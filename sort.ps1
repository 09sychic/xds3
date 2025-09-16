# PowerShell Script: sort-downloads.ps1 (fixed quoting/braces + reliable logging)
# Purpose: Downloads organizer with filename processing, duplicate detection, and scheduling

# ------------------- Logging setup (same directory as script) -------------------
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $scriptDir) { $scriptDir = (Get-Location).Path }  # Fallback for rare hosts

$debugLogPath = Join-Path $scriptDir "downloads-organizer-debug.log"
$errorLogPath = Join-Path $scriptDir "downloads-organizer-errors.log"

# Initialize log files
$now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"=== Downloads Organizer Debug Log - Started $now ===" | Out-File -FilePath $debugLogPath -Encoding UTF8
"=== Downloads Organizer Error Log - Started $now ===" | Out-File -FilePath $errorLogPath -Encoding UTF8

function Write-DebugLog {
    param([string]$Message)
    $entry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') DEBUG: $Message"
    $entry | Out-File -FilePath $debugLogPath -Append -Encoding UTF8
    Write-Host $Message
}
function Write-ErrorLog {
    param([string]$Message, $Err = $null)
    $entry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ERROR: $Message"
    if ($Err) {
        $entry += "`nException: $($Err.Exception.Message)"
        if ($Err.ScriptStackTrace) { $entry += "`nStackTrace: $($Err.ScriptStackTrace)" }
    }
    $entry | Out-File -FilePath $errorLogPath -Append -Encoding UTF8
    Write-Host "ERROR: $Message" -ForegroundColor Red
}

Write-DebugLog "========================================"
Write-DebugLog "DOWNLOADS ORGANIZER STARTING..."
Write-DebugLog "========================================"

# ------------------- Config -------------------
$downloadsPath = "$env:USERPROFILE\Downloads"
if (-not (Test-Path $downloadsPath)) {
    Write-ErrorLog "Downloads folder not found at $downloadsPath"
    exit 1
}
Write-DebugLog "Downloads path: $downloadsPath"

