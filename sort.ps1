# PowerShell Script: sort-downloads.ps1
# Purpose: ADVANCED Downloads organizer with filename processing, duplicate detection, and scheduling
# Author: Enhanced Auto-generated with Error Handling
# Usage: Right-click and "Run with PowerShell" or execute from PowerShell terminal
# Features: Smart categorization, filename sanitization, hash-based duplicate detection, auto-scheduling

# Initialize logging
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$logFile = Join-Path $scriptPath "downloads-organizer-debug.log"
$errorLogFile = Join-Path $scriptPath "downloads-organizer-errors.log"

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [switch]$ToConsole = $true
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to log file
    try {
        Add-Content -Path $logFile -Value $logEntry -ErrorAction Stop
    } catch {
        Write-Warning "Failed to write to log file: $_"
    }
    
    # Write to console if requested
    if ($ToConsole) {
        switch ($Level) {
            "ERROR" { Write-Host $logEntry -ForegroundColor Red }
            "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
            "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
            "INFO" { Write-Host $logEntry -ForegroundColor White }
            default { Write-Host $logEntry -ForegroundColor Gray }
        }
    }
}

function Write-ErrorLog {
    param(
        [string]$ErrorMessage,
        [string]$Function = "",
        [string]$File = "",
        [System.Management.Automation.ErrorRecord]$ErrorRecord = $null
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $errorEntry = "[$timestamp] ERROR in $Function"
    if ($File) { $errorEntry += " (File: $File)" }
    $errorEntry += ": $ErrorMessage"
    
    if ($ErrorRecord) {
        $errorEntry += "`nException: $($ErrorRecord.Exception.Message)"
        $errorEntry += "`nStack Trace: $($ErrorRecord.ScriptStackTrace)"
    }
    
    try {
        Add-Content -Path $errorLogFile -Value $errorEntry -ErrorAction Stop
        Add-Content -Path $errorLogFile -Value "----------------------------------------" -ErrorAction Stop
    } catch {
        Write-Warning "Failed to write to error log file: $_"
    }
    
    Write-Log $ErrorMessage "ERROR"
}

# Initialize log files
try {
    "=== Downloads Organizer Debug Log - Started $(Get-Date) ===" | Out-File -FilePath $logFile -Force
    "=== Downloads Organizer Error Log - Started $(Get-Date) ===" | Out-File -FilePath $errorLogFile -Force
} catch {
    Write-Warning "Failed to initialize log files: $_"
}

Write-Log "========================================" "INFO"
Write-Log "  DOWNLOADS ORGANIZER STARTING...      " "INFO"
Write-Log "========================================" "INFO"

# Define the base Downloads folder path
$downloadsPath = "$env:USERPROFILE\Downloads"
Write-Log "Downloads path set to: $downloadsPath" "INFO"

# Verify Downloads folder exists
if (-not (Test-Path $downloadsPath)) {
    Write-ErrorLog "Downloads folder not found at $downloadsPath" "Main"
    exit 1
}

Write-Log "✓ Downloads folder found: $downloadsPath" "SUCCESS"

# Function to show Windows notification with proper error handling
function Show-Notification($title, $message) {
    try {
        Write-Log "Attempting to show notification: $title - $message" "INFO"
        
        # Try Windows 10/11 toast notification first
        if ([System.Environment]::OSVersion.Version.Major -ge 10) {
            try {
                Add-Type -AssemblyName System.Runtime.WindowsRuntime -ErrorAction Stop
                
                # Load required WinRT types
                $null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
                $null = [Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType = WindowsRuntime]
                $null = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]
                
                $template = @"
<toast>
    <visual>
        <binding template="ToastGeneric">
            <text>$title</text>
            <text>$message</text>
        </binding>
    </visual>
</toast>
"@
                
                $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
                $xml.LoadXml($template)
                $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
                $toast.Tag = "PowerShell"
                $toast.Group = "PowerShell"
                $toast.ExpirationTime = [DateTimeOffset]::Now.AddMinutes(5)
                
                $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("Downloads Organizer")
                $notifier.Show($toast)
                
                Write-Log "Toast notification sent successfully" "SUCCESS"
                return
            } catch {
                Write-ErrorLog "Toast notification failed: $($_.Exception.Message)" "Show-Notification" "" $_
            }
        }
        
        # Fallback to message box
        try {
            Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
            [System.Windows.Forms.MessageBox]::Show($message, $title, 'OK', 'Information') | Out-Null
            Write-Log "Message box notification sent successfully" "SUCCESS"
        } catch {
            Write-ErrorLog "Message box notification failed: $($_.Exception.Message)" "Show-Notification" "" $_
            Write-Log "All notification methods failed, continuing without notification" "WARNING"
        }
    } catch {
        Write-ErrorLog "Complete notification failure: $($_.Exception.Message)" "Show-Notification" "" $_
    }
}

