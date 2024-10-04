@echo off
setlocal

:: Input parameters
set "version=%1"

if /i "%version%"=="" set "version=master"

:: Define architecture array
set "arch_list=x64 x86 arm arm64"

:: Checkout icu4c repository
echo Checking out icu4c repository with version %version%...
if not exist %~dp0..\buildtree\icu4c git clone --branch %version% https://github.com/PHP-WOA/icu4c %~dp0..\buildtree\icu4c || goto :failure


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

    :: Build icu4c
    echo Building icu4c for arch %~1...
    pushd %~dp0..\buildtree\icu4c\source\allinone
    if /i "%~1" == "x86" (
      msbuild /p:Configuration=Release;Platform=Win32 allinone.sln || exit /b 1
    ) else (
      msbuild /p:Configuration=Release;Platform=%~1 allinone.sln || exit /b 1
    )
    popd

    :: Install icu4c
    echo Installing icu4c for arch %~1...
    pushd %~dp0..\buildtree\icu4c
    set WB_BINDIR=bin
    set WB_LIBDIR=lib
    if /i "%~1" == "x64" (
      set WB_BINDIR=%WB_BINDIR%64
      set WB_LIBDIR=%WB_LIBDIR%64
    ) else if /i "%~1" == "arm" (
      set WB_BINDIR=%WB_BINDIR%arm
      set WB_LIBDIR=%WB_LIBDIR%arm
    ) else if /i "%~1" == "arm64" (
      set WB_BINDIR=%WB_BINDIR%arm64
      set WB_LIBDIR=%WB_LIBDIR%arm64
    )
    del /q %WB_BINDIR%\*test*.dll 
    del /q %WB_BINDIR%\*test*.exe
    del /q %WB_LIBDIR%\*test*.*
    xcopy %WB_BINDIR%\* %~dp0..\libs\icu4c\%~1\bin\* /Y
    xcopy %WB_LIBDIR%\* %~dp0..\libs\icu4c\%~1\lib\* /Y
    xcopy include\* %~dp0..\libs\icu4c\%~1\include\* /Y /E
    
    xcopy %WB_BINDIR%\* %~dp0..\install\%~1\bin\* /Y
    xcopy %WB_LIBDIR%\* %~dp0..\install\%~1\lib\* /Y
    xcopy include\* %~dp0..\install\%~1\include\* /Y /E
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