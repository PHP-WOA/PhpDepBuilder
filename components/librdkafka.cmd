@echo off
setlocal

:: Input parameters
set "version=%1"

if /i "%version%"=="" set "version=master"

:: Define architecture array
set "arch_list=x64 x86 arm arm64"

:: Checkout librdkafka repository
echo Checking out librdkafka repository with version %version%...
if not exist %~dp0..\buildtree\librdkafka git clone --branch %version% https://github.com/PHP-WOA/librdkafka %~dp0..\buildtree\librdkafka || goto :failure


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

    :: Build librdkafka
    echo Building librdkafka for arch %~1...
    rmdir /s /q %~dp0..\buildtree\librdkafka\build
    mkdir %~dp0..\buildtree\librdkafka\build
    pushd %~dp0..\buildtree\librdkafka\build
    if /i "%~1" == "x86" (
    cmake .. -A Win32 -DWITH_ZSTD=ON -DWITH_SSL=ON -DWITH_ZLIB=ON -DCMAKE_PREFIX_PATH:PATH=%~dp0..\install\%~1 -DZLIB_LIBRARY:PATH=%~dp0..\install\%~1\lib\zlib_a.lib -DZSTD_LIBRARY:PATH=%~dp0..\install\%~1\lib\libzstd_a.lib -DRDKAFKA_BUILD_EXAMPLES=OFF -DRDKAFKA_BUILD_TESTS=OFF || exit /b 1
    ) else (
    cmake .. -A %~1 -DWITH_ZSTD=ON -DWITH_SSL=ON -DWITH_ZLIB=ON -DCMAKE_PREFIX_PATH:PATH=%~dp0..\install\%~1 -DZLIB_LIBRARY:PATH=%~dp0..\install\%~1\lib\zlib_a.lib -DZSTD_LIBRARY:PATH=%~dp0..\install\%~1\lib\libzstd_a.lib -DRDKAFKA_BUILD_EXAMPLES=OFF -DRDKAFKA_BUILD_TESTS=OFF || exit /b 1
    )
    cmake --build . --config RelWithDebInfo || exit /b 1
    cmake --install . --config RelWithDebInfo --prefix ..\installed || exit /b 1
    popd

    :: Install librdkafka
    echo Installing librdkafka for arch %~1...
    pushd %~dp0..\buildtree\librdkafka
    xcopy installed %~dp0..\libs\librdkafka\%~1\* /Y /E
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