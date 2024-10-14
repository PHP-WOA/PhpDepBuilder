@echo off
setlocal

:: Input parameters
set "version=%1"

if /i "%version%"=="" set "version=master"

:: Define architecture array
set "arch_list=x64 x86 arm arm64"

:again
:: Checkout libbzip2 repository
echo Checking out libbzip2 repository with version %version%...
if not exist %~dp0..\buildtree\libbzip2 git clone --branch %version% https://github.com/PHP-WOA/libbzip2 %~dp0..\buildtree\libbzip2 || goto :again

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

    :: Build libbzip2
    echo Building libbzip2 for arch %arch%...
    pushd %~dp0..\buildtree\libbzip2
    nmake /f Makefile.msc clean
    nmake /f Makefile.msc || exit /b 1
    popd

    :: Install libbzip2
    echo Installing libbzip2 for arch %~1...
    xcopy %~dp0..\buildtree\libbzip2\bzlib.h %~dp0..\libs\libbzip2\%~1\include\ /Y
    xcopy %~dp0..\buildtree\libbzip2\libbz2_a.* %~dp0..\libs\libbzip2\%~1\lib\ /Y
    xcopy %~dp0..\buildtree\libbzip2\bzlib.h %~dp0..\install\%~1\include\ /Y
    xcopy %~dp0..\buildtree\libbzip2\libbz2_a.* %~dp0..\install\%~1\lib\ /Y
endlocal
exit /b
:failure
echo Error occurred when compiling.
pause
exit /b 1
:success
endlocal
exit /b 0