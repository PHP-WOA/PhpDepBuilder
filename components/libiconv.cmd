@echo off
setlocal

:: Input parameters
set "version=%1"

if /i "%version%"=="" set "version=master"

:: Define architecture array
set "arch_list=x64 x86 arm arm64"

:: Checkout libiconv repository
echo Checking out libiconv repository with version %version%...
if not exist %~dp0..\buildtree\libiconv git clone --branch %version% https://github.com/PHP-WOA/libiconv %~dp0..\buildtree\libiconv || goto :failure


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

    :: Build libiconv
    echo Building libiconv for arch %~1...
    pushd %~dp0..\buildtree\libiconv\msvcauto
    msbuild /p:Configuration=Release;Platform=%~1 libiconv.sln || exit /b 1
    popd

    :: Install libiconv
    echo Installing libiconv for arch %~1...
    pushd %~dp0..\buildtree\libiconv\msvcauto
    xcopy Release\%~1\libiconv.dll %~dp0..\libs\libiconv\%~1\bin\ /Y /E
    xcopy Release\%~1\libiconv.pdb %~dp0..\libs\libiconv\%~1\bin\ /Y /E
    xcopy Release\%~1\libiconv_a.lib %~dp0..\libs\libiconv\%~1\lib\ /Y /E
    xcopy Release\%~1\libiconv.lib %~dp0..\libs\libiconv\%~1\lib\ /Y /E
    xcopy Release\%~1\libiconv_a.pdb %~dp0..\libs\libiconv\%~1\lib\ /Y /E
    xcopy ..\source\include\iconv.h %~dp0..\libs\libiconv\%~1\include\* /Y
    xcopy Release\%~1\libiconv.dll %~dp0..\install\%~1\bin\ /Y /E
    xcopy Release\%~1\libiconv.pdb %~dp0..\install\%~1\bin\ /Y /E
    xcopy Release\%~1\libiconv_a.lib %~dp0..\install\%~1\lib\ /Y /E
    xcopy Release\%~1\libiconv.lib %~dp0..\install\%~1\lib\ /Y /E
    xcopy Release\%~1\libiconv_a.pdb %~dp0..\install\%~1\lib\ /Y /E
    xcopy ..\source\include\iconv.h %~dp0..\install\%~1\include\* /Y
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