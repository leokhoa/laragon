@echo off

SET CMDER_ROOT=%~dp0

@if "%2"=="" (SET FULL_TITLE=%1) else (SET FULL_TITLE=%2) 

for %%f in (%FULL_TITLE%) do set TER_TITLE=%%~nxf
title %TER_TITLE% - %FULL_TITLE%

:: Remove trailing '\'
@if "%CMDER_ROOT:~-1%" == "\" SET CMDER_ROOT=%CMDER_ROOT:~0,-1%

cd /d "%1"

cmd /k %CMDER_ROOT%\vendor\init.bat "%2" 