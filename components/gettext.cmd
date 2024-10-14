@echo off
setlocal

:: Input parameters
set "version=%1"

if /i "%version%"=="" set "version=master"

:: Define architecture array
set "arch_list=x64 x86 arm arm64"

:: Checkout gettext repository
echo Checking out gettext repository with version %version%...
if not exist %~dp0..\buildtree\gettext git clone --branch %version% https://github.com/PHP-WOA/gettext %~dp0..\buildtree\gettext || goto :failure


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

    :: Build gettext
    echo Building gettext for arch %~1...
    pushd %~dp0..\buildtree\gettext\MSVCAUTO
    msbuild /p:Configuration=Release;Platform=%~1 gettext.sln || exit /b 1
    popd

    :: Install gettext
    echo Installing gettext for arch %~1...
    pushd %~dp0..\buildtree\gettext
    mkdir %~dp0..\libs\gettext\%~1\include
    copy source\gettext-runtime\intl\libgnuintl.h %~dp0..\libs\gettext\%~1\include\libintl.h /Y
    xcopy MSVCAUTO\%~1\Release\libintl.dll %~dp0..\libs\gettext\%~1\bin\* /Y
    xcopy MSVCAUTO\%~1\Release\libintl.pdb %~dp0..\libs\gettext\%~1\bin\* /Y
    xcopy MSVCAUTO\%~1\Release\libintl.lib %~dp0..\libs\gettext\%~1\lib\* /Y
    xcopy MSVCAUTO\%~1\Release\libintl_a.lib %~dp0..\libs\gettext\%~1\lib\* /Y
    xcopy MSVCAUTO\%~1\Release\libintl_a.pdb %~dp0..\libs\gettext\%~1\lib\* /Y
    mkdir %~dp0..\install\%~1\include
    copy source\gettext-runtime\intl\libgnuintl.h %~dp0..\install\%~1\include\libintl.h /Y
    xcopy MSVCAUTO\%~1\Release\libintl.dll %~dp0..\install\%~1\bin\* /Y
    xcopy MSVCAUTO\%~1\Release\libintl.pdb %~dp0..\install\%~1\bin\* /Y
    xcopy MSVCAUTO\%~1\Release\libintl.lib %~dp0..\install\%~1\lib\* /Y
    xcopy MSVCAUTO\%~1\Release\libintl_a.lib %~dp0..\install\%~1\lib\* /Y
    xcopy MSVCAUTO\%~1\Release\libintl_a.pdb %~dp0..\install\%~1\lib\* /Y
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