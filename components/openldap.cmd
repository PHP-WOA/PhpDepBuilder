@echo off
setlocal

:: Input parameters
set "version=%1"

if /i "%version%"=="" set "version=master"

:: Define architecture array
set "arch_list=x64 x86 arm arm64"

:: Checkout openldap repository
echo Checking out openldap repository with version %version%...
if not exist %~dp0..\buildtree\openldap git clone --branch %version% https://github.com/PHP-WOA/openldap %~dp0..\buildtree\openldap || goto :failure


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

    :: Build openldap
    echo Building openldap for arch %~1...
    pushd %~dp0..\buildtree\openldap\win32\vsauto
    msbuild /p:Configuration=Release;Platform=%~1 liblber.sln || exit /b 1
    popd

    :: Install openldap
    echo Installing openldap for arch %~1...
    pushd %~dp0..\buildtree\openldap
    xcopy /e include\*.h %~dp0..\libs\openldap\%~1\include\openldap\* /Y
    xcopy win32\vsauto\out\liblber\%~1\Release\o*.lib %~dp0..\libs\openldap\%~1\lib\* /Y
    xcopy win32\vsauto\out\liblber\%~1\Release\o*.pdb %~dp0..\libs\openldap\%~1\lib\* /Y
    xcopy win32\vsauto\out\libldap\%~1\Release\o*.lib %~dp0..\libs\openldap\%~1\lib\* /Y
    xcopy win32\vsauto\out\libldap\%~1\Release\o*.pdb %~dp0..\libs\openldap\%~1\lib\* /Y
    xcopy /e include\*.h %~dp0..\install\%~1\include\openldap\* /Y
    xcopy win32\vsauto\out\liblber\%~1\Release\o*.lib %~dp0..\install\%~1\lib\* /Y
    xcopy win32\vsauto\out\liblber\%~1\Release\o*.pdb %~dp0..\install\%~1\lib\* /Y
    xcopy win32\vsauto\out\libldap\%~1\Release\o*.lib %~dp0..\install\%~1\lib\* /Y
    xcopy win32\vsauto\out\libldap\%~1\Release\o*.pdb %~dp0..\install\%~1\lib\* /Y
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