@echo off
setlocal

:: Input parameters
set "version=%1"

if /i "%version%"=="" set "version=master"

:: Define architecture array
set "arch_list=x64 x86 arm64 arm"

:: Checkout libwebp repository
echo Checking out libwebp repository with version %version%...
if not exist %~dp0..\buildtree\libwebp git clone --branch %version% https://github.com/PHP-WOA/libwebp %~dp0..\buildtree\libwebp || goto :failure

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

    :: Build libwebp
    echo Building libwebp for arch %arch%...
    pushd %~dp0..\buildtree\libwebp
    nmake /f Makefile.vc RTLIBCFG=static CFG=release-static OBJDIR=output clean
    nmake /f Makefile.vc RTLIBCFG=static CFG=release-static OBJDIR=output || exit /b 1
    popd

    :: Install libwebp
    echo Installing libwebp for arch %~1...
    pushd %~dp0..\buildtree\libwebp
    xcopy output\release-static\%~1\bin\*.exe %~dp0..\libs\libwebp\%~1\bin\* /Y
    xcopy src\webp\*.h %~dp0..\libs\libwebp\%~1\include\webp\* /E /Y
    xcopy output\release-static\%~1\lib\* %~dp0..\libs\libwebp\%~1\lib\* /Y
    xcopy output\release-static\%~1\bin\*.exe %~dp0..\install\%~1\bin\* /Y
    xcopy src\webp\*.h %~dp0..\install\%~1\include\webp\* /E /Y
    xcopy output\release-static\%~1\lib\* %~dp0..\install\%~1\lib\* /Y
    nmake /f Makefile.vc RTLIBCFG=static CFG=release-static OBJDIR=output clean
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