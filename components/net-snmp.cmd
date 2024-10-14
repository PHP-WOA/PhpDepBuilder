@echo off
setlocal

:: Input parameters
set "version=%1"

if /i "%version%"=="" set "version=master"

:: Define architecture array
set "arch_list=x64 x86 arm arm64"

:again
:: Checkout net-snmp repository
echo Checking out net-snmp repository with version %version%...
if not exist %~dp0..\buildtree\net-snmp git clone --branch %version% https://github.com/PHP-WOA/net-snmp %~dp0..\buildtree\net-snmp || goto :again

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

    :: Build net-snmp
    echo Building net-snmp for arch %~1...
    pushd %~dp0..\buildtree\net-snmp\win32
    perl Configure --with-sdk --with-ssl --with-sslincdir=%~dp0..\install\%~1\include --with-ssllibdir=%~dp0..\install\%~1\lib  --config=release --linktype=static --with-ipv6 --prefix=..\install
    nmake libsnmp || exit /b 1
    nmake libagent || exit /b 1
    nmake netsnmpmibs || exit /b 1
    nmake snmpd || exit /b 1
    popd

    :: Install net-snmp
    echo Installing net-snmp for arch %~1...
    pushd %~dp0..\buildtree\net-snmp\win32
    xcopy bin\release\snmpd.exe %~dp0..\libs\net-snmp\%~1\bin\* /Y
    xcopy bin\release\snmpd.pdb %~dp0..\libs\net-snmp\%~1\bin\* /Y
    xcopy /e ..\include\net-snmp\*.h %~dp0..\libs\net-snmp\%~1\include\net-snmp\* /Y
    xcopy /e ..\win32\net-snmp\*.h %~dp0..\libs\net-snmp\%~1\include\net-snmp\* /Y
    xcopy include\net-snmp\library\README %~dp0..\libs\net-snmp\%~1\include\net-snmp\library\* /Y
    xcopy lib\release\netsnmp.lib %~dp0..\libs\net-snmp\%~1\lib\* /Y
    xcopy libsnmp\release\libsnmp.pdb %~dp0..\libs\net-snmp\%~1\lib\* /Y
    xcopy ..\mibs\* %~dp0..\libs\net-snmp\%~1\share\mibs\* /Y
    xcopy bin\release\snmpd.exe %~dp0..\install\%~1\bin\* /Y
    xcopy bin\release\snmpd.pdb %~dp0..\install\%~1\bin\* /Y
    xcopy /e ..\include\net-snmp\*.h %~dp0..\install\%~1\include\net-snmp\* /Y
    xcopy /e ..\win32\net-snmp\*.h %~dp0..\install\%~1\include\net-snmp\* /Y
    xcopy include\net-snmp\library\README %~dp0..\install\%~1\include\net-snmp\library\* /Y
    xcopy lib\release\netsnmp.lib %~dp0..\install\%~1\lib\* /Y
    xcopy libsnmp\release\libsnmp.pdb %~dp0..\install\%~1\lib\* /Y
    xcopy ..\mibs\* %~dp0..\install\%~1\share\mibs\* /Y
    nmake clean || exit /b 1
    del /s /q *.obj
    del /s /q *.lib
    del /s /q *.pdb
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