# Windows notification (safe quoting; fallbacks; completely contained try/catch)
function Show-Notification {
    param([string]$Title, [string]$Message)
    try {
        Write-DebugLog "Attempting toast notification"
        # Check if Windows.Runtime is available first
        if ([System.Environment]::OSVersion.Version -ge [Version]"10.0") {
            Add-Type -AssemblyName Windows.Runtime -ErrorAction Stop
            [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
            # ... rest of toast code ...
        } else {
            throw "Windows 10+ required for toast notifications"
        }
    } catch {
        Write-ErrorLog "Toast notification failed; using MessageBox fallback" $_
        try {
            Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
            [System.Windows.Forms.MessageBox]::Show($Message, $Title, 'OK', 'Information') | Out-Null
            Write-DebugLog "MessageBox fallback shown"
        } catch {
            Write-ErrorLog "MessageBox failed; using console output" $_
            Write-Host "=== $Title ===" -ForegroundColor Green
            Write-Host $Message -ForegroundColor Cyan
        }
    }
}
# Categories map (same as before; trimmed comments)
$folderStructure = @{
    "Documents\Word" = @("doc","docx","dot","dotx","docm","dotm")
    "Documents\Excel" = @("xls","xlsx","csv","xlsm","ods","xlsb","xltx","xltm","numbers")
    "Documents\PowerPoint" = @("ppt","pptx","pps","odp","pptm","ppsx","ppsm","potx","key")
    "Documents\PDF" = @("pdf")
    "Documents\Text" = @("txt","rtf","md","tex","readme","changelog","license")
    "Documents\Logs" = @("log","err","out","trace","debug")
    "Documents\School" = @()
    "Documents\Ebooks" = @("epub","mobi","azw3","fb2","lit","azw","prc","lrf","pdb","cbr","cbz")
    "Documents\Contracts" = @()
    "Documents\Manuals" = @()
    "Images\Standard" = @("jpg","jpeg","png","gif","bmp","tif","tiff","webp","heic","avif","jfif","pjpeg","pjp")
    "Images\Raw" = @("arw","raw","rw2","cr2","nef","orf","raf","dng","sr2","pef","3fr","ari","bay","crw","dcr","erf","fff","iiq","k25","kdc","mef","mos","mrw","nrw","obm","ptx","r3d","rwl","rwz","x3f")
    "Images\Vector" = @("svg","ai","eps","cdr","wmf","emf","cgm","sk","sk1","plt","hpgl")
    "Images\Design" = @("psd","xd","fig","sketch","indd","idml","qxd","pub","cpt","cpp","drw","designer")
    "Images\Screenshots" = @()
    "Images\Icons" = @("ico","icns","cur","ani")
    "Images\Memes" = @()
    "Audio\Music" = @("mp3","flac","wav","aac","ogg","m4a","wma","opus","ape","mpc","tta","wv","dsd","dsf","dff")
    "Audio\Podcasts" = @()
    "Audio\Audiobooks" = @("m4b","aa","aax")
    "Audio\Project" = @("als","flp","cpr","npr","mscz","ptx","logic","band","reason","cmf","drm","ens","sib","musx","omg")
    "Audio\Samples" = @("rex","rx2","sf2","sfz","gig","nki","exs24","nnp","fxp","h2drumkit")
    "Video\Movies" = @("mp4","mkv","avi","mov","wmv","mpg","mpeg","m4v","rm","rmvb","asf","f4v","ogv")
    "Video\Series" = @()
    "Video\Clips" = @("webm","flv","3gp","ts","vob","mts","m2ts","tod","mod")
    "Video\Subtitles" = @("srt","ass","vtt","sub","idx","ssa","usf","xml","ttml","sbv")
    "Video\Project" = @("prproj","aep","fcp","fcpx","avs","kdenlive","blend","wlmp","mswmm","veg","xges")
    "Archives\Standard" = @("zip","rar","7z","tar","gz","bz2","xz","lz","lzma","z")
    "Archives\Disk" = @("iso","img","bin","cue","nrg","mds","ccd","daa","udf")
    "Archives\Cabinet" = @("cab","msi","msp","wim","esd")
    "Archives\Packages" = @("deb","rpm","pkg","xar","tgz","txz","tbz2")
    "Programs\Windows" = @("exe","msi","bat","cmd","ps1","vbs","wsf","scr","pif","com")
    "Programs\Mac" = @("dmg","pkg","app","mpkg","bundle")
    "Programs\Linux" = @("deb","rpm","appimage","snap","flatpak","run","bin")
    "Programs\Mobile" = @("apk","ipa","xap","appx","msix")
    "Programs\Registry" = @("reg","inf","cat","sys","drv")
    "Programs\Scripts" = @("ahk","au3","nsi","iss","sh","bash","zsh","fish","csh")
    "Code\Web" = @("html","htm","css","scss","sass","less","js","ts","jsx","tsx","vue","php","asp","aspx","jsp","erb","handlebars","mustache")
    "Code\Languages" = @("py","java","cs","cpp","c","h","hpp","cc","cxx","go","rs","kt","rb","swift","scala","lua","pl","r","m","mm","f","f90","f95","pas","pp","ada","vb","bas")
    "Code\Data" = @("json","xml","yaml","yml","toml","ini","cfg","conf","properties","plist","reg")
    "Code\Database" = @("sql","db","sqlite","sqlite3","mdb","accdb","dbf","frm","myd","myi")
    "Code\Config" = @("dockerfile","vagrantfile","makefile","rakefile","gulpfile","webpack","package","composer","requirements","gemfile","podfile")
    "Code\Notebooks" = @("ipynb","rmd","qmd","nb","mathematica")
    "Games\ROMs" = @("rom","nes","smc","sfc","gb","gbc","gba","nds","3ds","n64","z64","v64","iso","cso","pbp","wbfs","gcm")
    "Games\Saves" = @("sav","save","dat","srm","st","ss","savestate","state","mcr","gme","vmc","ps2","xps")
    "Games\Mods" = @("pak","wad","pk3","vpk","bsp","map","sk3","unitypackage")
    "Games\Steam" = @("acf","blob","manifest","vdf")
    "Development\Projects" = @("sln","csproj","vbproj","vcxproj","xcodeproj","xcworkspace","pbxproj","gradle","pom","build","ant")
    "Development\Libraries" = @("dll","so","dylib","lib","a","jar","war","ear","aar","framework")
    "Development\Certificates" = @("crt","cer","pem","p12","pfx","key","pub","csr","jks","keystore")
    "3D\Models" = @("obj","fbx","dae","3ds","max","blend","ma","mb","c4d","lwo","lws","x3d","ply","stl")
    "3D\CAD" = @("dwg","dxf","step","stp","iges","igs","sat","parasolid","catpart","catproduct","prt","asm")
    "3D\Textures" = @("exr","hdr","tga","dds","ktx","basis")
    "Scientific\Data" = @("csv","tsv","dat","h5","hdf5","nc","cdf","fits","mat","sav","dta","por")
    "Scientific\References" = @("bib","ris","enw","ref","nbib")
    "Scientific\Presentations" = @()
    "Business\Templates" = @("dot","dotx","potx","xltx","oft","odt","ott","ots","otp")
    "Business\Reports" = @()
    "Business\Proposals" = @()
    "MediaProduction\RAW" = @("r3d","braw","mxf","mov","prores","dnxhd","avchd")
    "MediaProduction\Audio" = @("aiff","bwf","rf64","w64","caf","sd2")
    "MediaProduction\Presets" = @("fcp","mogrt","aep","prproj","veg","pro")
    "Legacy\Documents" = @("wpd","wps","works","cwk","pages","key","numbers")
    "Legacy\Images" = @("pcx","tga","xbm","xpm","ppm","pgm","pbm","pnm")
    "Legacy\Archives" = @("sit","sea","hqx","arc","zoo","lzh","arj","ace")
    "System\Logs" = @("log","trace","crash","dump","dmp","evtx","etl")
    "System\Cache" = @("cache","tmp","temp","thumbs","ds_store")
    "System\Backups" = @("bak","backup","old","orig","~")
    "Torrents" = @("torrent","magnet")
    "Fonts\TrueType" = @("ttf","ttc")
    "Fonts\OpenType" = @("otf","otc")
    "Fonts\Web" = @("woff","woff2","eot")
    "Fonts\Legacy" = @("fon","fnt","bdf","pcf","snf","pfa","pfb","afm","pfm")
}
Write-DebugLog "Configuration loaded: $($folderStructure.Count) categories"

$skipExtensions = @("tmp","crdownload","part","filepart","download","opdownload","!qb","bc!","dlm")
$maxFileNameLength = 100
$enableDuplicateDetection = $true
$enableFilenameProcessing = $true
$enableScheduling = $false

# ------------------- Helpers -------------------
$global:fileHashCache = @{}
$global:duplicatesFound = @()
$global:processedCount = 0

function Get-SeriesDestination($filename) { if ($filename -match "S\d+E\d+|Season\s*\d+|Episode\s*\d+|s\d+e\d+") { return "Video\Series" } return $null }
function Get-ScreenshotDestination($filename) { foreach ($p in @("screenshot","screen shot","snip","capture","screencap","screenclip")) { if ($filename -match $p) { return "Images\Screenshots" } } return $null }
function Get-SchoolDestination($filename) { foreach ($p in @("pset","problem set","homework","assignment","lab","midterm","final","exam")) { if ($filename -match $p) { return "Documents\School" } } return $null }
function Get-EbookDestination($filename, $ext) { if ($ext -eq "pdf") { foreach ($p in @("book","ebook","novel","guide","manual","tutorial","handbook")) { if ($filename -match $p) { return "Documents\Ebooks" } } } return $null }
function Get-BusinessDestination($filename, $ext) {
    foreach ($p in @("report","analysis","summary","quarterly","annual")) { if ($filename -match $p) { return "Business\Reports" } }
    foreach ($p in @("proposal","quote","estimate","bid","contract","agreement")) { if ($filename -match $p) { return "Business\Proposals" } }
    return $null
}
function Get-PodcastDestination($filename) { foreach ($p in @("podcast","episode","interview","talk","show","cast")) { if ($filename -match $p) { return "Audio\Podcasts" } } return $null }
function Get-MemeDestination($filename) { foreach ($p in @("meme","funny","lol","lmao","reaction","gif","comic")) { if ($filename -match $p) { return "Images\Memes" } } return $null }

function Get-FileHash-Fast($filePath) {
    try {
        if (Test-Path $filePath) { return (Get-FileHash -Path $filePath -Algorithm MD5 -ErrorAction Stop).Hash }
        return $null
    } catch { Write-ErrorLog "Hash failed for $filePath" $_; return $null }
}
function Sanitize-Filename($filename, $extension, $destinationFolder, $creationDate) {
    if (-not $enableFilenameProcessing) { return $filename }
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($filename)
    $clean = $baseName -replace '[<>:"/\\|?*]', '' -replace '\s+', '_'
    $dateStr = $creationDate.ToString("MMM-dd-yyyy").ToUpper()
    $newBase = "$clean" + "_" + "$dateStr"
    $maxBase = $maxFileNameLength - $extension.Length - 1
    if ($newBase.Length -gt $maxBase) { $newBase = $newBase.Substring(0, $maxBase) }
    return "$newBase.$extension"
}
function Test-DuplicateFile($filePath, $fileHash) {
    if (-not $enableDuplicateDetection) { return $false }
    if ($fileHash -and $global:fileHashCache.ContainsKey($fileHash)) {
        $existing = $global:fileHashCache[$fileHash]
        if (Test-Path $existing) {
            $global:duplicatesFound += @{ Original=$existing; Duplicate=$filePath; Hash=$fileHash }
            return $true
        } else { $global:fileHashCache.Remove($fileHash) }
    }
    if ($fileHash) { $global:fileHashCache[$fileHash] = $filePath }
    return $false
}
function Create-ScheduledTask {
    if (-not $enableScheduling) { return }
    try {
        $scriptPath = $PSCommandPath
        $taskName = "Auto-Downloads-Organizer"
        if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) { return }
        $trigger = New-ScheduledTaskTrigger -Daily -At "02:00"
        $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File `"$scriptPath`""
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        Register-ScheduledTask -TaskName $taskName -Trigger $trigger -Action $action -Settings $settings -Description "Organize Downloads daily" -RunLevel Highest | Out-Null
    } catch { Write-ErrorLog "Create-ScheduledTask failed" $_ }
}
function Get-UniqueFileName($basePath, $fileName) { return $fileName }

