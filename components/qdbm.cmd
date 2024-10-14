@echo off
setlocal

:: Input parameters
set "version=%1"

if /i "%version%"=="" set "version=master"

:: Define architecture array
set "arch_list=x64 x86 arm arm64"

:again
:: Checkout qdbm repository
echo Checking out qdbm repository with version %version%...
if not exist %~dp0..\buildtree\qdbm git clone --branch %version% https://github.com/PHP-WOA/qdbm %~dp0..\buildtree\qdbm || goto :again

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

    :: Build qdbm
    echo Building qdbm for arch %arch%...
    pushd %~dp0..\buildtree\qdbm
    nmake /f VCmakefile clean || exit /b 1
    nmake /f VCmakefile || exit /b 1
    popd

    :: Install qdbm
    echo Installing qdbm for arch %~1...
    pushd %~dp0..\buildtree\qdbm
    xcopy qdbm.dll %~dp0..\libs\qdbm\%~1\bin\*
    xcopy tmp\qdbm.pdb %~dp0..\libs\qdbm\%~1\bin\*
    xcopy *.h %~dp0..\libs\qdbm\%~1\include\qdbm\*
    del %~dp0..\libs\qdbm\%~1\include\qdbm\hovel.h %~dp0..\libs\qdbm\%~1\include\qdbm\myconf.h
    xcopy *.lib %~dp0..\libs\qdbm\%~1\lib\*
    xcopy qdbm.dll %~dp0..\install\%~1\bin\*
    xcopy tmp\qdbm.pdb %~dp0..\install\%~1\bin\*
    xcopy *.h %~dp0..\install\%~1\include\qdbm\*
    del %~dp0..\install\%~1\include\qdbm\hovel.h %~dp0..\install\%~1\include\qdbm\myconf.h
    xcopy *.lib %~dp0..\install\%~1\lib\*
    nmake /f VCmakefile clean
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