# MASSIVE EXPANSION: Define comprehensive folder structure and file extension mappings
$folderStructure = @{
    # Documents category - Office files, PDFs, and text documents
    "Documents\Word"           = @("doc", "docx", "dot", "dotx", "docm", "dotm")
    "Documents\Excel"          = @("xls", "xlsx", "csv", "xlsm", "ods", "xlsb", "xltx", "xltm", "numbers")
    "Documents\PowerPoint"     = @("ppt", "pptx", "pps", "odp", "pptm", "ppsx", "ppsm", "potx", "key")
    "Documents\PDF"            = @("pdf")  # Basic PDFs (special handling for receipts/books below)
    "Documents\Text"           = @("txt", "rtf", "md", "tex", "readme", "changelog", "license")
    "Documents\Logs"           = @("log", "err", "out", "trace", "debug")
    "Documents\School"         = @()  # Special handling - files with PSET/problem set keywords
    "Documents\Ebooks"         = @("epub", "mobi", "azw3", "fb2", "lit", "azw", "prc", "lrf", "pdb", "cbr", "cbz")
    "Documents\Contracts"      = @()  # Special handling - PDFs with contract/agreement keywords
    "Documents\Manuals"        = @()  # Special handling - PDFs with manual/guide keywords
    
    # Images category - Photos, graphics, and design files
    "Images\Standard"          = @("jpg", "jpeg", "png", "gif", "bmp", "tif", "tiff", "webp", "heic", "avif", "jfif", "pjpeg", "pjp")
    "Images\Raw"              = @("arw", "raw", "rw2", "cr2", "nef", "orf", "raf", "dng", "sr2", "pef", "3fr", "ari", "bay", "crw", "dcr", "erf", "fff", "iiq", "k25", "kdc", "mef", "mos", "mrw", "nrw", "obm", "ptx", "r3d", "rwl", "rwz", "x3f")
    "Images\Vector"           = @("svg", "ai", "eps", "cdr", "wmf", "emf", "cgm", "sk", "sk1", "plt", "hpgl")
    "Images\Design"           = @("psd", "xd", "fig", "sketch", "indd", "idml", "qxd", "pub", "cpt", "cpp", "drw", "designer")
    "Images\Screenshots"      = @()  # Special handling - files with screenshot keywords
    "Images\Icons"            = @("ico", "icns", "cur", "ani")
    "Images\Memes"            = @()  # Special handling - files with meme keywords
    
    # Audio category - Music, podcasts, and audio projects
    "Audio\Music"             = @("mp3", "flac", "wav", "aac", "ogg", "m4a", "wma", "opus", "ape", "mpc", "tta", "wv", "dsd", "dsf", "dff")
    "Audio\Podcasts"          = @()  # Special handling - files with podcast keywords or in podcast folders
    "Audio\Audiobooks"        = @("m4b", "aa", "aax")
    "Audio\Project"           = @("als", "flp", "cpr", "npr", "mscz", "ptx", "logic", "band", "reason", "cmf", "drm", "ens", "sib", "musx", "omg")
    "Audio\Samples"           = @("rex", "rx2", "sf2", "sfz", "gig", "nki", "exs24", "nnp", "fxp", "h2drumkit")
    
    # Video category - Movies, series, clips, and subtitles
    "Video\Movies"            = @("mp4", "mkv", "avi", "mov", "wmv", "mpg", "mpeg", "m4v", "rm", "rmvb", "asf", "f4v", "ogv")
    "Video\Series"            = @()  # Special handling - videos with series patterns (S01E01, etc.)
    "Video\Clips"             = @("webm", "flv", "3gp", "ts", "vob", "mts", "m2ts", "tod", "mod")
    "Video\Subtitles"         = @("srt", "ass", "vtt", "sub", "idx", "ssa", "usf", "xml", "ttml", "sbv")
    "Video\Project"           = @("prproj", "aep", "fcp", "fcpx", "avs", "kdenlive", "blend", "wlmp", "mswmm", "veg", "xges")
    
    # Archives category - All compression and container formats
    "Archives\Standard"       = @("zip", "rar", "7z", "tar", "gz", "bz2", "xz", "lz", "lzma", "z")
    "Archives\Disk"           = @("iso", "img", "bin", "cue", "nrg", "mds", "ccd", "daa", "udf")
    "Archives\Cabinet"        = @("cab", "msi", "msp", "wim", "esd")
    "Archives\Packages"       = @("deb", "rpm", "pkg", "xar", "tgz", "txz", "tbz2")
    
    # Programs category - Executables, installers, and system files
    "Programs\Windows"        = @("exe", "msi", "bat", "cmd", "ps1", "vbs", "wsf", "scr", "pif", "com")
    "Programs\Mac"            = @("dmg", "pkg", "app", "mpkg", "bundle")
    "Programs\Linux"          = @("deb", "rpm", "appimage", "snap", "flatpak", "run", "bin")
    "Programs\Mobile"         = @("apk", "ipa", "xap", "appx", "msix")
    "Programs\Registry"       = @("reg", "inf", "cat", "sys", "drv")
    "Programs\Scripts"        = @("ahk", "au3", "nsi", "iss", "sh", "bash", "zsh", "fish", "csh")
    
    # Code category - Programming files and development resources
    "Code\Web"                = @("html", "htm", "css", "scss", "sass", "less", "js", "ts", "jsx", "tsx", "vue", "php", "asp", "aspx", "jsp", "erb", "handlebars", "mustache")
    "Code\Languages"          = @("py", "java", "cs", "cpp", "c", "h", "hpp", "cc", "cxx", "go", "rs", "kt", "rb", "swift", "scala", "lua", "pl", "r", "m", "mm", "f", "f90", "f95", "pas", "pp", "ada", "vb", "bas")
    "Code\Data"               = @("json", "xml", "yaml", "yml", "toml", "ini", "cfg", "conf", "properties", "plist", "reg")
    "Code\Database"           = @("sql", "db", "sqlite", "sqlite3", "mdb", "accdb", "dbf", "frm", "myd", "myi")
    "Code\Config"             = @("dockerfile", "vagrantfile", "makefile", "rakefile", "gulpfile", "webpack", "package", "composer", "requirements", "gemfile", "podfile")
    "Code\Notebooks"          = @("ipynb", "rmd", "qmd", "nb", "mathematica")
    
    # Games category - Game files, ROMs, and saves
    "Games\ROMs"              = @("rom", "nes", "smc", "sfc", "gb", "gbc", "gba", "nds", "3ds", "n64", "z64", "v64", "iso", "cso", "pbp", "wbfs", "gcm")
    "Games\Saves"             = @("sav", "save", "dat", "srm", "st", "ss", "savestate", "state", "mcr", "gme", "vmc", "ps2", "xps")
    "Games\Mods"              = @("pak", "wad", "pk3", "vpk", "bsp", "map", "sk3", "unitypackage")
    "Games\Steam"             = @("acf", "blob", "manifest", "vdf")
    
    # Development category - IDEs, frameworks, and build files
    "Development\Projects"    = @("sln", "csproj", "vbproj", "vcxproj", "xcodeproj", "xcworkspace", "pbxproj", "gradle", "pom", "build", "ant")
    "Development\Libraries"   = @("dll", "so", "dylib", "lib", "a", "jar", "war", "ear", "aar", "framework")
    "Development\Certificates"= @("crt", "cer", "pem", "p12", "pfx", "key", "pub", "csr", "jks", "keystore")
    
    # 3D category - 3D models, animations, and CAD files
    "3D\Models"               = @("obj", "fbx", "dae", "3ds", "max", "blend", "ma", "mb", "c4d", "lwo", "lws", "x3d", "ply", "stl")
    "3D\CAD"                  = @("dwg", "dxf", "step", "stp", "iges", "igs", "sat", "parasolid", "catpart", "catproduct", "prt", "asm")
    "3D\Textures"             = @("exr", "hdr", "tga", "dds", "ktx", "basis")
    
    # Scientific category - Research, data, and academic files
    "Scientific\Data"         = @("csv", "tsv", "dat", "h5", "hdf5", "nc", "cdf", "fits", "mat", "sav", "dta", "por")
    "Scientific\References"   = @("bib", "ris", "enw", "ref", "nbib")
    "Scientific\Presentations"= @()  # Special handling - academic presentation files
    
    # Business category - Office templates, presentations, and reports
    "Business\Templates"      = @("dot", "dotx", "potx", "xltx", "oft", "odt", "ott", "ots", "otp")
    "Business\Reports"        = @()  # Special handling - files with report keywords
    "Business\Proposals"      = @()  # Special handling - files with proposal keywords
    
    # Media Production category - Professional media files
    "MediaProduction\RAW"     = @("r3d", "braw", "mxf", "mov", "prores", "dnxhd", "avchd")
    "MediaProduction\Audio"   = @("aiff", "bwf", "rf64", "w64", "caf", "sd2")
    "MediaProduction\Presets" = @("fcp", "mogrt", "aep", "prproj", "veg", "pro")
    
    # Legacy category - Old file formats and vintage files
    "Legacy\Documents"        = @("wpd", "wps", "works", "cwk", "pages", "key", "numbers")
    "Legacy\Images"           = @("pcx", "tga", "xbm", "xpm", "ppm", "pgm", "pbm", "pnm")
    "Legacy\Archives"         = @("sit", "sea", "hqx", "arc", "zoo", "lzh", "arj", "ace")
    
    # System category - System files and temporary data
    "System\Logs"             = @("log", "trace", "crash", "dump", "dmp", "evtx", "etl")
    "System\Cache"            = @("cache", "tmp", "temp", "thumbs", "ds_store")
    "System\Backups"          = @("bak", "backup", "old", "orig", "~")
    
    # Torrents category
    "Torrents"                = @("torrent", "magnet")
    
    # Fonts category - All font formats
    "Fonts\TrueType"          = @("ttf", "ttc")
    "Fonts\OpenType"          = @("otf", "otc")
    "Fonts\Web"               = @("woff", "woff2", "eot")
    "Fonts\Legacy"            = @("fon", "fnt", "bdf", "pcf", "snf", "pfa", "pfb", "afm", "pfm")
}

