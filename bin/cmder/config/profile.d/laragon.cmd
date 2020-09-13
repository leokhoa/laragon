@echo off

echo %CMDER_ROOT% | findstr /i "laragon" >nul
if "%ERRORLEVEL%" equ "0" call %cmder_root%\..\..\etc\cmder\laragon.cmd
exit /b 0
