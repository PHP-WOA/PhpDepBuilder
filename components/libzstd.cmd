@echo off
setlocal

:: Input parameters
set "version=%1"

if /i "%version%"=="" set "version=dev"

:: Define architecture array
set "arch_list=x64 x86 arm arm64"

:: Checkout libzstd repository
echo Checking out libzstd repository with version %version%...
if not exist %~dp0..\buildtree\libzstd git clone --branch %version% https://github.com/PHP-WOA/zstd %~dp0..\buildtree\libzstd || goto :failure


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

    :: Build libzstd
    echo Building libzstd for arch %~1...
    rmdir /s /q %~dp0..\buildtree\libzstd\build\cmake\build
    mkdir %~dp0..\buildtree\libzstd\build\cmake\build
    pushd %~dp0..\buildtree\libzstd\build\cmake\build
    if /i "%~1" == "x86" (
    cmake .. -A Win32 -DZSTD_USE_STATIC_RUNTIME=ON || exit /b 1
    ) else (
    cmake .. -A %~1 -DZSTD_USE_STATIC_RUNTIME=ON || exit /b 1
    )
    cmake --build . --config RelWithDebInfo || exit /b 1
    cmake --install . --config RelWithDebInfo --prefix ..\..\..\installed || exit /b 1
    popd

    :: Install libzstd
    echo Installing libzstd for arch %~1...
    pushd %~dp0..\buildtree\libzstd
    ren installed\bin\zstd.dll libzstd.dll
    ren installed\bin\zstd.pdb libzstd.pdb
    ren installed\lib\zstd_static.lib libzstd_a.lib
    ren installed\lib\zstd.lib libzstd.lib
    ren installed\lib\zstd_static.pdb libzstd_a.pdb
    xcopy installed %~dp0..\libs\libzstd\%~1\* /Y /E
    xcopy installed %~dp0..\install\%~1\* /Y /E
    rmdir /s /q build\cmake\build
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