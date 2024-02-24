@echo off
 
@if "%2"=="" (SET FULL_TITLE=%1) else (SET FULL_TITLE=%2) 
::SET FULL_TITLE=%1 
for %%f in (%FULL_TITLE%) do set TER_TITLE=%%~nxf
title %TER_TITLE% - %FULL_TITLE%

 
call %~dp0laragon.cmd

cd /d "%1"

if not '"%2"'=='""""' if not '"%2"'=='""' (
    call "%2"
) else (
    rem 
)