# Build extension lookup
Write-DebugLog "Building extension lookup table"
$extensionToFolder = @{}
foreach ($folder in $folderStructure.Keys) {
    foreach ($ext in $folderStructure[$folder]) { $extensionToFolder[$ext.ToLower()] = $folder }
}
Write-DebugLog "Extension map count: $($extensionToFolder.Count)"

if ($enableScheduling) { Create-ScheduledTask }

# ------------------- Scan -------------------
Write-DebugLog "Scanning Downloads folder..."
try {
    $filesToProcess = Get-ChildItem -Path $downloadsPath -File -Recurse | Where-Object {
        -not ($_.Attributes -band [System.IO.FileAttributes]::Hidden) -and
        -not ($_.Attributes -band [System.IO.FileAttributes]::System)
    }
} catch { Write-ErrorLog "Failed scanning $downloadsPath" $_; exit 1 }

$totalFiles = ($filesToProcess | Measure-Object).Count
Write-DebugLog "Found $totalFiles files"

if ($totalFiles -eq 0) {
    Write-DebugLog "No files to organize"
    "=== Completed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===" | Out-File -FilePath $debugLogPath -Append -Encoding UTF8
    exit 0
}

# ------------------- Process -------------------
$movedCount = 0; $skippedCount = 0; $errorCount = 0; $duplicatesSkipped = 0; $filesRenamed = 0
$currentFile = 0

