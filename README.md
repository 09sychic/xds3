# XDS3 Downloads Organizer

> **Intelligent Downloads Organizer** - A comprehensive PowerShell script that automatically organizes your Downloads folder with advanced categorization, duplicate detection, and filename processing.

## 🚀 Quick Start

### One-Line Installation & Run (PowerShell - Admin Required)
```powershell
iwr -UseBasicParsing "https://raw.githubusercontent.com/09sychic/xds3/main/sort.ps1" -OutFile "$env:TEMP\sort.ps1"; Start-Process "powershell.exe" -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "$env:TEMP\sort.ps1" -Verb RunAs -Wait; Remove-Item "$env:TEMP\sort.ps1" -ErrorAction SilentlyContinue
```

### Alternative (Command Prompt)
```cmd
powershell -Command "iwr -UseBasicParsing 'https://raw.githubusercontent.com/09sychic/xds3/main/sort.ps1' -OutFile '$env:TEMP\sort.ps1'; Start-Process 'powershell.exe' -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', '$env:TEMP\sort.ps1' -Verb RunAs -Wait; Remove-Item '$env:TEMP\sort.ps1' -ErrorAction SilentlyContinue"
```

### Robust Version with Error Handling
```powershell
try { iwr -UseBasicParsing "https://raw.githubusercontent.com/09sychic/xds3/main/sort.ps1" -OutFile "$env:TEMP\sort.ps1" -ErrorAction Stop; Start-Process "powershell.exe" -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "$env:TEMP\sort.ps1" -Verb RunAs -Wait -ErrorAction Stop } catch { Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red } finally { Remove-Item "$env:TEMP\sort.ps1" -ErrorAction SilentlyContinue }
```

## 📋 Features

### 🎯 **Smart Organization**
- **60+ File Categories**: Automatically sorts files into logical folder structures
- **Content-Aware Detection**: Recognizes TV series, screenshots, school files, memes, and more
- **Extension Mapping**: Comprehensive file type recognition (500+ extensions)

### 🔍 **Advanced Processing**
- **Duplicate Detection**: MD5 hash-based duplicate identification and skipping
- **Filename Sanitization**: Cleans illegal characters and adds timestamps
- **Smart Categorization**: Context-aware folder placement based on filename patterns

### 📊 **Monitoring & Logging**
- **Detailed Logging**: Separate debug and error logs with timestamps
- **Progress Tracking**: Real-time processing status and completion statistics
- **Windows Notifications**: Toast notifications with fallback to MessageBox

### ⚙️ **Automation Options**
- **Scheduled Tasks**: Optional daily automation at 2 AM
- **Batch Processing**: Handles large file collections efficiently
- **Safe Operations**: Skips temporary and system files

## 📁 Folder Structure

The script organizes files into these main categories:

### 📄 **Documents**
- `Documents\Word` - Word documents, templates
- `Documents\Excel` - Spreadsheets, CSV files
- `Documents\PowerPoint` - Presentations
- `Documents\PDF` - PDF files
- `Documents\Text` - Plain text, markdown, logs
- `Documents\School` - Academic files (auto-detected)
- `Documents\Ebooks` - Digital books
- `Documents\Contracts` - Legal documents
- `Documents\Manuals` - User guides, manuals

### 🖼️ **Images**
- `Images\Standard` - JPEG, PNG, GIF, WebP
- `Images\Raw` - Camera raw files (ARW, CR2, NEF, etc.)
- `Images\Vector` - SVG, AI, EPS files
- `Images\Design` - PSD, XD, Sketch files
- `Images\Screenshots` - Screen captures (auto-detected)
- `Images\Icons` - ICO, ICNS files
- `Images\Memes` - Funny images (auto-detected)

### 🎵 **Audio**
- `Audio\Music` - MP3, FLAC, WAV, etc.
- `Audio\Podcasts` - Podcast episodes (auto-detected)
- `Audio\Audiobooks` - M4B, AA files
- `Audio\Project` - DAW project files
- `Audio\Samples` - Audio samples, loops

### 🎬 **Video**
- `Video\Movies` - MP4, MKV, AVI, etc.
- `Video\Series` - TV shows (auto-detected by S01E01 pattern)
- `Video\Clips` - Short video clips
- `Video\Subtitles` - SRT, ASS subtitle files
- `Video\Project` - Video editing projects

### 📦 **Archives**
- `Archives\Standard` - ZIP, RAR, 7Z files
- `Archives\Disk` - ISO, IMG disk images
- `Archives\Cabinet` - CAB, MSI installers
- `Archives\Packages` - DEB, RPM packages

### 💻 **Programs**
- `Programs\Windows` - EXE, MSI, BAT files
- `Programs\Mac` - DMG, PKG files
- `Programs\Linux` - AppImage, DEB, RPM
- `Programs\Mobile` - APK, IPA files
- `Programs\Scripts` - Various script files

### 🔧 **Development**
- `Code\Web` - HTML, CSS, JavaScript, PHP
- `Code\Languages` - Python, Java, C++, etc.
- `Code\Data` - JSON, XML, YAML files
- `Code\Database` - SQL, DB files
- `Code\Config` - Configuration files
- `Development\Projects` - IDE project files
- `Development\Libraries` - DLL, JAR, SO files

### 🎮 **Games**
- `Games\ROMs` - Game ROM files
- `Games\Saves` - Save game files
- `Games\Mods` - Game modifications
- `Games\Steam` - Steam-related files