Write-Log "✓ Configuration loaded: $($folderStructure.Count) categories defined" "SUCCESS"

# Files to skip (temporary and system files)
$skipExtensions = @("tmp", "crdownload", "part", "filepart", "download", "opdownload", "!qb", "bc!", "dlm")

# ADVANCED FEATURES CONFIGURATION
$maxFileNameLength = 100  # Maximum filename length before truncation
$enableDuplicateDetection = $true  # Enable hash-based duplicate detection
$enableFilenameProcessing = $true  # Enable filename sanitization and dating
$enableScheduling = $false  # Set to $true to create scheduled task

Write-Log "✓ Features enabled: Duplicate detection=$enableDuplicateDetection, Filename processing=$enableFilenameProcessing" "SUCCESS"

# Hash cache for duplicate detection (file hash -> file path)
$global:fileHashCache = @{}
$global:duplicatesFound = @()
$global:processedCount = 0

# Special pattern-based categorization functions
function Get-SeriesDestination($filename) {
    try {
        # Detect TV series patterns like S01E01, S1E1, Season 1, etc.
        if ($filename -match "S\d+E\d+|Season\s*\d+|Episode\s*\d+|s\d+e\d+") {
            Write-Log "Series pattern detected in: $filename" "INFO"
            return "Video\Series"
        }
        return $null
    } catch {
        Write-ErrorLog "Error in Get-SeriesDestination: $($_.Exception.Message)" "Get-SeriesDestination" $filename $_
        return $null
    }
}

