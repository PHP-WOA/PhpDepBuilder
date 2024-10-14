@echo off
setlocal

:: Input parameters
set "version=%1"

if /i "%version%"=="" set "version=master"

:: Define architecture array
set "arch_list=x64 x86 arm arm64"

:again
:: Checkout imap repository
echo Checking out imap repository with version %version%...
if not exist %~dp0..\buildtree\imap git clone --branch %version% https://github.com/PHP-WOA/imap %~dp0..\buildtree\imap || goto :again

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

    :: Build imap
    echo Building imap for arch %arch%...
    pushd %~dp0..\buildtree\imap
    nmake /f Makefile.w2k clean
    nmake /f Makefile.w2k || exit /b 1
    popd

    :: Install imap
    echo Installing imap for arch %~1...
    pushd %~dp0..\buildtree\imap
    xcopy c-client\*.h %~dp0..\libs\imap\%~1\include\c-client\* /Y
    xcopy c-client\cclient_a.lib %~dp0..\libs\imap\%~1\lib\ /Y
    xcopy c-client\*.h %~dp0..\install\%~1\include\c-client\* /Y
    xcopy c-client\cclient_a.lib %~dp0..\install\%~1\lib\ /Y
    nmake /f Makefile.w2k clean
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