@echo off
setlocal

:: Input parameters
set "version=%1"

if /i "%version%"=="" set "version=master"

:: Define architecture array
set "arch_list=x64 x86 arm arm64"

:again
:: Checkout oniguruma repository
echo Checking out oniguruma repository with version %version%...
if not exist %~dp0..\buildtree\oniguruma git clone --branch %version% https://github.com/PHP-WOA/oniguruma %~dp0..\buildtree\oniguruma || goto :again

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

    :: Build oniguruma
    echo Building oniguruma for arch %arch%...
    pushd %~dp0..\buildtree\oniguruma
    call make_win.bat clean
    call make_win.bat
    popd

    :: Install oniguruma
    echo Installing oniguruma for arch %~1...
    pushd %~dp0..\buildtree\oniguruma
    xcopy onig.dll %~dp0..\libs\oniguruma\%~1\bin\* /Y
    xcopy src\onig*.h %~dp0..\libs\oniguruma\%~1\include\* /E /Y
    xcopy onig.lib %~dp0..\libs\oniguruma\%~1\lib\* /Y
    xcopy onig_a.lib %~dp0..\libs\oniguruma\%~1\lib\* /Y
    xcopy onig.dll %~dp0..\install\%~1\bin\* /Y
    xcopy src\onig*.h %~dp0..\install\%~1\include\* /E /Y
    xcopy onig.lib %~dp0..\install\%~1\lib\* /Y
    xcopy onig_a.lib %~dp0..\install\%~1\lib\* /Y
    call make_win.bat clean
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