function Get-ScreenshotDestination($filename) {
    try {
        # Detect screenshot patterns
        $screenshotPatterns = @("screenshot", "screen shot", "snip", "capture", "screencap", "screenclip")
        foreach ($pattern in $screenshotPatterns) {
            if ($filename -match $pattern) {
                Write-Log "Screenshot pattern '$pattern' detected in: $filename" "INFO"
                return "Images\Screenshots"
            }
        }
        return $null
    } catch {
        Write-ErrorLog "Error in Get-ScreenshotDestination: $($_.Exception.Message)" "Get-ScreenshotDestination" $filename $_
        return $null
    }
}

function Get-SchoolDestination($filename) {
    try {
        # Detect school document patterns - PSET, problem set, homework
        $schoolPatterns = @("pset", "problem set", "homework", "assignment", "lab", "midterm", "final", "exam")
        foreach ($pattern in $schoolPatterns) {
            if ($filename -match $pattern) {
                Write-Log "School pattern '$pattern' detected in: $filename" "INFO"
                return "Documents\School"
            }
        }
        return $null
    } catch {
        Write-ErrorLog "Error in Get-SchoolDestination: $($_.Exception.Message)" "Get-SchoolDestination" $filename $_
        return $null
    }
}

function Get-EbookDestination($filename, $extension) {
    try {
        # Detect ebook patterns in PDFs
        if ($extension -eq "pdf") {
            $ebookPatterns = @("book", "ebook", "novel", "guide", "manual", "tutorial", "handbook")
            foreach ($pattern in $ebookPatterns) {
                if ($filename -match $pattern) {
                    Write-Log "Ebook pattern '$pattern' detected in: $filename" "INFO"
                    return "Documents\Ebooks"
                }
            }
        }
        return $null
    } catch {
        Write-ErrorLog "Error in Get-EbookDestination: $($_.Exception.Message)" "Get-EbookDestination" $filename $_
        return $null
    }
}

function Get-BusinessDestination($filename, $extension) {
    try {
        # Detect business document patterns
        $reportPatterns = @("report", "analysis", "summary", "quarterly", "annual")
        $proposalPatterns = @("proposal", "quote", "estimate", "bid", "contract", "agreement")
        
        foreach ($pattern in $reportPatterns) {
            if ($filename -match $pattern) {
                Write-Log "Report pattern '$pattern' detected in: $filename" "INFO"
                return "Business\Reports"
            }
        }
        
        foreach ($pattern in $proposalPatterns) {
            if ($filename -match $pattern) {
                Write-Log "Proposal pattern '$pattern' detected in: $filename" "INFO"
                return "Business\Proposals"
            }
        }
        
        return $null
    } catch {
        Write-ErrorLog "Error in Get-BusinessDestination: $($_.Exception.Message)" "Get-BusinessDestination" $filename $_
        return $null
    }
}

