@echo off
setlocal

:: Input parameters
set "version=%1"

if /i "%version%"=="" set "version=master"

:: Define architecture array
set "arch_list=x64 x86 arm arm64"

:: Checkout enchant repository
echo Checking out enchant repository with version %version%...
if not exist %~dp0..\buildtree\enchant git clone --branch %version% https://github.com/PHP-WOA/enchant %~dp0..\buildtree\enchant || goto :failure


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

    :: Build enchant
    echo Building enchant for arch %~1...
    pushd %~dp0..\buildtree\enchant\msvcauto
    msbuild /p:Configuration=Release;Platform=%~1 enchant2.sln || exit /b 1
    popd

    :: Install enchant
    echo Installing enchant for arch %~1...
    pushd %~dp0..\buildtree\enchant
    xcopy bin\Release\%~1\*.dll %~dp0..\libs\enchant\%~1\bin\* /Y /E
    xcopy bin\Release\%~1\*.pdb %~dp0..\libs\enchant\%~1\bin\* /Y /E
    xcopy bin\Release\%~1\*.lib %~dp0..\libs\enchant\%~1\lib\* /Y /E
    xcopy src\enchant.h %~dp0..\libs\enchant\%~1\include\*
    xcopy bin\Release\%~1\*.dll %~dp0..\install\%~1\bin\* /Y /E
    xcopy bin\Release\%~1\*.pdb %~dp0..\install\%~1\bin\* /Y /E
    xcopy bin\Release\%~1\*.lib %~dp0..\install\%~1\lib\* /Y /E
    xcopy src\enchant.h %~dp0..\install\%~1\include\*
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