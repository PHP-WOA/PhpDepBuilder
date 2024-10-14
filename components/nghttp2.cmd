@echo off
setlocal

:: Input parameters
set "version=%1"

if /i "%version%"=="" set "version=master"

:: Define architecture array
set "arch_list=x64 x86 arm arm64"

:again
:: Checkout nghttp2 repository
echo Checking out nghttp2 repository with version %version%...
if not exist %~dp0..\buildtree\nghttp2 git clone --branch %version% https://github.com/PHP-WOA/nghttp2 %~dp0..\buildtree\nghttp2 || goto :again


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

    :: Build nghttp2
    echo Building nghttp2 for arch %~1...
    rmdir /s /q %~dp0..\buildtree\nghttp2\build
    mkdir %~dp0..\buildtree\nghttp2\build
    pushd %~dp0..\buildtree\nghttp2\build
    if /i "%~1" == "x86" (
    cmake .. -A Win32 -DENABLE_STATIC_CRT=ON || exit /b 1
    ) else (
    cmake .. -A %~1 -DENABLE_STATIC_CRT=ON || exit /b 1
    )
    cmake --build . --config RelWithDebInfo || exit /b 1
    cmake --install . --config RelWithDebInfo --prefix ..\installed || exit /b 1
    popd

    :: Install nghttp2
    echo Installing nghttp2 for arch %~1...
    pushd %~dp0..\buildtree\nghttp2
    xcopy installed %~dp0..\libs\nghttp2\%~1\* /Y /E
    xcopy installed %~dp0..\install\%~1\* /Y /E
    rmdir /s /q Build
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