function Get-PodcastDestination($filename) {
    try {
        # Detect podcast patterns
        $podcastPatterns = @("podcast", "episode", "interview", "talk", "show", "cast")
        foreach ($pattern in $podcastPatterns) {
            if ($filename -match $pattern) {
                Write-Log "Podcast pattern '$pattern' detected in: $filename" "INFO"
                return "Audio\Podcasts"
            }
        }
        return $null
    } catch {
        Write-ErrorLog "Error in Get-PodcastDestination: $($_.Exception.Message)" "Get-PodcastDestination" $filename $_
        return $null
    }
}

function Get-MemeDestination($filename) {
    try {
        # Detect meme patterns
        $memePatterns = @("meme", "funny", "lol", "lmao", "reaction", "gif", "comic")
        foreach ($pattern in $memePatterns) {
            if ($filename -match $pattern) {
                Write-Log "Meme pattern '$pattern' detected in: $filename" "INFO"
                return "Images\Memes"
            }
        }
        return $null
    } catch {
        Write-ErrorLog "Error in Get-MemeDestination: $($_.Exception.Message)" "Get-MemeDestination" $filename $_
        return $null
    }
}

# ADVANCED FILENAME PROCESSING FUNCTIONS

function Get-FileHash-Fast($filePath) {
    # Fast hash calculation for duplicate detection
    try {
        if (-not (Test-Path $filePath)) {
            Write-Log "File not found for hashing: $filePath" "WARNING"
            return $null
        }
        
        # Check if file is locked
        try {
            $fileStream = [System.IO.File]::Open($filePath, 'Open', 'Read', 'ReadWrite')
            $fileStream.Close()
        } catch {
            Write-Log "File is locked or inaccessible for hashing: $filePath" "WARNING"
            return $null
        }
        
        $hash = Get-FileHash -Path $filePath -Algorithm MD5 -ErrorAction Stop
        Write-Log "Hash calculated for: $filePath" "INFO"
        return $hash.Hash
    } catch {
        Write-ErrorLog "Failed to calculate hash for: $filePath - $($_.Exception.Message)" "Get-FileHash-Fast" $filePath $_
        return $null
    }
}

function Sanitize-Filename($filename, $extension, $destinationFolder, $creationDate) {
    try {
        if (-not $enableFilenameProcessing) { 
            Write-Log "Filename processing disabled, returning original: $filename" "INFO"
            return $filename 
        }
        
        # Remove extension for processing
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($filename)
        Write-Log "Processing filename: $baseName" "INFO"
        
        # 1. Remove special characters and replace spaces with underscores
        $cleanName = $baseName -replace '[<>:"/\\|?*]', '' -replace '\s+', '_'
        
        # 2. Add date suffix (MM-DD-YYYY format)
        $dateString = $creationDate.ToString("MMM-dd-yyyy").ToUpper()
        
        # 3. Construct new filename with suffix
        $newBaseName = $cleanName + "_" + $dateString
        
        # 4. Truncate if too long (leave room for extension)
        $maxBaseLength = $maxFileNameLength - $extension.Length - 1
        if ($newBaseName.Length -gt $maxBaseLength) {
            $newBaseName = $newBaseName.Substring(0, $maxBaseLength)
            Write-Log "Filename truncated to $($newBaseName.Length) characters" "WARNING"
        }
        
        # 5. Return complete filename with extension
        $finalName = $newBaseName + "." + $extension
        Write-Log "Filename processed: $filename -> $finalName" "INFO"
        return $finalName
    } catch {
        Write-ErrorLog "Error sanitizing filename: $filename - $($_.Exception.Message)" "Sanitize-Filename" $filename $_
        return $filename  # Return original filename on error
    }
}

function Test-DuplicateFile($filePath, $fileHash) {
    try {
        if (-not $enableDuplicateDetection) { 
            Write-Log "Duplicate detection disabled" "INFO"
            return $false 
        }
        
        if (-not $fileHash) {
            Write-Log "No hash provided for duplicate check" "INFO"
            return $false
        }
        
        if ($global:fileHashCache.ContainsKey($fileHash)) {
            $existingFile = $global:fileHashCache[$fileHash]
            if (Test-Path $existingFile) {
                Write-Log "Duplicate found: $filePath matches $existingFile" "WARNING"
                $global:duplicatesFound += @{
                    Original = $existingFile
                    Duplicate = $filePath
                    Hash = $fileHash
                }
                return $true
            } else {
                Write-Log "Cached file no longer exists, removing from cache: $existingFile" "INFO"
                $global:fileHashCache.Remove($fileHash)
            }
        }
        
        # Add to cache
        $global:fileHashCache[$fileHash] = $filePath
        Write-Log "File added to hash cache: $filePath" "INFO"
        return $false
    } catch {
        Write-ErrorLog "Error checking for duplicates: $($_.Exception.Message)" "Test-DuplicateFile" $filePath $_
        return $false
    }
}

