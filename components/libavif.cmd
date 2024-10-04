@echo off
setlocal

:: Input parameters
set "version=%1"
set "aomversion=%2"

if /i "%version%"=="" set "version=master"
if /i "%aomversion%"=="" set "aomversion=master"

:: Define architecture array
set "arch_list=x64 x86 arm arm64"

:: Checkout libavif repository
echo Checking out libavif repository with version %version%...
if not exist %~dp0..\buildtree\libavif git clone --branch %version% https://github.com/PHP-WOA/libavif %~dp0..\buildtree\libavif || goto :failure
echo Checking out aom repository with version %version%...
if not exist %~dp0..\buildtree\libavif\ext\aom git clone --branch %aomversion% https://github.com/PHP-WOA/aom %~dp0..\buildtree\libavif\ext\aom || goto :failure


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

    :: Build aom
    echo Building aom for arch %~1...
    rmdir /s /q %~dp0..\buildtree\libavif\ext\aom\build.libavif
    mkdir %~dp0..\buildtree\libavif\ext\aom\build.libavif
    pushd %~dp0..\buildtree\libavif\ext\aom\build.libavif
    if /i "%~1" == "x86" (
    cmake .. -A Win32 -DENABLE_DOCS=0 -DENABLE_EXAMPLES=0 -DENABLE_TESTDATA=0 -DENABLE_TESTS=0 -DENABLE_TOOLS=0 -DENABLE_NASM=0 -DENABLE_SSE2=0 -DENABLE_SSE3=0 -DENABLE_SSSE3=0 -DENABLE_SSE4_1=0 -DENABLE_SSE4_2=0 -DENABLE_AVX=0 -DENABLE_AVX2=0 -DAOM_TARGET_CPU=x86  || exit /b 1
    ) else if /i "%~1" == "x64" (
    cmake .. -A %~1 -DENABLE_DOCS=0 -DENABLE_EXAMPLES=0 -DENABLE_TESTDATA=0 -DENABLE_TESTS=0 -DENABLE_TOOLS=0 -DENABLE_NASM=0 -DENABLE_SSE2=1 -DENABLE_SSE3=1 -DENABLE_SSSE3=1 -DENABLE_SSE4_1=1 -DENABLE_SSE4_2=1 -DENABLE_AVX=1 -DENABLE_AVX2=1 -DAOM_TARGET_CPU=x86_64 || exit /b 1
    ) else if /i "%~1" == "arm"  (
    :: arm32 neon is buggy, we have to disable it until we have a better solution
    cmake .. -A %~1 -DENABLE_DOCS=0 -DENABLE_EXAMPLES=0 -DENABLE_TESTDATA=0 -DENABLE_TESTS=0 -DENABLE_TOOLS=0 -DENABLE_NASM=0 -DENABLE_SSE2=0 -DENABLE_SSE3=0 -DENABLE_SSSE3=0 -DENABLE_SSE4_1=0 -DENABLE_SSE4_2=0 -DENABLE_AVX=0 -DENABLE_AVX2=0 -DENABLE_NEON=0 -DAOM_TARGET_CPU=arm || exit /b 1
    ) else if /i "%~1" == "arm64"  (
    cmake .. -A %~1 -DENABLE_DOCS=0 -DENABLE_EXAMPLES=0 -DENABLE_TESTDATA=0 -DENABLE_TESTS=0 -DENABLE_TOOLS=0 -DENABLE_NASM=0 -DENABLE_SSE2=0 -DENABLE_SSE3=0 -DENABLE_SSSE3=0 -DENABLE_SSE4_1=0 -DENABLE_SSE4_2=0 -DENABLE_AVX=0 -DENABLE_AVX2=0 -DAOM_TARGET_CPU=aarch64 || exit /b 1
    )
    cmake --build . --config RelWithDebInfo || exit /b 1
    cmake --install . --config RelWithDebInfo --prefix ..\..\..\installed || exit /b 1
    xcopy RelWithDebInfo\*.lib . /y
    xcopy RelWithDebInfo\*.pdb . /y
    copy RelWithDebInfo\aom.lib ..\..\..\installed\lib\aom_a.lib /y
    popd

    :: Build libavif
    echo Building libavif for arch %~1...
    rmdir /s /q %~dp0..\buildtree\libavif\build
    mkdir %~dp0..\buildtree\libavif\build
    pushd %~dp0..\buildtree\libavif\build
    if /i "%~1" == "x86" (
    cmake .. -A Win32 -DAVIF_CODEC_AOM=1 -DAVIF_LOCAL_AOM=1 -DAVIF_ENABLE_WERROR=0 -DBUILD_SHARED_LIBS=0 || exit /b 1
    ) else (
    cmake .. -A %~1 -DAVIF_CODEC_AOM=1 -DAVIF_LOCAL_AOM=1 -DAVIF_ENABLE_WERROR=0 -DBUILD_SHARED_LIBS=0 || exit /b 1
    )
    cmake --build . --config RelWithDebInfo || exit /b 1
    cmake --install . --config RelWithDebInfo --prefix ..\installed || exit /b 1
    popd

    :: Install libavif
    echo Installing libavif for arch %~1...
    pushd %~dp0..\buildtree\libavif
    xcopy installed %~dp0..\libs\libavif\%~1\* /Y /E
    xcopy installed %~dp0..\install\%~1\* /Y /E
    rmdir /s /q build
    rmdir /s /q installed
    rmdir /s /q %~dp0..\buildtree\libavif\ext\aom\build.libavif
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