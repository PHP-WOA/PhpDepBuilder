@echo off
setlocal

:: Input parameters
set "version=%1"

if /i "%version%"=="" set "version=master"

:: Define architecture array
set "arch_list=x64 x86 arm arm64"

:: Checkout mpir repository
echo Checking out mpir repository with version %version%...
if not exist %~dp0..\buildtree\mpir git clone --branch %version% https://github.com/PHP-WOA/mpir %~dp0..\buildtree\mpir || goto :failure


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

    :: Build mpir
    echo Building mpir for arch %~1...
    pushd %~dp0..\buildtree\mpir
    if /i "%~1" == "x86" (
      msbuild "/p:Configuration=Release;Platform=Win32" build.vcauto\lib_mpir_gc\lib_mpir_gc.vcxproj || exit /b 1
      msbuild "/p:Configuration=Release;Platform=Win32" build.vcauto\dll_mpir_gc\dll_mpir_gc.vcxproj || exit /b 1
    ) else (
      msbuild "/p:Configuration=Release;Platform=%~1" build.vcauto\lib_mpir_gc\lib_mpir_gc.vcxproj || exit /b 1
      msbuild "/p:Configuration=Release;Platform=%~1" build.vcauto\dll_mpir_gc\dll_mpir_gc.vcxproj || exit /b 1
    )
    popd

    :: Install mpir
    echo Installing mpir for arch %~1...
    pushd %~dp0..\buildtree\mpir
    if /i "%~1" == "x86" (
      xcopy lib\Win32\Release\config.h %~dp0..\libs\mpir\%~1\include\mpir\* /Y
      xcopy lib\Win32\Release\gmp-mparam.h %~dp0..\libs\mpir\%~1\include\mpir\* /Y
      xcopy lib\Win32\Release\gmp.h %~dp0..\libs\mpir\%~1\include\mpir\* /Y
      xcopy lib\Win32\Release\mpir.h %~dp0..\libs\mpir\%~1\include\mpir\* /Y
      xcopy lib\Win32\Release\mpir_a.??? %~dp0..\libs\mpir\%~1\lib\* /Y
      xcopy dll\Win32\Release\mpir.??? %~dp0..\libs\mpir\%~1\bin\* /Y
      xcopy lib\Win32\Release\config.h %~dp0..\install\%~1\include\mpir\* /Y
      xcopy lib\Win32\Release\gmp-mparam.h %~dp0..\install\%~1\include\mpir\* /Y
      xcopy lib\Win32\Release\gmp.h %~dp0..\install\%~1\include\mpir\* /Y
      xcopy lib\Win32\Release\mpir.h %~dp0..\install\%~1\include\mpir\* /Y
      xcopy lib\Win32\Release\mpir_a.??? %~dp0..\install\%~1\lib\* /Y
      xcopy dll\Win32\Release\mpir.??? %~dp0..\install\%~1\bin\* /Y
    ) else (
      xcopy lib\%~1\Release\config.h %~dp0..\libs\mpir\%~1\include\mpir\* /Y
      xcopy lib\%~1\Release\gmp-mparam.h %~dp0..\libs\mpir\%~1\include\mpir\* /Y
      xcopy lib\%~1\Release\gmp.h %~dp0..\libs\mpir\%~1\include\mpir\* /Y
      xcopy lib\%~1\Release\mpir.h %~dp0..\libs\mpir\%~1\include\mpir\* /Y
      xcopy lib\%~1\Release\mpir_a.??? %~dp0..\libs\mpir\%~1\lib\* /Y
      xcopy dll\%~1\Release\mpir.??? %~dp0..\libs\mpir\%~1\bin\* /Y
      xcopy lib\%~1\Release\config.h %~dp0..\install\%~1\include\mpir\* /Y
      xcopy lib\%~1\Release\gmp-mparam.h %~dp0..\install\%~1\include\mpir\* /Y
      xcopy lib\%~1\Release\gmp.h %~dp0..\install\%~1\include\mpir\* /Y
      xcopy lib\%~1\Release\mpir.h %~dp0..\install\%~1\include\mpir\* /Y
      xcopy lib\%~1\Release\mpir_a.??? %~dp0..\install\%~1\lib\* /Y
      xcopy dll\%~1\Release\mpir.??? %~dp0..\install\%~1\bin\* /Y
    )
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