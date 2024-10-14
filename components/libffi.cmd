@echo off
setlocal

:: Input parameters
set "version=%1"

if /i "%version%"=="" set "version=master"

:: Define architecture array
set "arch_list=x64 x86 arm arm64"

:again
:: Checkout libffi repository
echo Checking out libffi repository with version %version%...
if not exist %~dp0..\buildtree\libffi git clone --branch %version% https://github.com/PHP-WOA/libffi %~dp0..\buildtree\libffi || goto :again


:: Loop through architectures
for %%A in (%arch_list%) do (
    call :compile %%A || goto :failure
)
goto :success
:compile
setlocal
    :: Setup MSVC development environment
    echo Setting up MSVC development environment for arch %~1
    call "%~dp0..\vsdevcmd\vsdevcmdauto.cmd" %~1

    :: Build libffi
    echo Building libffi for arch %~1...
    pushd %~dp0..\buildtree\libffi\win32\vsauto_%~1
    msbuild /p:Configuration=Release libffi-msvc.sln || exit /b 1
    popd

    :: Install libffi
    echo Installing libffi for arch %~1...
    pushd %~dp0..\buildtree\libffi
    xcopy include\ffi.h %~dp0..\libs\libffi\%~1\include\* /Y
    perl -pi -e "s/#define LIBFFI_H/#define LIBFFI_H\n#define FFI_BUILDING/" %~dp0..\libs\libffi\%~1\include\ffi.h
    if /i "%~1"=="arm" (
        xcopy src\arm\ffitarget.h %~dp0..\libs\libffi\%~1\include\* /Y
    ) else if /i "%~1"=="arm64" (
        xcopy src\aarch64\ffitarget.h %~dp0..\libs\libffi\%~1\include\* /Y
    ) else (
        xcopy src\x86\ffitarget.h %~dp0..\libs\libffi\%~1\include\* /Y
    )
    xcopy fficonfig.h %~dp0..\libs\libffi\%~1\include\* /Y
    xcopy win32\vsauto_%~1\%~1\Release\libffi.lib %~dp0..\libs\libffi\%~1\lib\* /Y
    xcopy win32\vsauto_%~1\%~1\Release\libffi.pdb %~dp0..\libs\libffi\%~1\lib\* /Y
    xcopy include\ffi.h %~dp0..\install\%~1\include\* /Y
    perl -pi -e "s/#define LIBFFI_H/#define LIBFFI_H\n#define FFI_BUILDING/" %~dp0..\install\%~1\include\ffi.h
    if /i "%~1"=="arm" (
        xcopy src\arm\ffitarget.h %~dp0..\install\%~1\include\* /Y
    ) else if /i "%~1"=="arm64" (
        xcopy src\aarch64\ffitarget.h %~dp0..\install\%~1\include\* /Y
    ) else (
        xcopy src\x86\ffitarget.h %~dp0..\install\%~1\include\* /Y
    )
    xcopy fficonfig.h %~dp0..\install\%~1\include\* /Y
    xcopy win32\vsauto_%~1\%~1\Release\libffi.lib %~dp0..\install\%~1\lib\* /Y
    xcopy win32\vsauto_%~1\%~1\Release\libffi.pdb %~dp0..\install\%~1\lib\* /Y
    popd
endlocal
exit /b
:failure
echo Error occurred when compiling.
pause
exit /b 1
:success
endlocal
exit /b 0