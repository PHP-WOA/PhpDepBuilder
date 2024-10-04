@echo off
setlocal

:: Input parameters
set "version=%1"

if /i "%version%"=="" set "version=master"

:: Define architecture array
set "arch_list=x64 x86 arm arm64"

:: Checkout libjpeg repository
echo Checking out libjpeg repository with version %version%...
if not exist %~dp0..\buildtree\libjpeg git clone --branch %version% https://github.com/PHP-WOA/libjpeg %~dp0..\buildtree\libjpeg || goto :failure


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

    :: Build libjpeg
    echo Building libjpeg for arch %~1...
    rmdir /s /q %~dp0..\buildtree\libjpeg\build
    mkdir %~dp0..\buildtree\libjpeg\build
    pushd %~dp0..\buildtree\libjpeg\build
    if /i "%~1" == "x86" (
    cmake .. -A Win32  -DWITH_JPEG8=1 -DWITH_CRT_DLL=0 -DENABLE_SHARED=0 -DWITH_TURBOJPEG=0 || exit /b 1
    ) else if /i "%~1" == "x64" (
    cmake .. -A %~1  -DWITH_JPEG8=1 -DWITH_CRT_DLL=0 -DENABLE_SHARED=0 -DWITH_TURBOJPEG=0 || exit /b 1
    ) else if /i "%~1" == "arm" (
    cmake .. -A %~1 -DCMAKE_TOOLCHAIN_FILE=..\cmakescripts\winarm.cmake -DWITH_JPEG8=1 -DWITH_CRT_DLL=0 -DENABLE_SHARED=0 -DWITH_TURBOJPEG=0 -DWITH_SIMD=0 || exit /b 1
    ) else if /i "%~1" == "arm64" (
    cmake .. -A %~1 -DCMAKE_TOOLCHAIN_FILE=..\cmakescripts\winarm64.cmake -DWITH_JPEG8=1 -DWITH_CRT_DLL=0 -DENABLE_SHARED=0 -DWITH_TURBOJPEG=0 -DWITH_SIMD=0 || exit /b 1
    )
    cmake --build . --config RelWithDebInfo || exit /b 1
    cmake --install . --config RelWithDebInfo --prefix ..\installed || exit /b 1
    popd

    :: Install libjpeg
    echo Installing libjpeg for arch %~1...
    pushd %~dp0..\buildtree\libjpeg
    xcopy installed %~dp0..\libs\libjpeg\%~1\* /Y /E
    xcopy installed %~dp0..\install\%~1\* /Y /E
    rmdir /s /q build
    rmdir /s /q installed
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