@echo off
setlocal

:: Input parameters
set "version=%1"

if /i "%version%"=="" set "version=master"

:: Define architecture array
set "arch_list=x64 x86 arm arm64"

:again
:: Checkout sqlite3 repository
echo Checking out sqlite3 repository with version %version%...
if not exist %~dp0..\buildtree\sqlite3 git clone --branch %version% https://github.com/PHP-WOA/sqlite3 %~dp0..\buildtree\sqlite3 || goto :again

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

    :: Build sqlite3
    echo Building sqlite3 for arch %~1...
    pushd %~dp0..\buildtree\sqlite3
    nmake PREFIX=build || exit /b 1
    nmake PREFIX=build install || exit /b 1
    popd

    :: Install sqlite3
    echo Installing sqlite3 for arch %~1...
    pushd %~dp0..\buildtree\sqlite3
    xcopy build\bin\* %~dp0..\libs\sqlite3\%~1\bin\* /Y
    xcopy build\include\* %~dp0..\libs\sqlite3\%~1\include\* /Y
    xcopy build\lib\* %~dp0..\libs\sqlite3\%~1\lib\* /Y
    xcopy build\bin\* %~dp0..\install\%~1\bin\* /Y
    xcopy build\include\* %~dp0..\install\%~1\include\* /Y
    xcopy build\lib\* %~dp0..\install\%~1\lib\* /Y
    nmake PREFIX=build clean
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