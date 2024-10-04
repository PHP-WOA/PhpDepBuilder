@echo off
setlocal

:: Input parameters
set "version=%1"

if /i "%version%"=="" set "version=master"

:: Define architecture array
set "arch_list=x64 x86 arm arm64"

:: Checkout postgresql repository
echo Checking out postgresql repository with version %version%...
if not exist %~dp0..\buildtree\postgresql git clone --branch %version% https://github.com/PHP-WOA/postgresql %~dp0..\buildtree\postgresql || goto :failure


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

    :: Build postgresql
    echo Building postgresql for arch %~1...
    pushd %~dp0..\buildtree\postgresql\src\tools\msvc
    call clean.bat
    echo ^$config-^>^{openssl^} = '%~dp0..\install\%~1'; > config.pl
    perl mkvcbuild.pl || exit /b 1
    popd
    pushd %~dp0..\buildtree\postgresql
    msbuild /p:Configuration=Release;Platform=%~1 libpq.vcxproj || exit /b 1
    msbuild /p:Configuration=Release;Platform=%~1;ConfigurationType=StaticLibrary;TargetName=libpq_a;IntDir=.\ReleaseStatic\libpq\;OutDir=.\ReleaseStatic\libpq\ libpq.vcxproj || exit /b 1
    popd

    :: Install postgresql
    echo Installing postgresql for arch %~1...
    pushd %~dp0..\buildtree\postgresql
    xcopy Release\libpq\libpq.dll %~dp0..\libs\postgresql\%~1\bin\* /Y
    xcopy Release\libpq\libpq.pdb %~dp0..\libs\postgresql\%~1\bin\* /Y
    xcopy src\include\pg_config.h %~dp0..\libs\postgresql\%~1\include\libpq\* /Y
    xcopy src\include\pg_config_ext.h %~dp0..\libs\postgresql\%~1\include\libpq\* /Y
    xcopy src\include\postgres_ext.h %~dp0..\libs\postgresql\%~1\include\libpq\* /Y
    xcopy src\include\libpq\*.h %~dp0..\libs\postgresql\%~1\include\libpq\* /Y
    xcopy src\interfaces\libpq\*.h %~dp0..\libs\postgresql\%~1\include\libpq\* /Y
    xcopy src\include\common\md5.h %~dp0..\libs\postgresql\%~1\include\libpq\* /Y
    xcopy src\include\common\ip.h %~dp0..\libs\postgresql\%~1\include\libpq\* /Y
    xcopy Release\libpq\libpq.lib %~dp0..\libs\postgresql\%~1\lib\* /Y
    xcopy ReleaseStatic\libpq\libpq_a.lib %~dp0..\libs\postgresql\%~1\lib\* /Y
    xcopy ReleaseStatic\libpq\libpq_a.pdb %~dp0..\libs\postgresql\%~1\lib\* /Y
    xcopy Release\libpq\libpq.dll %~dp0..\install\%~1\bin\* /Y
    xcopy Release\libpq\libpq.pdb %~dp0..\install\%~1\bin\* /Y
    xcopy src\include\pg_config.h %~dp0..\install\%~1\include\libpq\* /Y
    xcopy src\include\pg_config_ext.h %~dp0..\install\%~1\include\libpq\* /Y
    xcopy src\include\postgres_ext.h %~dp0..\install\%~1\include\libpq\* /Y
    xcopy src\include\libpq\*.h %~dp0..\install\%~1\include\libpq\* /Y
    xcopy src\interfaces\libpq\*.h %~dp0..\install\%~1\include\libpq\* /Y
    xcopy src\include\common\md5.h %~dp0..\install\%~1\include\libpq\* /Y
    xcopy src\include\common\ip.h %~dp0..\install\%~1\include\libpq\* /Y
    xcopy Release\libpq\libpq.lib %~dp0..\install\%~1\lib\* /Y
    xcopy ReleaseStatic\libpq\libpq_a.lib %~dp0..\install\%~1\lib\* /Y
    xcopy ReleaseStatic\libpq\libpq_a.pdb %~dp0..\install\%~1\lib\* /Y
    popd
    pushd %~dp0..\buildtree\postgresql\src\tools\msvc
    call clean.bat
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