### 🔬 **Specialized Categories**
- `3D\Models` - 3D model files (OBJ, FBX, etc.)
- `3D\CAD` - CAD files (DWG, STEP, etc.)
- `Scientific\Data` - Research data files
- `Business\Reports` - Business documents
- `MediaProduction\RAW` - Professional video formats
- `Fonts\*` - Font files by type
- `System\*` - System files, logs, backups

## ⚡ Configuration Options

### 🔧 **Customizable Settings**
```powershell
$maxFileNameLength = 100              # Maximum filename length
$enableDuplicateDetection = $true     # Enable/disable duplicate detection
$enableFilenameProcessing = $true     # Enable/disable filename sanitization
$enableScheduling = $false            # Enable/disable scheduled task creation
```

### 🚫 **Skipped File Types**
The script automatically skips temporary files:
- `.tmp`, `.crdownload`, `.part`, `.filepart`
- `.download`, `.opdownload`, `.!qb`, `.bc!`, `.dlm`

## 📊 Smart Detection Features

### 🎭 **Pattern Recognition**
- **TV Series**: Detects S01E01, Season 1, Episode patterns
- **Screenshots**: Identifies screenshot, snip, capture keywords
- **School Files**: Recognizes homework, assignment, exam patterns
- **Podcasts**: Detects podcast, episode, interview keywords
- **Memes**: Identifies meme, funny, reaction content
- **Business**: Recognizes reports, proposals, contracts

### 🔄 **Duplicate Handling**
- **MD5 Hash Comparison**: Fast and reliable duplicate detection
- **Memory Caching**: Efficient hash storage for large batches
- **Duplicate Logging**: Tracks all duplicate files found

### 🏷️ **Filename Processing**
- **Illegal Character Removal**: Sanitizes `< > : " / \ | ? *`
- **Timestamp Addition**: Adds creation date (MMM-DD-YYYY format)
- **Length Limiting**: Prevents filesystem errors from long names

## 📝 Logging System

### 📋 **Log Files**
- `downloads-organizer-debug.log` - Detailed operation log
- `downloads-organizer-errors.log` - Error-specific log

### 📊 **Log Information**
- Timestamped entries for all operations
- Processing progress with percentages
- Detailed error messages with stack traces
- Operation summaries and statistics

## 🔔 Notification System

### 📱 **Windows Toast Notifications**
- Modern Windows 10/11 toast notifications
- Automatic fallback to MessageBox on older systems
- Customizable notification timeout (5 minutes)
- Operation summary with file counts

## ⏰ Scheduling (Optional)

### 🕐 **Automated Organization**
When `$enableScheduling = $true`:
- Creates Windows Scheduled Task
- Runs daily at 2:00 AM
- Highest privileges for file access
- Battery-friendly settings

## 🛡️ Safety Features

### 🔒 **Safe Operations**
- **No Overwrites**: Files are moved, not copied
- **Existence Checking**: Verifies files before operations
- **Error Recovery**: Continues processing after individual failures
- **Hidden File Skipping**: Ignores system and hidden files

### 📊 **Progress Tracking**
- Real-time percentage progress
- File-by-file processing status
- Comprehensive operation statistics
- Memory usage optimization

## 📈 Performance

### ⚡ **Optimizations**
- **Efficient Hashing**: MD5 for fast duplicate detection
- **Memory Caching**: Hash results stored in memory
- **Batch Processing**: Handles thousands of files
- **Minimal I/O**: Single pass through directory structure

### 📊 **Typical Performance**
- **1000 files**: ~2-3 minutes
- **5000 files**: ~8-10 minutes
- **Memory Usage**: <50MB for most operations
- **CPU Usage**: Low, primarily I/O bound

## 🔧 Usage Examples

### Basic Usage
```powershell
# Download and run immediately
.\sort.ps1
```

### Custom Configuration
```powershell
# Edit script variables before running
$enableDuplicateDetection = $false
$maxFileNameLength = 150
$enableScheduling = $true
```

### Manual Scheduling
```powershell
# Create scheduled task manually
schtasks /create /tn "Downloads-Organizer" /tr "powershell.exe -File C:\path\to\sort.ps1" /sc daily /st 02:00
```

## 🔍 Troubleshooting

### ❗ **Common Issues**

**Permission Errors**
- Run PowerShell as Administrator
- Check Downloads folder permissions

**Execution Policy**
- Run: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

**Path Issues**
- Ensure Downloads folder exists at `%USERPROFILE%\Downloads`
- Check for special characters in filenames

**Notification Failures**
- Windows 10/11 required for toast notifications
- Fallback MessageBox should work on all systems

### 🔧 **Debug Information**
Check log files in script directory:
- `downloads-organizer-debug.log` - Processing details
- `downloads-organizer-errors.log` - Error messages

## 📋 Requirements

### 💻 **System Requirements**
- **OS**: Windows 10/11 (Windows 7+ supported with limited features)
- **PowerShell**: 5.1 or later
- **Permissions**: User access to Downloads folder
- **Disk Space**: Minimal (script organizes existing files)

### 🔧 **Optional Features**
- **Administrator**: Required for scheduled task creation
- **Internet**: Only needed for one-line download commands
- **Toast Notifications**: Windows 10/11 for modern notifications

## 🤝 Contributing

Feel free to contribute by:
- Adding new file type categories
- Improving detection patterns
- Enhancing performance
- Fixing bugs or issues

## 📄 License

This project is open source. Use and modify as needed.

---

**Created by**: [09sychic](https://github.com/09sychic)  
**Repository**: [xds3](https://github.com/09sychic/xds3)  
**Version**: Latest  
**Last Updated**: 2025
