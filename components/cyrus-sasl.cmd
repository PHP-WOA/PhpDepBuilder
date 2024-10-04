@echo off
setlocal

:: Input parameters
set "version=%1"

if /i "%version%"=="" set "version=master"

:: Define architecture array
set "arch_list=x64 x86 arm arm64"

:: Checkout cyrus-sasl repository
echo Checking out cyrus-sasl repository with version %version%...
if not exist %~dp0..\buildtree\cyrus-sasl git clone --branch %version% https://github.com/PHP-WOA/cyrus-sasl %~dp0..\buildtree\cyrus-sasl || goto :failure


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

    :: Build cyrus-sasl
    echo Building cyrus-sasl for arch %arch%...
    pushd %~dp0..\buildtree\cyrus-sasl\win32
    msbuild /p:Configuration=Release;Platform=%~1 cyrus-sasl-sasldb.sln || exit /b 1
    popd

    :: Install cyrus-sasl
    echo Installing cyrus-sasl for arch %~1...
    if /i "%~1"=="x86" (
    xcopy %~dp0..\buildtree\cyrus-sasl\win32\Win32\Release\libsasl.dll %~dp0..\libs\cyrus-sasl\%~1\bin\ /Y
    xcopy %~dp0..\buildtree\cyrus-sasl\win32\Win32\Release\libsasl.pdb %~dp0..\libs\cyrus-sasl\%~1\bin\ /Y
    xcopy %~dp0..\buildtree\cyrus-sasl\win32\Win32\Release\plugin_sasldb.dll %~dp0..\libs\cyrus-sasl\%~1\bin\sasl2\* /Y
    xcopy %~dp0..\buildtree\cyrus-sasl\win32\Win32\Release\plugin_sasldb.pdb %~dp0..\libs\cyrus-sasl\%~1\bin\sasl2\* /Y
    xcopy %~dp0..\buildtree\cyrus-sasl\include\*.h %~dp0..\libs\cyrus-sasl\%~1\include\sasl\* /Y
    xcopy %~dp0..\buildtree\cyrus-sasl\win32\Win32\Release\libsasl.lib %~dp0..\libs\cyrus-sasl\%~1\lib\* /Y
    xcopy %~dp0..\libs\cyrus-sasl\%~1\ %~dp0..\install\%~1\* /E /Y
    ) else (
    xcopy %~dp0..\buildtree\cyrus-sasl\win32\%~1\Release\libsasl.dll %~dp0..\libs\cyrus-sasl\%~1\bin\ /Y
    xcopy %~dp0..\buildtree\cyrus-sasl\win32\%~1\Release\libsasl.pdb %~dp0..\libs\cyrus-sasl\%~1\bin\ /Y
    xcopy %~dp0..\buildtree\cyrus-sasl\win32\%~1\Release\plugin_sasldb.dll %~dp0..\libs\cyrus-sasl\%~1\bin\sasl2\* /Y
    xcopy %~dp0..\buildtree\cyrus-sasl\win32\%~1\Release\plugin_sasldb.pdb %~dp0..\libs\cyrus-sasl\%~1\bin\sasl2\* /Y
    xcopy %~dp0..\buildtree\cyrus-sasl\include\*.h %~dp0..\libs\cyrus-sasl\%~1\include\sasl\* /Y
    xcopy %~dp0..\buildtree\cyrus-sasl\win32\%~1\Release\libsasl.lib %~dp0..\libs\cyrus-sasl\%~1\lib\* /Y
    xcopy %~dp0..\libs\cyrus-sasl\%~1\ %~dp0..\install\%~1\*  /E /Y
    )
endlocal
exit /b
:failure
echo Error occurred when compiling.
pause
exit /b 1
:success
endlocal
exit /b 0