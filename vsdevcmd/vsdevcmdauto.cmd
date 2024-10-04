@echo off
setlocal enabledelayedexpansion

set arch=%~1
if "%~1"=="" (
   set "arch=x64"
)


set "vs="
set "vsnum="
set "vsyear="



set "toolset="
for %%T in (vc15 2017 vs16 2019) do (
    if "!vs!"=="%%T" (
        set "vs=%%T"
        set "vsyear=%%U"
    )
)


for %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    set "DriveName=%%d"
    if exist "!DriveName!:\" (
        :: Search for vswhere.exe
        for /f "delims=" %%F in ('dir /a-d /b /s !DriveName!:\vswhere.exe') do (
            set "vswherePath=%%F"
            goto :foundVswhere
        )
    )
)

echo vswhere.exe not found
exit /b 1

:foundVswhere
echo Found vswhere.exe at: !vswherePath!

for /f "delims=" %%T in ('call "!vswherePath!" -latest -find "VC\Auxiliary\Build"') do (
    set "devcmddir=%%T"
)

if /i "!devcmddir!" == "" (
    echo No VS found.
    exit /b 1
)
echo Found Developer cmd path at: !devcmddir!

set "archprefix="
if "%arch%"=="x64" (
    set "archprefix=x64"
) else if "%arch%"=="x86" (
    set "archprefix=x86"
) else if "%arch%"=="arm" (
    set "archprefix=x64_arm"
) else if "%arch%"=="arm64" (
    set "archprefix=x64_arm64"
)

if not defined archprefix (
    echo no suitable archprefix available
    exit /b 1
)

endlocal&set "devcmddir=%devcmddir%"&set "archprefix=%archprefix%"
call "%devcmddir%\vcvarsall.bat" %archprefix%
exit /b 0