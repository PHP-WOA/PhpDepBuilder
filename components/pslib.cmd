@echo off
setlocal

:: Input parameters
set "version=%1"

if /i "%version%"=="" set "version=main"

:: Define architecture array
set "arch_list=x64 x86 arm arm64"

:again
:: Checkout pslib repository
echo Checking out pslib repository with version %version%...
if not exist %~dp0..\buildtree\pslib git clone --branch %version% https://github.com/PHP-WOA/pslib %~dp0..\buildtree\pslib || goto :again


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

    :: Build pslib
    echo Building pslib for arch %~1...
    rmdir /s /q %~dp0..\buildtree\pslib\build.pslib
    mkdir %~dp0..\buildtree\pslib\build.pslib
    pushd %~dp0..\buildtree\pslib\build.pslib
    if /i "%~1" == "x86" (
    cmake .. -A Win32 || exit /b 1
    ) else (
    cmake .. -A %~1 || exit /b 1
    )
    cmake --build . --config RelWithDebInfo || exit /b 1
    popd

    :: Install pslib
    echo Installing pslib for arch %~1...
    pushd %~dp0..\buildtree\pslib
    xcopy build.pslib\RelWithDebInfo\pslib.dll %~dp0..\libs\pslib\%~1\bin\* /Y
    xcopy build.pslib\RelWithDebInfo\pslib.pdb %~dp0..\libs\pslib\%~1\bin\* /Y
    xcopy include\libps\*.h %~dp0..\libs\pslib\%~1\include\libps\* /Y
    xcopy build.pslib\RelWithDebInfo\pslib.lib %~dp0..\libs\pslib\%~1\lib\* /Y
    xcopy build.pslib\RelWithDebInfo\pslib.dll %~dp0..\install\%~1\bin\* /Y
    xcopy build.pslib\RelWithDebInfo\pslib.pdb %~dp0..\install\%~1\bin\* /Y
    xcopy include\libps\*.h %~dp0..\install\%~1\include\libps\* /Y
    xcopy build.pslib\RelWithDebInfo\pslib.lib %~dp0..\install\%~1\lib\* /Y
    rmdir /s /q build.pslib
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