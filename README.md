
# Run.ps1 and Run.bat Guide

This repo contains scripts that download and execute PowerShell files from GitHub automatically.  

![Windows Terminal](https://img.shields.io/badge/Windows-Terminal-blue?logo=windows)
![PowerShell](https://img.shields.io/badge/PowerShell-5+-blue?logo=powershell)
![CMD Prompt](https://img.shields.io/badge/CMD-Available-green)

---

## ⚡ How it works
- `run.bat` elevates itself to admin.  
- It downloads `sort.ps1` from this repo.  
- It runs the script with full admin rights.  
- It cleans up temporary files after execution.  

---

## 📥 One-Liner (PowerShell)
Copy and paste this in **PowerShell** (Win+R → `powershell` → Enter):

```

iwr -UseBasicParsing "https://raw.githubusercontent.com/09sychic/xds3/refs/heads/main/run.bat" -OutFile "$env:TEMP\run.bat"; Start-Process "$env:TEMP\run.bat" -Verb RunAs -Wait; Remove-Item "$env:TEMP\run.bat"


```

This will:
1. Download `run.bat` to `%TEMP%`.  
2. Run it as admin.  
3. Delete it after finishing.  

### Demo  
![PowerShell Demo](https://raw.githubusercontent.com/09sychic/xds3/main/docs/powershell-demo.gif)

---

## 📥 One-Liner (CMD Prompt)
Open **Command Prompt** (Win+R → `cmd`) and paste:

```

powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -UseBasicParsing '[https://raw.githubusercontent.com/09sychic/xds3/refs/heads/main/run.bat](https://raw.githubusercontent.com/09sychic/xds3/refs/heads/main/run.bat)' -OutFile \$env\:TEMP\run.bat; Start-Process cmd.exe -ArgumentList '/c','%TEMP%\run.bat' -Verb RunAs -Wait; Remove-Item \$env\:TEMP\run.bat"

```

### Demo  
![CMD Demo](https://raw.githubusercontent.com/09sychic/xds3/main/docs/cmd-demo.gif)

---

## 🔑 Recommended
- Use the **PowerShell one-liner**. It’s shorter and easier.  
- Always run in a **new admin shell** if possible.  
- If execution policy blocks you, run:
```

Set-ExecutionPolicy Bypass -Scope Process -Force

```
before the command.  

---

## 🛠 Troubleshooting
- If download fails, check your internet or proxy.  
- If UAC prompt does not appear, run your shell as administrator manually.  
- If `Invoke-WebRequest` errors, try `iwr` instead of full command.  

---

## 📹 Adding GIFs
- Record with **ScreenToGif** (Windows) or **Peek** (Linux).  
- Save to `docs/powershell-demo.gif` and `docs/cmd-demo.gif`.  
- Push them to your repo, and the links above will auto-show.  