foreach ($file in $filesToProcess) {
    try {
        $currentFile++
        $pct = [math]::Round(($currentFile / $totalFiles) * 100, 1)
        $ext = $file.Extension.TrimStart('.').ToLower()
        $namePattern = $file.BaseName.ToLower()

        Write-DebugLog "[$pct%] Processing: $($file.Name)"

        if ([string]::IsNullOrEmpty($ext)) { $skippedCount++; Write-DebugLog "Skipped: No extension"; continue }
        if ($ext -in $skipExtensions) { $skippedCount++; Write-DebugLog "Skipped: Temp extension .$ext"; continue }

        $fileHash = $null
        if ($enableDuplicateDetection) {
            $fileHash = Get-FileHash-Fast $file.FullName
            if ($fileHash -and (Test-DuplicateFile $file.FullName $fileHash)) { $duplicatesSkipped++; Write-DebugLog "Skipped: Duplicate"; continue }
        }

        $destFolder = $null
        if (-not $destFolder) { $destFolder = Get-ScreenshotDestination $namePattern }
        if (-not $destFolder) {
            $series = Get-SeriesDestination $namePattern
            if ($series -and $ext -in @("mp4","mkv","avi","mov","wmv","mpg","mpeg","m4v","rm","rmvb","asf","f4v","ogv")) { $destFolder = $series }
        }
        if (-not $destFolder) { $destFolder = Get-SchoolDestination $namePattern }
        if (-not $destFolder) { $destFolder = Get-EbookDestination $namePattern $ext }
        if (-not $destFolder) { $destFolder = Get-BusinessDestination $namePattern $ext }
        if (-not $destFolder) {
            $pod = Get-PodcastDestination $namePattern
            if ($pod -and $ext -in @("mp3","flac","wav","aac","ogg","m4a","wma","opus","ape","mpc","tta","wv","dsd","dsf","dff")) { $destFolder = $pod }
        }
        if (-not $destFolder) {
            $meme = Get-MemeDestination $namePattern
            if ($meme -and $ext -in @("jpg","jpeg","png","gif","bmp","tif","tiff","webp","heic","avif","jfif","pjpeg","pjp")) { $destFolder = $meme }
        }
        if (-not $destFolder) {
            if ($extensionToFolder.ContainsKey($ext)) { $destFolder = $extensionToFolder[$ext] } else { $destFolder = "Misc" }
        }

        $destPath = Join-Path $downloadsPath $destFolder

        if ($file.DirectoryName -eq $destPath) { $skippedCount++; Write-DebugLog "Already in correct location"; continue }

        if (-not (Test-Path $destPath)) {
            try {
                New-Item -Path $destPath -ItemType Directory -Force | Out-Null
                Write-DebugLog "Created folder: $destFolder"
            } catch { Write-ErrorLog "Failed creating folder $destPath" $_; $errorCount++; continue }
        }

        $processedName = Sanitize-Filename $file.Name $ext $destFolder $file.CreationTime
        if ($processedName -ne $file.Name) { $filesRenamed++ }

        $destFile = Join-Path $destPath $processedName

        if (-not (Test-Path $file.FullName)) { Write-ErrorLog "Source missing before move: $($file.FullName)"; $errorCount++; continue }

        try {
            Move-Item -Path $file.FullName -Destination $destFile -Force
            $movedCount++; $global:processedCount++
            Write-DebugLog "Moved to: $destFolder"
        } catch { Write-ErrorLog "Move failed: $($file.FullName) -> $destFile" $_; $errorCount++ }
    } catch {
        Write-ErrorLog "Unexpected error: $($file.FullName)" $_
        $errorCount++
    }
}

# ------------------- Summary -------------------
Write-DebugLog "ORGANIZATION COMPLETE"
$summary = @"
Files processed: $totalFiles
- Moved: $movedCount
- Renamed: $filesRenamed
- Duplicates skipped: $duplicatesSkipped
- Other skipped: $skippedCount
- Errors: $errorCount
"@
Write-DebugLog $summary

try { Show-Notification -Title "Downloads Organizer" -Message $summary } catch { Write-ErrorLog "Notification failed at end" $_ }

"=== Completed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===" | Out-File -FilePath $debugLogPath -Append -Encoding UTF8
"Summary: Moved=$movedCount, Renamed=$filesRenamed, Duplicates=$duplicatesSkipped, Skipped=$skippedCount, Errors=$errorCount" | Out-File -FilePath $debugLogPath -Append -Encoding UTF8
Write-Host "Debug log: $debugLogPath"
Write-Host "Error log: $errorLogPath"

Read-Host -Prompt "Press Enter to exit"
exit 0

