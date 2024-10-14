@echo off
setlocal

:: Input parameters
set "version=%1"

if /i "%version%"=="" set "version=master"

:: Define architecture array
set "arch_list=x64 x86 arm arm64"

:again
:: Checkout glib repository
echo Checking out glib repository with version %version%...
if not exist %~dp0..\buildtree\glib git clone --branch %version% https://github.com/PHP-WOA/glib %~dp0..\buildtree\glib || goto :again


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

    :: Build glib
    echo Building glib for arch %~1...
    pushd %~dp0..\buildtree\glib\win32\vsauto
    msbuild /p:Configuration=Release_BundledPCRE;Platform=%~1 glib.sln || exit /b 1
    popd

    :: Install glib
    echo Installing glib for arch %~1...
    pushd %~dp0..\buildtree\glib
    xcopy installed\%~1 %~dp0..\libs\glib\%~1\ /Y /E
    xcopy installed\%~1 %~dp0..\install\%~1\ /Y /E
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