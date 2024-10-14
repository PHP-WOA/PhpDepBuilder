@echo off
setlocal

:: Input parameters
set "version=%1"

if /i "%version%"=="" set "version=master"

:: Define architecture array
set "arch_list=x64 x86 arm arm64"

:again
:: Checkout curl repository
echo Checking out curl repository with version %version%...
if not exist %~dp0..\buildtree\curl git clone --branch %version% https://github.com/PHP-WOA/curl %~dp0..\buildtree\curl || goto :again

:: Loop through architectures
for %%A in (%arch_list%) do (
    call :compile %%A || goto :failure
)
goto :success
:compile

    :: Setup MSVC development environment
    echo Setting up MSVC development environment for arch %~1
    call "%~dp0..\vsdevcmd\vsdevcmdauto.cmd" %~1

    :: Build curl
    echo Building curl for arch %~1...
    pushd %~dp0..\buildtree\curl\winbuild
    nmake /f Makefile.vc mode=static WITH_DEVEL=%~dp0..\install\%~1 WITH_SSL=static WITH_ZLIB=static WITH_NGHTTP2=dll WITH_SSH2=dll ENABLE_WINSSL=no USE_IDN=yes ENABLE_IPV6=yes GEN_PDB=yes DEBUG=no MACHINE=%~1 CURL_DISABLE_MQTT=1 RTLIBCFG=static || exit /b 1
    popd

    :: Install curl
    echo Installing curl for arch %~1...
    xcopy %~dp0..\buildtree\curl\builds\libcurl-vc-%~1-release-static-ssl-static-zlib-static-ssh2-dll-ipv6-sspi-nghttp2-dll %~dp0..\libs\curl\%~1\ /Y /E
    xcopy %~dp0..\buildtree\curl\builds\libcurl-vc-%~1-release-static-ssl-static-zlib-static-ssh2-dll-ipv6-sspi-nghttp2-dll %~dp0..\install\%~1\ /Y /E


exit /b
:failure
echo Error occurred when compiling.
pause
exit /b 1
:success
endlocal
exit /b 0