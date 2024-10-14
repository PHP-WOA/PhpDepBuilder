@echo off
setlocal

:: Input parameters
set "version=%1"

if /i "%version%"=="" set "version=master"

:: Define architecture array
set "arch_list=x64 x86 arm arm64"

:again
:: Checkout wineditline repository
echo Checking out wineditline repository with version %version%...
if not exist %~dp0..\buildtree\wineditline git clone --branch %version% https://github.com/PHP-WOA/wineditline %~dp0..\buildtree\wineditline || goto :again


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

    :: Build wineditline
    echo Building wineditline for arch %~1...
    rmdir /s /q %~dp0..\buildtree\wineditline\build.wineditline
    mkdir %~dp0..\buildtree\wineditline\build.wineditline
    pushd %~dp0..\buildtree\wineditline\build.wineditline
    if /i "%~1" == "x86" (
    cmake .. -A Win32 -DMSVC_USE_STATIC_RUNTIME=ON -DCMAKE_INSTALL_PREFIX=..\installed.wineditline || exit /b 1
    ) else (
    cmake .. -A %~1 -DMSVC_USE_STATIC_RUNTIME=ON -DCMAKE_INSTALL_PREFIX=..\installed.wineditline || exit /b 1
    )
    cmake --build . --config RelWithDebInfo || exit /b 1
    cmake --install . --config RelWithDebInfo --prefix ..\installed.wineditline || exit /b 1
    popd

    :: Install wineditline
    echo Installing wineditline for arch %~1...
    pushd %~dp0..\buildtree\wineditline
    xcopy installed.wineditline %~dp0..\libs\wineditline\%~1\* /Y /E
    xcopy installed.wineditline %~dp0..\install\%~1\* /Y /E
    rmdir /s /q build.wineditline
    rmdir /s /q installed.wineditline
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