function Create-ScheduledTask() {
    if (-not $enableScheduling) { 
        Write-Log "Scheduled task creation disabled" "INFO"
        return 
    }
    
    try {
        $scriptPath = $PSCommandPath
        if (-not $scriptPath) {
            Write-Log "Unable to determine script path for scheduled task" "WARNING"
            return
        }
        
        $taskName = "Auto-Downloads-Organizer"
        Write-Log "Creating scheduled task: $taskName" "INFO"
        
        # Check if task already exists
        $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        if ($existingTask) {
            Write-Log "✓ Scheduled task already exists" "SUCCESS"
            return
        }
        
        # Create daily trigger at 2 AM
        $trigger = New-ScheduledTaskTrigger -Daily -At "02:00" -ErrorAction Stop
        
        # Create action to run the script
        $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File `"$scriptPath`"" -ErrorAction Stop
        
        # Create task settings
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ErrorAction Stop
        
        # Register the task
        Register-ScheduledTask -TaskName $taskName -Trigger $trigger -Action $action -Settings $settings -Description "Automatically organizes Downloads folder daily" -RunLevel Highest -ErrorAction Stop
        
        Write-Log "✓ Scheduled task created successfully" "SUCCESS"
        
    } catch {
        Write-ErrorLog "Error creating scheduled task: $($_.Exception.Message)" "Create-ScheduledTask" "" $_
    }
}

function Get-UniqueFileName($basePath, $fileName) {
    try {
        # ENHANCED: Overwrite duplicates instead of keeping both versions
        # This function now simply returns the original filename to enable overwriting
        Write-Log "Using filename (overwrite mode): $fileName" "INFO"
        return $fileName
    } catch {
        Write-ErrorLog "Error in Get-UniqueFileName: $($_.Exception.Message)" "Get-UniqueFileName" $fileName $_
        return $fileName
    }
}

# Build reverse lookup hash table (extension -> folder path)
Write-Log "⚙ Building extension lookup table..." "INFO"
$extensionToFolder = @{}
try {
    foreach ($folder in $folderStructure.Keys) {
        foreach ($extension in $folderStructure[$folder]) {
            if ($extensionToFolder.ContainsKey($extension.ToLower())) {
                Write-Log "Warning: Extension '$extension' mapped to multiple folders" "WARNING"
            }
            $extensionToFolder[$extension.ToLower()] = $folder
        }
    }
    Write-Log "✓ Extension lookup table built: $($extensionToFolder.Count) extensions mapped" "SUCCESS"
} catch {
    Write-ErrorLog "Error building extension lookup table: $($_.Exception.Message)" "Main" "" $_
    exit 1
}

# Create scheduled task if enabled
if ($enableScheduling) {
    Write-Log "⚙ Setting up scheduled task..." "INFO"
    Create-ScheduledTask
}

# Get all files recursively in Downloads folder and subfolders (excluding hidden/system files and folders)
Write-Log "`n⚙ Scanning Downloads folder for files..." "INFO"
try {
    $filesToProcess = Get-ChildItem -Path $downloadsPath -File -Recurse -ErrorAction Stop | Where-Object { 
        -not ($_.Attributes -band [System.IO.FileAttributes]::Hidden) -and
        -not ($_.Attributes -band [System.IO.FileAttributes]::System)
    }
    
    $totalFiles = $filesToProcess.Count
    Write-Log "✓ Found $totalFiles files to process" "SUCCESS"
} catch {
    Write-ErrorLog "Error scanning Downloads folder: $($_.Exception.Message)" "Main" "" $_
    exit 1
}

if ($totalFiles -eq 0) {
    Write-Log "`n🎉 No files to organize! Downloads folder is already clean." "SUCCESS"
    exit 0
}

$movedCount = 0
$skippedCount = 0
$errorCount = 0
$duplicatesSkipped = 0
$filesRenamed = 0

Write-Log "`n========================================" "INFO"
Write-Log "  PROCESSING FILES...                   " "INFO"
Write-Log "========================================" "INFO"

