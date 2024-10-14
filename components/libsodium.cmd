@echo off
setlocal

:: Input parameters
set "version=%1"

if /i "%version%"=="" set "version=master"

:: Define architecture array
set "arch_list=x64 x86 arm arm64"

:again
:: Checkout libsodium repository
echo Checking out libsodium repository with version %version%...
if not exist %~dp0..\buildtree\libsodium git clone --branch %version% https://github.com/PHP-WOA/libsodium %~dp0..\buildtree\libsodium || goto :again


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

    :: Build libsodium
    echo Building libsodium for arch %~1...
    pushd %~dp0..\buildtree\libsodium\builds\msvc\vsauto
    msbuild /p:Configuration=StaticRelease;Platform=%~1 libsodium.sln || exit /b 1
    msbuild /p:Configuration=DynRelease;Platform=%~1 libsodium.sln || exit /b 1
    popd

    :: Install libsodium
    echo Installing libsodium for arch %~1...
    pushd %~dp0..\buildtree\libsodium
    xcopy bin\%~1\Release\dynamic\libsodium.dll %~dp0..\libs\libsodium\%~1\bin\* /Y
    xcopy bin\%~1\Release\dynamic\libsodium.pdb %~dp0..\libs\libsodium\%~1\bin\* /Y
    xcopy /e src\libsodium\include\*.h %~dp0..\libs\libsodium\%~1\include\* /Y
    xcopy bin\%~1\Release\dynamic\libsodium.lib %~dp0..\libs\libsodium\%~1\lib\* /Y
    copy bin\%~1\Release\static\libsodium.lib %~dp0..\libs\libsodium\%~1\lib\libsodium_a.lib /Y
    xcopy bin\%~1\Release\dynamic\libsodium.dll %~dp0..\install\%~1\bin\* /Y
    xcopy bin\%~1\Release\dynamic\libsodium.pdb %~dp0..\install\%~1\bin\* /Y
    xcopy /e src\libsodium\include\*.h %~dp0..\install\%~1\include\* /Y
    xcopy bin\%~1\Release\dynamic\libsodium.lib %~dp0..\install\%~1\lib\* /Y
    copy bin\%~1\Release\static\libsodium.lib %~dp0..\install\%~1\lib\libsodium_a.lib /Y
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