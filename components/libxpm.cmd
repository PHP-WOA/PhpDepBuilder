@echo off
setlocal

:: Input parameters
set "version=%1"

if /i "%version%"=="" set "version=master"

:: Define architecture array
set "arch_list=x64 x86 arm arm64"

:again
:: Checkout libxpm repository
echo Checking out libxpm repository with version %version%...
if not exist %~dp0..\buildtree\libxpm git clone --branch %version% https://github.com/PHP-WOA/libxpm %~dp0..\buildtree\libxpm || goto :again


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

    :: Build libxpm
    echo Building libxpm for arch %~1...
    pushd %~dp0..\buildtree\libxpm\windows\vsauto
    msbuild "/p:Configuration=Static Release;Platform=%~1" libxpm.sln || exit /b 1
    msbuild "/p:Configuration=Static Release;Platform=%~1" libxpm.sln || exit /b 1
    popd

    :: Install libxpm
    echo Installing libxpm for arch %~1...
    pushd %~dp0..\buildtree\libxpm\windows\vsauto
    xcopy ..\..\include\X11\* %~dp0..\libs\libxpm\%~1\include\X11\*
    xcopy "..\builds\%~1\Static Release\libxpm_a.*" %~dp0..\libs\libxpm\%~1\lib\*
    xcopy ..\..\include\X11\* %~dp0..\install\%~1\include\X11\*
    xcopy "..\builds\%~1\Static Release\libxpm_a.*" %~dp0..\install\%~1\lib\*
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