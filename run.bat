@echo off
setlocal

REM Name of the file you want to run (same directory as this BAT)
set "target=sort.ps1"

REM Get current directory
set "curdir=%~dp0"

REM Run the file with PowerShell, capture errors
powershell -NoProfile -ExecutionPolicy Bypass -File "%curdir%%target%" 2>"%curdir%error.log"

REM Check if error log has content
for %%A in ("%curdir%error.log") do (
    if %%~zA EQU 0 del "%curdir%error.log"
)

endlocal
pause
