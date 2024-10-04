@echo off
setlocal

:: Input parameters
set "version=%1"

if /i "%version%"=="" set "version=master"

:: Define architecture array
set "arch_list=x64 x86 arm64 arm"

:: Checkout lmdb repository
echo Checking out lmdb repository with version %version%...
if not exist %~dp0..\buildtree\lmdb git clone --branch %version% https://github.com/PHP-WOA/lmdb %~dp0..\buildtree\lmdb || goto :failure

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

    :: Build lmdb
    echo Building lmdb for arch %~1...
    pushd %~dp0..\buildtree\lmdb\libraries\liblmdb
    nmake /f Makefile.vc || exit /b 1
    popd

    :: Install lmdb
    echo Installing lmdb for arch %~1...
    pushd %~dp0..\buildtree\lmdb\libraries\liblmdb
    xcopy *.exe %~dp0..\libs\lmdb\%~1\bin\* /Y
    xcopy lmdb.h %~dp0..\libs\lmdb\%~1\include\* /Y
    xcopy liblmdb_a.* %~dp0..\libs\lmdb\%~1\lib\* /Y
    xcopy *.exe %~dp0..\install\%~1\bin\* /Y
    xcopy lmdb.h %~dp0..\install\%~1\include\* /Y
    xcopy liblmdb_a.* %~dp0..\install\%~1\lib\* /Y
    nmake /f Makefile.vc clean
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