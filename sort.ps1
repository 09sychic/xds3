# PowerShell Script: sort-downloads.ps1
# Purpose: ADVANCED Downloads organizer with filename processing, duplicate detection, and scheduling
# Author: Enhanced Auto-generated
# Usage: Right-click and "Run with PowerShell" or execute from PowerShell terminal
# Features: Smart categorization, filename sanitization, hash-based duplicate detection, auto-scheduling

# Define the base Downloads folder path
$downloadsPath = "$env:USERPROFILE\Downloads"

# Verify Downloads folder exists
if (-not (Test-Path $downloadsPath)) {
    exit
}

# Function to show Windows notification
function Show-Notification($title, $message) {
    try {
        # Create a Windows toast notification
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        [Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
        
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
    } catch {
        # Fallback to simple message box if toast fails
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show($message, $title, 'OK', 'Information')
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

# Files to skip (temporary and system files)
$skipExtensions = @("tmp", "crdownload", "part", "filepart", "download", "opdownload", "!qb", "bc!", "dlm")

# ADVANCED FEATURES CONFIGURATION
$maxFileNameLength = 100  # Maximum filename length before truncation
$enableDuplicateDetection = $true  # Enable hash-based duplicate detection
$enableFilenameProcessing = $true  # Enable filename sanitization and dating
$enableScheduling = $false  # Set to $true to create scheduled task

# Hash cache for duplicate detection (file hash -> file path)
$global:fileHashCache = @{}
$global:duplicatesFound = @()
$global:processedCount = 0

# Special pattern-based categorization functions
function Get-SeriesDestination($filename) {
    # Detect TV series patterns like S01E01, S1E1, Season 1, etc.
    if ($filename -match "S\d+E\d+|Season\s*\d+|Episode\s*\d+|s\d+e\d+") {
        return "Video\Series"
    }
    return $null
}

function Get-ScreenshotDestination($filename) {
    # Detect screenshot patterns
    $screenshotPatterns = @("screenshot", "screen shot", "snip", "capture", "screencap", "screenclip")
    foreach ($pattern in $screenshotPatterns) {
        if ($filename -match $pattern) {
            return "Images\Screenshots"
        }
    }
    return $null
}

function Get-SchoolDestination($filename) {
    # Detect school document patterns - PSET, problem set, homework
    $schoolPatterns = @("pset", "problem set", "homework", "assignment", "lab", "midterm", "final", "exam")
    foreach ($pattern in $schoolPatterns) {
        if ($filename -match $pattern) {
            return "Documents\School"
        }
    }
    return $null
}

function Get-EbookDestination($filename, $extension) {
    # Detect ebook patterns in PDFs
    if ($extension -eq "pdf") {
        $ebookPatterns = @("book", "ebook", "novel", "guide", "manual", "tutorial", "handbook")
        foreach ($pattern in $ebookPatterns) {
            if ($filename -match $pattern) {
                return "Documents\Ebooks"
            }
        }
    }
    return $null
}

function Get-BusinessDestination($filename, $extension) {
    # Detect business document patterns
    $reportPatterns = @("report", "analysis", "summary", "quarterly", "annual")
    $proposalPatterns = @("proposal", "quote", "estimate", "bid", "contract", "agreement")
    
    foreach ($pattern in $reportPatterns) {
        if ($filename -match $pattern) {
            return "Business\Reports"
        }
    }
    
    foreach ($pattern in $proposalPatterns) {
        if ($filename -match $pattern) {
            return "Business\Proposals"
        }
    }
    
    return $null
}

function Get-PodcastDestination($filename) {
    # Detect podcast patterns
    $podcastPatterns = @("podcast", "episode", "interview", "talk", "show", "cast")
    foreach ($pattern in $podcastPatterns) {
        if ($filename -match $pattern) {
            return "Audio\Podcasts"
        }
    }
    return $null
}

function Get-MemeDestination($filename) {
    # Detect meme patterns
    $memePatterns = @("meme", "funny", "lol", "lmao", "reaction", "gif", "comic")
    foreach ($pattern in $memePatterns) {
        if ($filename -match $pattern) {
            return "Images\Memes"
        }
    }
    return $null
}

# ADVANCED FILENAME PROCESSING FUNCTIONS

function Get-FileHash-Fast($filePath) {
    # Fast hash calculation for duplicate detection
    try {
        $hash = Get-FileHash -Path $filePath -Algorithm MD5
        return $hash.Hash
    } catch {
        return $null
    }
}

function Sanitize-Filename($filename, $extension, $destinationFolder, $creationDate) {
    if (-not $enableFilenameProcessing) { return $filename }
    
    # Remove extension for processing
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($filename)
    
    # 1. Remove special characters and replace spaces with underscores
    $cleanName = $baseName -replace '[<>:"/\\|?*]', '' -replace '\s+', '_'
    
    # 2. Add date suffix (MM-DD-YYYY format)
    $dateString = $creationDate.ToString("MMM-dd-yyyy").ToUpper()
    
    # 3. Add category prefix based on destination folder
    $categoryPrefix = ""
    if ($destinationFolder) {
        $parts = $destinationFolder.Split('\')
        if ($parts.Length -gt 1) {
            $categoryPrefix = $parts[1].ToUpper() + "_" 
        } else {
            $categoryPrefix = $parts[0].ToUpper() + "_"
        }
    }
    
    # 4. Construct new filename with prefix and suffix
    $newBaseName = $categoryPrefix + $cleanName + "_" + $dateString
    
    # 5. Truncate if too long (leave room for extension)
    $maxBaseLength = $maxFileNameLength - $extension.Length - 1
    if ($newBaseName.Length -gt $maxBaseLength) {
        $newBaseName = $newBaseName.Substring(0, $maxBaseLength)
        # Filename truncated silently
    }
    
    # 6. Return complete filename with extension
    return $newBaseName + "." + $extension
}

function Test-DuplicateFile($filePath, $fileHash) {
    if (-not $enableDuplicateDetection) { return $false }
    
    if ($global:fileHashCache.ContainsKey($fileHash)) {
        $existingFile = $global:fileHashCache[$fileHash]
        if (Test-Path $existingFile) {
            # Duplicate found silently
            $global:duplicatesFound += @{
                Original = $existingFile
                Duplicate = $filePath
                Hash = $fileHash
            }
            return $true
        }
    }
    
    # Add to cache
    $global:fileHashCache[$fileHash] = $filePath
    return $false
}

function Create-ScheduledTask() {
    if (-not $enableScheduling) { return }
    
    try {
        $scriptPath = $MyInvocation.ScriptName
        $taskName = "Auto-Downloads-Organizer"
        
        # Check if task already exists
        $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        if ($existingTask) {
            # Task already exists
            return
        }
        
        # Create daily trigger at 2 AM
        $trigger = New-ScheduledTaskTrigger -Daily -At "02:00"
        
        # Create action to run the script
        $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File `"$scriptPath`""
        
        # Create task settings
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        
        # Register the task
        Register-ScheduledTask -TaskName $taskName -Trigger $trigger -Action $action -Settings $settings -Description "Automatically organizes Downloads folder daily" -RunLevel Highest
        
        # Scheduled task created
        
    } catch {
        # Error creating scheduled task
    }
}

function Get-UniqueFileName($basePath, $fileName) {
    # ENHANCED: Overwrite duplicates instead of keeping both versions
    # This function now simply returns the original filename to enable overwriting
    return $fileName
}

# Build reverse lookup hash table (extension -> folder path)
$extensionToFolder = @{}
foreach ($folder in $folderStructure.Keys) {
    foreach ($extension in $folderStructure[$folder]) {
        $extensionToFolder[$extension.ToLower()] = $folder
    }
}

# Create scheduled task if enabled
Create-ScheduledTask

# Get all files recursively in Downloads folder and subfolders (excluding hidden/system files and folders)
$filesToProcess = Get-ChildItem -Path $downloadsPath -File -Recurse | Where-Object { 
    -not ($_.Attributes -band [System.IO.FileAttributes]::Hidden) -and
    -not ($_.Attributes -band [System.IO.FileAttributes]::System)
}

$movedCount = 0
$skippedCount = 0
$errorCount = 0
$duplicatesSkipped = 0
$filesRenamed = 0

# Processing configuration loaded silently

# Process each file with advanced pattern detection and duplicate handling
foreach ($file in $filesToProcess) {
    try {
        # Get file extension (without the dot) and filename for pattern matching
        $extension = $file.Extension.TrimStart('.').ToLower()
        $filenameForPattern = $file.BaseName.ToLower()
        
        # Skip temporary and system files
        if ($skipExtensions -contains $extension) {
            $skippedCount++
            continue
        }
        
        # Skip files without extensions
        if ([string]::IsNullOrEmpty($extension)) {
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
        
        # 2. Series detection (Videos) - Check for TV series patterns
        if (-not $destinationFolder) {
            $seriesDestination = Get-SeriesDestination $filenameForPattern
            if ($seriesDestination -and @("mp4", "mkv", "avi", "mov", "wmv", "mpg", "mpeg", "m4v", "rm", "rmvb", "asf", "f4v", "ogv") -contains $extension) {
                $destinationFolder = $seriesDestination
            }
        }
        
        # 3. School document detection - PSET, homework, assignments
        if (-not $destinationFolder) {
            $destinationFolder = Get-SchoolDestination $filenameForPattern
        }
        
        # 4. Ebook detection (PDFs)
        if (-not $destinationFolder) {
            $destinationFolder = Get-EbookDestination $filenameForPattern $extension
        }
        
        # 5. Business document detection
        if (-not $destinationFolder) {
            $destinationFolder = Get-BusinessDestination $filenameForPattern $extension
        }
        
        # 6. Podcast detection (Audio files)
        if (-not $destinationFolder) {
            $podcastDestination = Get-PodcastDestination $filenameForPattern
            if ($podcastDestination -and @("mp3", "flac", "wav", "aac", "ogg", "m4a", "wma", "opus", "ape", "mpc", "tta", "wv", "dsd", "dsf", "dff") -contains $extension) {
                $destinationFolder = $podcastDestination
            }
        }
        
        # 7. Meme detection (Image files)
        if (-not $destinationFolder) {
            $memeDestination = Get-MemeDestination $filenameForPattern
            if ($memeDestination -and @("jpg", "jpeg", "png", "gif", "bmp", "tif", "tiff", "webp", "heic", "avif", "jfif", "pjpeg", "pjp") -contains $extension) {
                $destinationFolder = $memeDestination
            }
        }
        
        # 8. Fall back to extension-based categorization
        if (-not $destinationFolder) {
            if ($extensionToFolder.ContainsKey($extension)) {
                $destinationFolder = $extensionToFolder[$extension]
            } else {
                $destinationFolder = "Misc"
            }
        }
        
        # Build full destination path
        $destinationPath = Join-Path $downloadsPath $destinationFolder
        
        # Check if file is already in the correct location
        if ($file.DirectoryName -eq $destinationPath) {
            $skippedCount++
            continue
        }
        
        # Create destination folder only if it doesn't exist (on-demand folder creation)
        if (-not (Test-Path $destinationPath)) {
            New-Item -Path $destinationPath -ItemType Directory -Force | Out-Null
        }
        
        # ADVANCED: Process filename with sanitization, dating, and truncation
        $originalFileName = $file.Name
        $processedFileName = Sanitize-Filename $file.Name $extension $destinationFolder $file.CreationTime
        
        if ($processedFileName -ne $originalFileName) {
            $filesRenamed++
        }
        
        # Handle duplicates by overwriting (no unique filename generation needed)
        $destinationFile = Join-Path $destinationPath $processedFileName
        
        # Move the file to destination (with overwrite and new processed name)
        Move-Item -Path $file.FullName -Destination $destinationFile -Force
        $movedCount++
        $global:processedCount++
        
    } catch {
        $errorCount++
    }
}

# Generate completion summary for notification
$summary = @"
Downloads Organization Complete!

Files processed:
• Moved: $movedCount files
• Renamed: $filesRenamed files
• Duplicates skipped: $duplicatesSkipped files
• Errors: $errorCount files
"@

# Category prefixes for better visualization
$categoryPrefixes = @{
    "Documents" = "[DOC]"
    "Images" = "[IMG]"
    "Audio" = "[AUD]"
    "Video" = "[VID]"
    "Archives" = "[ARC]"
    "Programs" = "[PRG]"
    "Code" = "[COD]"
    "Games" = "[GAM]"
    "Development" = "[DEV]"
    "3D" = "[3D]"
    "Scientific" = "[SCI]"
    "Business" = "[BIZ]"
    "MediaProduction" = "[MED]"
    "Legacy" = "[LEG]"
    "System" = "[SYS]"
    "Torrents" = "[TOR]"
    "Fonts" = "[FNT]"
    "Misc" = "[MSC]"
}

# Create organized view by category
$categorizedFolders = @{}
foreach ($folder in $folderStructure.Keys) {
    $parts = $folder.Split('\')
    $category = $parts[0]
    if (-not $categorizedFolders.ContainsKey($category)) {
        $categorizedFolders[$category] = @()
    }
    $categorizedFolders[$category] += $folder
}

# Add Misc to display
$categorizedFolders["Misc"] = @("Misc")

# Count organized files silently for notification

# Show completion notification
Show-Notification "Downloads Organizer" $summary