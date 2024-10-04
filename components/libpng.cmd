@echo off
setlocal

:: Input parameters
set "version=%1"

if /i "%version%"=="" set "version=master"

:: Define architecture array
set "arch_list=x64 x86 arm arm64"

:: Checkout libpng repository
echo Checking out libpng repository with version %version%...
if not exist %~dp0..\buildtree\libpng git clone --branch %version% https://github.com/PHP-WOA/libpng %~dp0..\buildtree\libpng || goto :failure


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

    :: Build libpng
    echo Building libpng for arch %~1...
    pushd %~dp0..\buildtree\libpng\projects\vstudioauto
    msbuild /p:Configuration=Release;Platform=%~1 /t:libpng vstudio.sln || exit /b 1
    msbuild "/p:Configuration=Release Library;Platform=%~1" /t:libpng vstudio.sln || exit /b 1
    popd

    :: Install libpng
    echo Installing libpng for arch %~1...
    pushd %~dp0..\buildtree\libpng\projects\vstudioauto
    xcopy Release\%~1\libpng.dll %~dp0..\libs\libpng\%~1\bin\* /Y
    xcopy Release\%~1\libpng.pdb %~dp0..\libs\libpng\%~1\bin\* /Y
    xcopy ..\..\png.h %~dp0..\libs\libpng\%~1\include\libpng16\* /Y
    xcopy ..\..\pngconf.h %~dp0..\libs\libpng\%~1\include\libpng16\* /Y
    xcopy ..\..\pnglibconf.h %~dp0..\libs\libpng\%~1\include\libpng16\* /Y
    xcopy Release\%~1\libpng.lib %~dp0..\libs\libpng\%~1\lib\* /Y
    xcopy "Release Library\%~1\libpng_a.*" %~dp0..\libs\libpng\%~1\lib\* /Y
    xcopy Release\%~1\libpng.dll %~dp0..\install\%~1\bin\* /Y
    xcopy Release\%~1\libpng.pdb %~dp0..\install\%~1\bin\* /Y
    xcopy ..\..\png.h %~dp0..\install\%~1\include\libpng16\* /Y
    xcopy ..\..\pngconf.h %~dp0..\install\%~1\include\libpng16\* /Y
    xcopy ..\..\pnglibconf.h %~dp0..\install\%~1\include\libpng16\* /Y
    xcopy Release\%~1\libpng.lib %~dp0..\install\%~1\lib\* /Y
    xcopy "Release Library\%~1\libpng_a.*" %~dp0..\install\%~1\lib\* /Y
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