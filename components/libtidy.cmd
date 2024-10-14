@echo off
setlocal

:: Input parameters
set "version=%1"

if /i "%version%"=="" set "version=master"

:: Define architecture array
set "arch_list=x64 x86 arm arm64"

:again
:: Checkout libtidy repository
echo Checking out libtidy repository with version %version%...
if not exist %~dp0..\buildtree\libtidy git clone --branch %version% https://github.com/PHP-WOA/libtidy %~dp0..\buildtree\libtidy || goto :again


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

    :: Build libtidy
    echo Building libtidy for arch %~1...
    rmdir /s /q %~dp0..\buildtree\libtidy\build.libtidy
    mkdir %~dp0..\buildtree\libtidy\build.libtidy
    pushd %~dp0..\buildtree\libtidy\build.libtidy
    if /i "%~1" == "x86" (
    cmake .. -A Win32 -DUSE_STATIC_RUNTIME=ON || exit /b 1
    ) else (
    cmake .. -A %~1 -DUSE_STATIC_RUNTIME=ON || exit /b 1
    )
    cmake --build . --config RelWithDebInfo || exit /b 1
    cmake --install . --config RelWithDebInfo --prefix ..\installed.libtidy || exit /b 1
    popd

    :: Install libtidy
    echo Installing libtidy for arch %~1...
    pushd %~dp0..\buildtree\libtidy
    ren installed.libtidy\bin\tidyexe.exe tidy.exe
    ren installed.libtidy\lib\tidys.lib tidy_a.lib
    copy build.libtidy\RelWithDebInfo\tidy.pdb installed.libtidy\bin\tidy.pdb
    copy build.libtidy\RelWithDebInfo\tidys.pdb installed.libtidy\lib\tidy_a.pdb
    xcopy installed.libtidy %~dp0..\libs\libtidy\%~1\* /Y /E
    xcopy installed.libtidy %~dp0..\install\%~1\* /Y /E
    rmdir /s /q build.libtidy
    rmdir /s /q installed.libtidy
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