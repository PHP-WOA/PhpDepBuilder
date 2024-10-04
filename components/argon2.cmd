@echo off
setlocal

:: Input parameters
set "version=%1"

if /i "%version%"=="" set "version=master"

:: Define architecture array
set "arch_list=x64 x86 arm64 arm"

:: Checkout argon2 repository
echo Checking out argon2 repository with version %version%...
if not exist %~dp0..\buildtree\argon2 git clone --branch %version% https://github.com/PHP-WOA/argon2 %~dp0..\buildtree\argon2 || goto :failure

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

    :: Build argon2
    echo Building argon2 for arch %arch%...
    pushd %~dp0..\buildtree\argon2
    nmake /f Makefile.vc clean
    nmake /f Makefile.vc || exit /b 1
    popd

    :: Install argon2
    echo Installing argon2 for arch %~1...
    xcopy %~dp0..\buildtree\argon2\include\*.h %~dp0..\libs\argon2\%~1\include\ /Y
    xcopy %~dp0..\buildtree\argon2\argon2_a.* %~dp0..\libs\argon2\%~1\lib\ /Y
    xcopy %~dp0..\buildtree\argon2\include\*.h %~dp0..\install\%~1\include\ /Y
    xcopy %~dp0..\buildtree\argon2\argon2_a.* %~dp0..\install\%~1\lib\ /Y
endlocal
exit /b
:failure
echo Error occurred when compiling.
pause
exit /b 1
:success
endlocal
exit /b 0