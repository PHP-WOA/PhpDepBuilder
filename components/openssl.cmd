@echo off
setlocal

:: Input parameters
set "version=%1"

if /i "%version%"=="" set "version=openssl-3.0.15.pl1"

:: Define architecture array
set "arch_list=x64 x86 arm64 arm"

:: Checkout openssl repository
echo Checking out openssl repository with version %version%...
if not exist %~dp0..\buildtree\openssl git clone --branch %version% https://github.com/PHP-WOA/openssl %~dp0..\buildtree\openssl || goto :failure

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

    :: Build openssl
    echo Building openssl for arch %~1...
    pushd %~dp0..\buildtree\openssl
    nmake clean
    if /i "%~1"=="x86" (
      perl Configure VC-WIN32 --prefix=%~dp0temp\ssl no-asm  no-dynamic-engine no-shared no-tests || exit /b 1
    ) else if /i "%~1"=="x64" (
      perl Configure VC-WIN64A --prefix=%~dp0temp\ssl  no-asm  no-dynamic-engine no-shared no-tests || exit /b 1
    ) else if /i "%~1"=="ARM" (
      perl Configure VC-WIN32-ARM --prefix=%~dp0temp\ssl  no-asm  no-dynamic-engine no-shared no-tests || exit /b 1
    ) else if /i "%~1"=="ARM64" (
      perl Configure VC-WIN64-ARM --prefix=%~dp0temp\ssl  no-asm  no-dynamic-engine no-shared no-tests || exit /b 1
    )
    nmake || exit /b 1
    nmake install_sw || exit /b 1
    popd

    :: Install openssl
    echo Installing openssl for arch %~1...
    xcopy %~dp0temp\ssl\bin\* %~dp0..\libs\openssl\%~1\bin\ /Y
    xcopy %~dp0temp\ssl\include\* %~dp0..\libs\openssl\%~1\include\ /Y /E
    xcopy %~dp0temp\ssl\lib\* %~dp0..\libs\openssl\%~1\lib\ /Y /E /S
    xcopy %~dp0temp\ssl\bin\* %~dp0..\install\%~1\bin\ /Y
    xcopy %~dp0temp\ssl\include\* %~dp0..\install\%~1\include\ /Y /E
    xcopy %~dp0temp\ssl\lib\* %~dp0..\install\%~1\lib\ /Y /E /S
    rmdir /s /q %~dp0temp\ssl
endlocal
exit /b
:failure
echo Error occurred when compiling.
pause
exit /b 1
:success
endlocal
exit /b 0