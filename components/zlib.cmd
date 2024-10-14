@echo off
setlocal

:: Input parameters
set "version=%1"

if /i "%version%"=="" set "version=master"

:: Define architecture array
set "arch_list=x64 x86 arm arm64"

:again
:: Checkout zlib repository
echo Checking out zlib repository with version %version%...
if not exist %~dp0..\buildtree\zlib git clone --branch %version% https://github.com/PHP-WOA/zlib %~dp0..\buildtree\zlib || goto :again

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

    :: Build zlib
    echo Building zlib for arch %~1...
    pushd %~dp0..\buildtree\zlib
    nmake -f win32/Makefile.msc zlib_a.lib || exit /b 1
    popd

    :: Install zlib
    echo Installing zlib for arch %~1...
    pushd %~dp0..\buildtree\zlib
    xcopy zconf.h %~dp0..\libs\zlib\%~1\include\ /Y
    xcopy zlib.h %~dp0..\libs\zlib\%~1\include\ /Y
    xcopy zutil.h %~dp0..\libs\zlib\%~1\include\ /Y
    xcopy zlib_a.lib %~dp0..\libs\zlib\%~1\lib\ /Y
    xcopy zlib_a.pdb %~dp0..\libs\zlib\%~1\lib\ /Y
    xcopy zconf.h %~dp0..\install\%~1\include\ /Y
    xcopy zlib.h %~dp0..\install\%~1\include\ /Y
    xcopy zutil.h %~dp0..\install\%~1\include\ /Y
    xcopy zlib_a.lib %~dp0..\install\%~1\lib\ /Y
    xcopy zlib_a.pdb %~dp0..\install\%~1\lib\ /Y
    nmake -f win32/Makefile.msc clean
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