# Process each file with advanced pattern detection and duplicate handling
$currentFile = 0
foreach ($file in $filesToProcess) {
    try {
        $currentFile++
        $percentComplete = [math]::Round(($currentFile / $totalFiles) * 100, 1)
        
        # Get file extension (without the dot) and filename for pattern matching
        $extension = $file.Extension.TrimStart('.').ToLower()
        $filenameForPattern = $file.BaseName.ToLower()
        
        Write-Log "[$percentComplete%] Processing: $($file.Name)" "INFO"
        
        # Validate file still exists
        if (-not (Test-Path $file.FullName)) {
            Write-Log "File no longer exists, skipping: $($file.FullName)" "WARNING"
            $skippedCount++
            continue
        }
        
        # Skip temporary and system files
        if ($extension -in $skipExtensions) {
            Write-Log "⏭ Skipped: Temporary file ($extension)" "INFO"
            $skippedCount++
            continue
        }
        
        # Skip files without extensions
        if ([string]::IsNullOrEmpty($extension)) {
            Write-Log "⏭ Skipped: No extension" "INFO"
            $skippedCount++
            continue
        }
        
        # ADVANCED: Calculate file hash for duplicate detection
        $fileHash = $null
        if ($enableDuplicateDetection) {
            $fileHash = Get-FileHash-Fast $file.FullName
            if ($fileHash -and (Test-DuplicateFile $file.FullName $fileHash)) {
                $duplicatesSkipped++
                continue
            }
        }
        
        # SMART PATTERN DETECTION - Check special cases first (order matters!)
        $destinationFolder = $null
        
        # 1. Screenshots (Images) - Check filename patterns
        $destinationFolder = Get-ScreenshotDestination $filenameForPattern
        if ($destinationFolder) {
            Write-Log "📸 Detected: Screenshot" "INFO"
        }
        
        # 2. Series detection (Videos) - Check for TV series patterns
        if (-not $destinationFolder) {
            $seriesDestination = Get-SeriesDestination $filenameForPattern
            if ($seriesDestination -and $extension -in @("mp4", "mkv", "avi", "mov", "wmv", "mpg", "mpeg", "m4v", "rm", "rmvb", "asf", "f4v", "ogv")) {
                $destinationFolder = $seriesDestination
                Write-Log "📺 Detected: TV Series" "INFO"
            }
        }
        
        # 3. School document detection - PSET, homework, assignments
        if (-not $destinationFolder) {
            $destinationFolder = Get-SchoolDestination $filenameForPattern
            if ($destinationFolder) {
                Write-Log "🎓 Detected: School Document" "INFO"
            }
        }
        
        # 4. Ebook detection (PDFs)
        if (-not $destinationFolder) {
            $destinationFolder = Get-EbookDestination $filenameForPattern $extension
            if ($destinationFolder) {
                Write-Log "📚 Detected: Ebook" "INFO"
            }
        }
        
        # 5. Business document detection
        if (-not $destinationFolder) {
            $destinationFolder = Get-BusinessDestination $filenameForPattern $extension
            if ($destinationFolder) {
                Write-Log "💼 Detected: Business Document" "INFO"
            }
        }
        
        # 6. Podcast detection (Audio files)
        if (-not $destinationFolder) {
            $podcastDestination = Get-PodcastDestination $filenameForPattern
            if ($podcastDestination -and $extension -in @("mp3", "flac", "wav", "aac", "ogg", "m4a", "wma", "opus", "ape", "mpc", "tta", "wv", "dsd", "dsf", "dff")) {
                $destinationFolder = $podcastDestination
                Write-Log "🎙 Detected: Podcast" "INFO"
            }
        }
        
        # 7. Meme detection (Image files)
        if (-not $destinationFolder) {
            $memeDestination = Get-MemeDestination $filenameForPattern
            if ($memeDestination -and $extension -in @("jpg", "jpeg", "png", "gif", "bmp", "tif", "tiff", "webp", "heic", "avif", "jfif", "pjpeg", "pjp")) {
                $destinationFolder = $memeDestination
                Write-Log "😂 Detected: Meme" "INFO"
            }
        }
        
        # 8. Fall back to extension-based categorization
        if (-not $destinationFolder) {
            if ($extensionToFolder.ContainsKey($extension)) {
                $destinationFolder = $extensionToFolder[$extension]
                Write-Log "📁 Categorized by extension: .$extension -> $destinationFolder" "INFO"
            } else {
                $destinationFolder = "Misc"
                Write-Log "❓ Moved to Misc: Unknown type (.$extension)" "INFO"
            }
        }
        
        # Build full destination path
        $destinationPath = Join-Path $downloadsPath $destinationFolder
        
        # Check if file is already in the correct location
        if ($file.DirectoryName -eq $destinationPath) {
            Write-Log "✓ Already in correct location: $destinationFolder" "SUCCESS"
            $skippedCount++
            continue
        }
        
        # Create destination folder only if it doesn't exist (on-demand folder creation)
        if (-not (Test-Path $destinationPath)) {
            try {
                New-Item -Path $destinationPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
                Write-Log "📂 Created folder: $destinationFolder" "SUCCESS"
            } catch {
                Write-ErrorLog "Failed to create destination folder: $destinationPath - $($_.Exception.Message)" "Main" $file.FullName $_
                $errorCount++
                continue
            }
        }
        
        # ADVANCED: Process filename with sanitization, dating, and truncation
        $originalFileName = $file.Name
        $processedFileName = Sanitize-Filename $file.Name $extension $destinationFolder $file.CreationTime
        
        if ($processedFileName -ne $originalFileName) {
            Write-Log "✏ Renamed: $originalFileName -> $processedFileName" "INFO"
            $filesRenamed++
        }
        
        # Handle duplicates by overwriting (no unique filename generation needed)
        $destinationFile = Join-Path $destinationPath $processedFileName
        
        # Validate source file still exists before moving
        if (-not (Test-Path $file.FullName)) {
            Write-Log "Source file no longer exists: $($file.FullName)" "WARNING"
            $errorCount++
            continue
        }
        
        # Check if destination file exists and if source and destination are the same
        if ((Test-Path $destinationFile) -and ((Get-Item $file.FullName).FullName -eq (Get-Item $destinationFile).FullName)) {
            Write-Log "Source and destination are the same file, skipping: $($file.FullName)" "WARNING"
            $skippedCount++
            continue
        }
        
        # Move the file to destination (with overwrite and new processed name)
        try {
            Move-Item -Path $file.FullName -Destination $destinationFile -Force -ErrorAction Stop
            Write-Log "➡ Successfully moved to: $destinationFolder" "SUCCESS"
            $movedCount++
            $global:processedCount++
        } catch {
            Write-ErrorLog "Failed to move file: $($file.FullName) -> $destinationFile - $($_.Exception.Message)" "Main" $file.FullName $_
            $errorCount++
        }
        
    } catch {
        Write-ErrorLog "Unexpected error processing file: $($file.FullName) - $($_.Exception.Message)" "Main" $file.FullName $_
        $errorCount++
    }
}

