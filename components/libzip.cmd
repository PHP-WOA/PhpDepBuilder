@echo off
setlocal

:: Input parameters
set "version=%1"

if /i "%version%"=="" set "version=master"

:: Define architecture array
set "arch_list=x64 x86 arm arm64"

:: Checkout libzip repository
echo Checking out libzip repository with version %version%...
if not exist %~dp0..\buildtree\libzip git clone --branch %version% https://github.com/PHP-WOA/libzip %~dp0..\buildtree\libzip || goto :failure


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

    :: Build libzip
    echo Building libzip for arch %~1...
    rmdir /s /q %~dp0..\buildtree\libzip\build
    mkdir %~dp0..\buildtree\libzip\build
    pushd %~dp0..\buildtree\libzip\build
    if /i "%~1" == "x86" (
    cmake .. -A Win32  -DZLIB_INCLUDE_DIR:PATH=%~dp0..\install\%~1\include -DZLIB_LIBRARY:PATH=%~dp0..\install\%~1\lib\zlib_a.lib -DBZIP2_INCLUDE_DIR:PATH=%~dp0..\install\%~1\include -DBZIP2_LIBRARIES:PATH=%~dp0..\install\%~1\lib\libbz2_a.lib -DLIBLZMA_INCLUDE_DIR:PATH=%~dp0..\install\%~1\include -DLIBLZMA_LIBRARY:PATH=%~dp0..\install\%~1\lib\liblzma_a.lib -DBUILD_TOOLS=OFF -DBUILD_REGRESS=OFF -DBUILD_EXAMPLES=OFF -DBUILD_DOC=OFF|| exit /b 1
    ) else (
    cmake .. -A %~1  -DZLIB_INCLUDE_DIR:PATH=%~dp0..\install\%~1\include -DZLIB_LIBRARY:PATH=%~dp0..\install\%~1\lib\zlib_a.lib -DBZIP2_INCLUDE_DIR:PATH=%~dp0..\install\%~1\include -DBZIP2_LIBRARIES:PATH=%~dp0..\install\%~1\lib\libbz2_a.lib -DLIBLZMA_INCLUDE_DIR:PATH=%~dp0..\install\%~1\include -DLIBLZMA_LIBRARY:PATH=%~dp0..\install\%~1\lib\liblzma_a.lib -DBUILD_TOOLS=OFF -DBUILD_REGRESS=OFF -DBUILD_EXAMPLES=OFF -DBUILD_DOC=OFF|| exit /b 1
    )
    cmake --build . --config RelWithDebInfo || exit /b 1
    cmake --install . --config RelWithDebInfo --prefix ..\installed || exit /b 1
    popd

    :: Install libzip
    echo Installing libzip for arch %~1...
    pushd %~dp0..\buildtree\libzip
    xcopy installed %~dp0..\libs\libzip\%~1\* /Y /E
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