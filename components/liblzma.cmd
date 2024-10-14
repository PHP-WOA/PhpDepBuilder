@echo off
setlocal

:: Input parameters
set "version=%1"

if /i "%version%"=="" set "version=master"

:: Define architecture array
set "arch_list=x64 x86 arm arm64"

:again
:: Checkout liblzma repository
echo Checking out liblzma repository with version %version%...
if not exist %~dp0..\buildtree\liblzma git clone --branch %version% https://github.com/PHP-WOA/liblzma %~dp0..\buildtree\liblzma || goto :again


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

    :: Build liblzma
    echo Building liblzma for arch %~1...
    rmdir /s /q %~dp0..\buildtree\liblzma\build
    mkdir %~dp0..\buildtree\liblzma\build
    pushd %~dp0..\buildtree\liblzma\build
    if /i "%~1" == "x86" (
    cmake .. -A Win32 || exit /b 1
    ) else (
    cmake .. -A %~1 || exit /b 1
    )
    cmake --build . --config RelWithDebInfo || exit /b 1
    cmake --install . --config RelWithDebInfo --prefix ..\installed || exit /b 1
    popd

    :: Install liblzma
    echo Installing liblzma for arch %~1...
    pushd %~dp0..\buildtree\liblzma
    xcopy installed %~dp0..\libs\liblzma\%~1\* /Y /E
    xcopy installed %~dp0..\install\%~1\* /Y /E
    rmdir /s /q build
    rmdir /s /q installed
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