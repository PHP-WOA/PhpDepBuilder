@echo off
setlocal

:: Input parameters
set "version=%1"

if /i "%version%"=="" set "version=master"

:: Define architecture array
set "arch_list=x64 x86 arm arm64"

:: Checkout libxml2 repository
echo Checking out libxml2 repository with version %version%...
if not exist %~dp0..\buildtree\libxml2 git clone --branch %version% https://github.com/PHP-WOA/libxml2 %~dp0..\buildtree\libxml2 || goto :failure


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

    :: Build libxml2
    echo Building libxml2 for arch %~1...
    pushd %~dp0..\buildtree\libxml2\win32
    cscript configure.js lib=%~dp0..\install\%~1\lib include=%~dp0..\install\%~1\include vcmanifest=yes prefix=install cruntime=/MT || exit /b 1
    nmake /f makefile.msvc || exit /b 1
    nmake /f makefile.msvc install || exit /b 1
    del /q install\bin\run*
    del /q install\bin\test*
    del /q install\bin\xml*.pdb
    popd

    :: Install libxml2
    echo Installing libxml2 for arch %~1...
    pushd %~dp0..\buildtree\libxml2\win32
    xcopy install %~dp0..\libs\libxml2\%~1\ /Y /E
    xcopy install %~dp0..\install\%~1\ /Y /E
    rmdir /s /q install
    nmake /f makefile.msvc clean || exit /b 1
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