Write-Log "`n========================================" "INFO"
Write-Log "  ORGANIZATION COMPLETE!                " "INFO"
Write-Log "========================================" "INFO"

# Generate completion summary for notification and console
$summary = @"
Files processed: $totalFiles
• ✅ Moved: $movedCount files
• ✏ Renamed: $filesRenamed files  
• ⚠ Duplicates skipped: $duplicatesSkipped files
• ⏭ Other skipped: $skippedCount files
• ❌ Errors: $errorCount files
"@

Write-Log $summary "INFO"

# Show completion status
if ($movedCount -gt 0) {
    Write-Log "`n🎉 SUCCESS: Downloads folder has been organized!" "SUCCESS"
} else {
    Write-Log "`n✨ INFO: No files needed to be moved." "INFO"
}

if ($duplicatesSkipped -gt 0) {
    Write-Log "💡 TIP: $duplicatesSkipped duplicate files were found and skipped." "WARNING"
}

if ($errorCount -gt 0) {
    Write-Log "⚠ WARNING: $errorCount files had errors during processing." "WARNING"
}

# Category breakdown
Write-Log "`n📊 CATEGORY BREAKDOWN:" "INFO"
try {
    $categoryStats = @{}
    Get-ChildItem -Path $downloadsPath -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            $fileCount = (Get-ChildItem -Path $_.FullName -File -Recurse -ErrorAction SilentlyContinue).Count
            if ($fileCount -gt 0) {
                $categoryStats[$_.Name] = $fileCount
                Write-Log "   $($_.Name): $fileCount files" "INFO"
            }
        } catch {
            Write-ErrorLog "Error counting files in category: $($_.Name) - $($_.Exception.Message)" "Main" "" $_
        }
    }
} catch {
    Write-ErrorLog "Error generating category breakdown: $($_.Exception.Message)" "Main" "" $_
}

Write-Log "`n✨ Organization complete! Press any key to exit..." "SUCCESS"
Write-Log "Debug logs saved to: $logFile" "INFO"
Write-Log "Error logs saved to: $errorLogFile" "INFO"

# Show notification
try {
    Show-Notification "Downloads Organizer" $summary
} catch {
    Write-ErrorLog "Failed to show final notification: $($_.Exception.Message)" "Main" "" $_
}

# Finalize logs
try {
    "=== Downloads Organizer Completed $(Get-Date) ===" | Add-Content -Path $logFile
    "=== Downloads Organizer Completed $(Get-Date) ===" | Add-Content -Path $errorLogFile
} catch {
    Write-Warning "Failed to finalize log files: $_"
}

# Wait for user input before closing
Read-Host

exit 0
