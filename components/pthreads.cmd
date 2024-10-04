@echo off
setlocal

:: Input parameters
set "version=%1"

if /i "%version%"=="" set "version=main"

:: Define architecture array
set "arch_list=x64 x86 arm64 arm"

:: Checkout pthreads repository
echo Checking out pthreads repository with version %version%...
if not exist %~dp0..\buildtree\pthreads git clone --branch %version% https://github.com/PHP-WOA/pthreads %~dp0..\buildtree\pthreads || goto :failure

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

    :: Build pthreads
    echo Building pthreads for arch %arch%...
    pushd %~dp0..\buildtree\pthreads
    nmake clean VC || exit /b 1
    popd

    :: Install pthreads
    echo Installing pthreads for arch %~1...
    pushd %~dp0..\buildtree\pthreads
    xcopy pthreadVC?.dll %~dp0..\libs\pthreads\%~1\bin\*
    xcopy pthreadVC?.pdb %~dp0..\libs\pthreads\%~1\bin\*
    xcopy _ptw32.h %~dp0..\libs\pthreads\%~1\include\*
    xcopy pthread.h %~dp0..\libs\pthreads\%~1\include\*
    xcopy sched.h %~dp0..\libs\pthreads\%~1\include\*
    xcopy pthreadVC?.lib %~dp0..\libs\pthreads\%~1\lib\*
    xcopy pthreadVC?.dll %~dp0..\install\%~1\bin\*
    xcopy pthreadVC?.pdb %~dp0..\install\%~1\bin\*
    xcopy _ptw32.h %~dp0..\install\%~1\include\*
    xcopy pthread.h %~dp0..\install\%~1\include\*
    xcopy sched.h %~dp0..\install\%~1\include\*
    xcopy pthreadVC?.lib %~dp0..\install\%~1\lib\*
    nmake clean
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