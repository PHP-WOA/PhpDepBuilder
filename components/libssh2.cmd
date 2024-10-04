@echo off
setlocal

:: Input parameters
set "version=%1"

if /i "%version%"=="" set "version=master"

:: Define architecture array
set "arch_list=x64 x86 arm arm64"

:: Checkout libssh2 repository
echo Checking out libssh2 repository with version %version%...
if not exist %~dp0..\buildtree\libssh2 git clone --branch %version% https://github.com/PHP-WOA/libssh2 %~dp0..\buildtree\libssh2 || goto :failure


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

    :: Build libssh2
    echo Building libssh2 for arch %~1...
    rmdir /s /q %~dp0..\buildtree\libssh2\build
    mkdir %~dp0..\buildtree\libssh2\build
    pushd %~dp0..\buildtree\libssh2\build
    if /i "%~1" == "x86" (
    cmake .. -A Win32 -DCRYPTO_BACKEND=OpenSSL -DOPENSSL_ROOT_DIR:PATH=%~dp0..\install\%~1 -DENABLE_ZLIB_COMPRESSION=ON -DZLIB_INCLUDE_DIR:PATH=%~dp0..\install\%~1\include -DZLIB_LIBRARY:FILEPATH=%~dp0..\install\%~1\lib\zlib_a.lib -DBUILD_SHARED_LIBS=ON -DBUILD_TESTING=OFF -DBUILD_EXAMPLES=OFF || exit /b 1
    ) else (
    cmake .. -A %~1 -DCRYPTO_BACKEND=OpenSSL -DOPENSSL_ROOT_DIR:PATH=%~dp0..\install\%~1 -DENABLE_ZLIB_COMPRESSION=ON -DZLIB_INCLUDE_DIR:PATH=%~dp0..\install\%~1\include -DZLIB_LIBRARY:FILEPATH=%~dp0..\install\%~1\lib\zlib_a.lib -DBUILD_SHARED_LIBS=ON -DBUILD_TESTING=OFF -DBUILD_EXAMPLES=OFF || exit /b 1
    )
    cmake --build . --config RelWithDebInfo || exit /b 1
    cmake --install . --config RelWithDebInfo --prefix ..\install || exit /b 1
    popd

    :: Install libssh2
    echo Installing libssh2 for arch %~1...
    pushd %~dp0..\buildtree\libssh2
    xcopy install %~dp0..\libs\libssh2\%~1\* /Y /E
    xcopy install %~dp0..\install\%~1\* /Y /E
    rmdir /s /q Build
    rmdir /s /q install
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