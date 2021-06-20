@echo off

:: Laragon Start -------------------------------------------------------------------

if exist "%CMDER_ROOT%\..\git" (
    set "GIT_INSTALL_ROOT=%CMDER_ROOT%\..\git"
)

if exist "%GIT_INSTALL_ROOT%\post-install.bat" (
    echo Running Git for Windows one time Post Install....
	pushd "%GIT_INSTALL_ROOT%"
    call "%GIT_INSTALL_ROOT%\git-bash.exe" --no-needs-console --hide --no-cd --command=post-install.bat
	@DEL post-install.bat

	popd
    :: cd /d %USERPROFILE%
	rem
)

for /f "delims=" %%i in ("%CMDER_ROOT%\..\..\usr") do set USER_DIR=%%~fi
set USR_DIR=%USER_DIR%

if exist "%CMDER_ROOT%\..\laragon\laragon.cmd" (
    :: call Laragon own commands
    call "%CMDER_ROOT%\..\laragon\laragon.cmd"
)


if exist "%USER_DIR%\user.cmd" (
    rem create this file and place your own command in there
    call "%USER_DIR%\user.cmd"
) else (
    echo Creating user startup file: "%USER_DIR%\user.cmd"
    (
    echo :: use this file to run your own startup commands
    echo :: use  in front of the command to prevent printing the command
    echo.
    echo :: call start-ssh-agent.cmd
    echo :: set PATH=%%USER_DIR%%\bin\whatever;%%PATH%%
	echo.
	echo :: cmd /c start http://localhost 
    echo.
    ) > "%USER_DIR%\user.cmd"
    
    :: cd /d "%CMDER_ROOT%\..\..\www"
	rem
)

:: Laragon End -------------------------------------------------------------------
    
exit /b 0
