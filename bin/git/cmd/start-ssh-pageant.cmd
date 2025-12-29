@REM Do not use "echo off" to not affect any child calls.

@REM The goal of this script is to simplify launching `ssh-pageant` at
@REM logon, typically by dropping a shortcut into the Startup folder, so
@REM that Pageant (the PuTTY authentication agent) will always be
@REM accessible. No attempt is made to load SSH keys, since this is
@REM normally handled directly by Pageant, and no interactive shell
@REM will be launched.
@REM 
@REM The `ssh-pageant` utility is launched with the `-r` (reuse socket)
@REM option, to ensure that only a single running incarnation (per user)
@REM will be required... instead of launching a separate process for
@REM every interactive Git Bash session. A side effect of this selection
@REM is that the SSH_AUTH_SOCK environment variable *must* be set prior
@REM to running this script, with the value specifying a unix-style socket
@REM path, and needs to be consistent for all git-related processes. The
@REM easiest way to do this is to set a persistent USER environment
@REM variable, which (under Windows 7) can be done via Control Panel
@REM under System / Advanced System Settings. A typical value would look
@REM similar to:
@REM
@REM    SSH_AUTH_SOCK=/tmp/.ssh-pageant-USERNAME
@REM

@REM Enable extensions, the `verify` call is a trick from the setlocal help
@VERIFY other 2>nul
@SETLOCAL EnableDelayedExpansion
@IF ERRORLEVEL 1 (
    @ECHO Unable to enable extensions
    @GOTO failure
)

@REM Ensure that SSH_AUTH_SOCK is set
@if "x" == "x%SSH_AUTH_SOCK%" @(
    @ECHO The SSH_AUTH_SOCK environment variable must be set prior to running this script. >&2
    @ECHO This is typically configured as a persistent USER variable, using a MSYS2 path for >&2
    @ECHO the ssh-pageant authentication socket as the value. Something similar to: >&2
    @ECHO. >&2
    @ECHO    SSH_AUTH_SOCK=/tmp/.ssh-pageant-%USERNAME% >&2
    @GOTO failure
)

@REM Start ssh-pageant if needed by git
@FOR %%i IN ("git.exe") DO @SET GIT=%%~$PATH:i
@IF EXIST "%GIT%" @(
    @REM Get the ssh-pageant executable
    @FOR %%i IN ("ssh-pageant.exe") DO @SET SSH_PAGEANT=%%~$PATH:i
    @IF NOT EXIST "%SSH_PAGEANT%" @(
        @FOR %%s IN ("%GIT%") DO @SET GIT_DIR=%%~dps
        @FOR %%s IN ("!GIT_DIR!") DO @SET GIT_DIR=!GIT_DIR:~0,-1!
        @FOR %%s IN ("!GIT_DIR!") DO @SET GIT_ROOT=%%~dps
        @FOR %%s IN ("!GIT_ROOT!") DO @SET GIT_ROOT=!GIT_ROOT:~0,-1!
        @FOR /D %%s in ("!GIT_ROOT!\usr\bin\ssh-pageant.exe") DO @SET SSH_PAGEANT=%%~s
        @IF NOT EXIST "!SSH_PAGEANT!" @GOTO ssh-pageant-done
    )
)

@REM Time to make the donuts!
@ECHO Starting ssh-pageant...
@FOR /f "usebackq tokens=1 delims=;" %%o in (`"%SSH_PAGEANT%" -qra %SSH_AUTH_SOCK%`) DO @ECHO %%o

:ssh-pageant-done
:failure
