#requires -Version 5.1

<#
.SYNOPSIS
    Simple File Organizer - Organizes files in Documents folder by type
.DESCRIPTION
    Automatically organizes files into categories and removes empty folders
.NOTES
    Requires Administrator privileges
#>

# ═══════════════════════════════════════════════════════════
# CHECK: Running as Administrator?
# ═══════════════════════════════════════════════════════════
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    # Auto-Elevate
    $scriptPath = $MyInvocation.MyCommand.Path
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    exit
}

# ═══════════════════════════════════════════════════════════
# CHECK: PowerShell Version >= 5.1?
# ═══════════════════════════════════════════════════════════
if ($PSVersionTable.PSVersion.Major -lt 5 -or ($PSVersionTable.PSVersion.Major -eq 5 -and $PSVersionTable.PSVersion.Minor -lt 1)) {
    Write-Host "ERROR: PowerShell 5.1 or higher is required" -ForegroundColor Red
    exit 1
}

# ═══════════════════════════════════════════════════════════
# DEFINE Categories & Extensions
# ═══════════════════════════════════════════════════════════
$categories = @{
    "Documents\Word" = @('doc', 'docx', 'dot', 'dotx', 'docm', 'dotm', 'rtf', 'odt')
    "Documents\PDF" = @('pdf')
    "Documents\Text" = @('txt', 'log', 'md', 'markdown')
    "Documents\Excel" = @('xls', 'xlsx', 'csv', 'xlsm', 'ods', 'xlsb', 'xltx', 'xltm', 'numbers')
    "Documents\PowerPoint" = @('ppt', 'pptx', 'pps', 'ppsx', 'pot', 'potx', 'odp')
    "Documents\Other Office" = @('pub', 'one', 'xps')
    
    "Images\Photos" = @('jpg', 'jpeg', 'heic', 'heif')
    "Images\PNG" = @('png')
    "Images\Graphics" = @('gif', 'bmp', 'tiff', 'webp', 'svg')
    
    "Videos\MP4" = @('mp4', 'm4v')
    "Videos\MKV" = @('mkv')
    "Videos\Other" = @('mov', 'avi', 'wmv', 'flv', 'webm', '3gp')
    
    "Audio\Music" = @('mp3', 'm4a', 'flac', 'aac')
    "Audio\Other" = @('wav', 'ogg', 'wma', 'aiff')
    
    "Archive\ZIP" = @('zip')
    "Archive\RAR" = @('rar')
    "Archive\Other" = @('7z', 'tar', 'gz', 'iso', 'cab')
    
    "Application\Executables" = @('exe', 'msi')
    "Application\Scripts" = @('bat', 'cmd', 'ps1', 'sh', 'py', 'js')
    "Application\Installers" = @('apk', 'dmg', 'pkg', 'deb', 'rpm')
    
    "Fonts" = @('ttf', 'otf', 'woff', 'woff2', 'eot', 'fon')
    
    "Design\Icons" = @('ico', 'icns')
    "Design\Vector" = @('eps', 'cdr', 'svg')
    "Design\3D" = @('blend', 'obj', 'fbx', 'stl', 'max', '3ds')
    
    "Code\Web" = @('html', 'htm', 'css', 'scss', 'sass', 'less', 'php', 'asp', 'aspx', 'jsp')
    "Code\Data" = @('json', 'xml', 'yaml', 'yml', 'toml', 'ini', 'cfg', 'conf')
    "Code\Database" = @('sql', 'db', 'sqlite', 'mdb', 'accdb')
    
    "Adobe\Photoshop" = @('psd', 'psb', 'pat', 'abr')
    "Adobe\Illustrator" = @('ai', 'ait')
    "Adobe\Premiere" = @('prproj', 'prel')
    "Adobe\After Effects" = @('aep', 'aet', 'aepx')
    "Adobe\InDesign" = @('indd', 'indl', 'indt', 'idml')
    "Adobe\Audition" = @('sesx', 'pkf')
    "Adobe\XD" = @('xd')
    
    "eBooks" = @('epub', 'mobi', 'azw', 'azw3')
}

# ═══════════════════════════════════════════════════════════
# BUILD Extension Lookup Table
# ═══════════════════════════════════════════════════════════
$extensionLookup = @{}
foreach ($category in $categories.Keys) {
    foreach ($ext in $categories[$category]) {
        $extensionLookup[$ext] = $category
    }
}

# ═══════════════════════════════════════════════════════════
# SET Source Folder (Ask User)
# ═══════════════════════════════════════════════════════════
Write-Host ""
Write-Host "═══════════════════════════════════" -ForegroundColor White
Write-Host "   SELECT FOLDER TO ORGANIZE" -ForegroundColor White
Write-Host "═══════════════════════════════════" -ForegroundColor White
Write-Host ""

$documentsPath = [Environment]::GetFolderPath('MyDocuments')
$downloadsPath = Join-Path ([Environment]::GetFolderPath('UserProfile')) 'Downloads'
$desktopPath = [Environment]::GetFolderPath('Desktop')
$picturesPath = [Environment]::GetFolderPath('MyPictures')
$videosPath = [Environment]::GetFolderPath('MyVideos')
$musicPath = [Environment]::GetFolderPath('MyMusic')

Write-Host "[1] Documents  - $documentsPath" -ForegroundColor Cyan
Write-Host "[2] Downloads  - $downloadsPath" -ForegroundColor Cyan
Write-Host "[3] Desktop    - $desktopPath" -ForegroundColor Cyan
Write-Host "[4] Pictures   - $picturesPath" -ForegroundColor Cyan
Write-Host "[5] Videos     - $videosPath" -ForegroundColor Cyan
Write-Host "[6] Music      - $musicPath" -ForegroundColor Cyan
Write-Host ""

$choice = Read-Host "Select folder to organize [1-6] (default: 1)"

if ([string]::IsNullOrWhiteSpace($choice)) {
    $choice = "1"
}

switch ($choice) {
    "1" { $sourceFolder = $documentsPath }
    "2" { $sourceFolder = $downloadsPath }
    "3" { $sourceFolder = $desktopPath }
    "4" { $sourceFolder = $picturesPath }
    "5" { $sourceFolder = $videosPath }
    "6" { $sourceFolder = $musicPath }
    default {
        Write-Host "Invalid choice. Using Documents folder." -ForegroundColor Yellow
        $sourceFolder = $documentsPath
    }
}

if (-not (Test-Path $sourceFolder)) {
    Write-Host "ERROR: Source folder does not exist: $sourceFolder" -ForegroundColor Red
    exit 1
}

# ═══════════════════════════════════════════════════════════
# SET Destination Folder (Always Documents)
# ═══════════════════════════════════════════════════════════
$targetFolder = $documentsPath

if (-not (Test-Path $targetFolder)) {
    Write-Host "ERROR: Destination folder does not exist: $targetFolder" -ForegroundColor Red
    exit 1
}

# ═══════════════════════════════════════════════════════════
# SHOW Preview
# ═══════════════════════════════════════════════════════════
Write-Host ""
Write-Host "═══════════════════════════════════" -ForegroundColor White
Write-Host "Source Folder:      $sourceFolder" -ForegroundColor White
Write-Host "Destination Folder: $targetFolder" -ForegroundColor White
Write-Host "═══════════════════════════════════" -ForegroundColor White

$allFiles = Get-ChildItem -Path $sourceFolder -Recurse -File -ErrorAction SilentlyContinue | Where-Object { -not $_.Attributes.HasFlag([System.IO.FileAttributes]::Hidden) -and -not $_.Attributes.HasFlag([System.IO.FileAttributes]::System) }
$totalCount = $allFiles.Count

Write-Host "Found $totalCount files to organize" -ForegroundColor White
Write-Host ""

$confirmation = Read-Host "Organize these files? (Y/N)"
if ($confirmation -ne 'Y') {
    Write-Host "Cancelled" -ForegroundColor Yellow
    exit 0
}
Write-Host ""

# ═══════════════════════════════════════════════════════════
# SCAN Files RECURSIVELY
# ═══════════════════════════════════════════════════════════
if ($totalCount -eq 0) {
    Write-Host "No files to organize" -ForegroundColor Yellow
    # Skip to cleanup
}

# ═══════════════════════════════════════════════════════════
# PROCESS Each File
# ═══════════════════════════════════════════════════════════
$movedCount = 0
$skippedCount = 0
$errorCount = 0
$processedCount = 0
$foldersToCreate = @{}

foreach ($file in $allFiles) {
    $processedCount++
    
    # Update progress every 50 files
    if ($processedCount % 50 -eq 0) {
        Write-Progress -Activity "Organizing Files" -Status "Processing file $processedCount of $totalCount" -PercentComplete (($processedCount / $totalCount) * 100)
    }
    
    # GET file extension (lowercase, without dot)
    $extension = $file.Extension.TrimStart('.').ToLower()
    
    # CHECK: Extension empty?
    if ([string]::IsNullOrEmpty($extension)) {
        continue
    }
    
    # LOOKUP Extension in extensionLookup table
    if ($extensionLookup.ContainsKey($extension)) {
        $categoryPath = $extensionLookup[$extension]
    } else {
        $extUpper = $extension.ToUpper()
        $categoryPath = "Others\$extUpper"
    }
    
    # BUILD Destination Folder Path
    $destinationFolder = Join-Path $targetFolder $categoryPath
    
    # CHECK: File already in correct location?
    $currentDirectory = $file.Directory.FullName.TrimEnd('\')
    $normalizedDestination = $destinationFolder.TrimEnd('\')
    
    # Also check if file is already anywhere in the destination Documents structure
    $isInDestinationTree = $file.FullName.StartsWith($targetFolder, [StringComparison]::OrdinalIgnoreCase)
    
    if ($currentDirectory -eq $normalizedDestination) {
        # File is already in the exact correct folder
        $skippedCount++
        continue
    }
    
    if ($isInDestinationTree -and $sourceFolder -ne $targetFolder) {
        # File is already somewhere in the Documents organized structure
        # Skip it to avoid moving already organized files
        $skippedCount++
        continue
    }
    
    # Mark this folder as needed (only create if we actually move a file)
    if (-not $foldersToCreate.ContainsKey($destinationFolder)) {
        $foldersToCreate[$destinationFolder] = $true
    }
    
    # CHECK: Destination folder exists? Create only if needed
    if (-not (Test-Path $destinationFolder)) {
        New-Item -ItemType Directory -Path $destinationFolder -Force | Out-Null
    }
    
    # BUILD Destination File Path
    $destinationFile = Join-Path $destinationFolder $file.Name
    
    # CHECK: File with same name exists in destination?
    if (Test-Path $destinationFile) {
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $ext = $file.Extension
        $counter = 1
        
        while (Test-Path $destinationFile) {
            $newName = "$baseName ($counter)$ext"
            $destinationFile = Join-Path $destinationFolder $newName
            $counter++
        }
    }
    
    # MOVE File
    try {
        $relativeDest = $destinationFile.Replace($targetFolder, "").TrimStart('\')
        $arrow = [char]0x2500 + [char]0x2500 + [char]0x2192
        Write-Host "MOVED  $($file.Name) $arrow $relativeDest" -ForegroundColor Cyan
        
        Move-Item -Path $file.FullName -Destination $destinationFile -Force
        $movedCount++
    } catch {
        Write-Host "ERROR  Failed to move $($file.Name): $_" -ForegroundColor Red
        $errorCount++
    }
}

Write-Progress -Activity "Organizing Files" -Completed

# ═══════════════════════════════════════════════════════════
# EMPTY FOLDER CLEANUP (Recursive)
# ═══════════════════════════════════════════════════════════
Write-Host ""
Write-Host "═══════════════════════════════════" -ForegroundColor White
Write-Host "Starting empty folder cleanup..." -ForegroundColor Yellow
Write-Host ""

# DEFINE folders to preserve
$organizedCategories = @('Documents', 'Adobe', 'Images', 'Videos', 'Audio', 'Archive', 'Application', 'Fonts', 'Design', 'Code', 'Others', 'eBooks')
$systemFolders = @('Windows', 'Program Files', 'Program Files (x86)', 'System32', 'ProgramData', 'AppData')

# GET all folders RECURSIVELY (sorted by depth, deepest first)
$allFolders = Get-ChildItem -Path $sourceFolder -Recurse -Directory -ErrorAction SilentlyContinue | Sort-Object -Property @{Expression={$_.FullName.Length}; Descending=$true}

$removedCount = 0
$folderProcessed = 0

foreach ($folder in $allFolders) {
    $folderProcessed++
    
    # Update progress every 20 folders
    if ($folderProcessed % 20 -eq 0) {
        Write-Progress -Activity "Cleaning Empty Folders" -Status "Processing folder $folderProcessed of $($allFolders.Count)" -PercentComplete (($folderProcessed / $allFolders.Count) * 100)
    }
    
    # CHECK: Is system folder?
    $isSystemFolder = $false
    foreach ($sysFolder in $systemFolders) {
        if ($folder.FullName -like "*$sysFolder*") {
            $isSystemFolder = $true
            break
        }
    }
    if ($isSystemFolder) { continue }
    
    # CHECK: Is organized category folder or subfolder?
    $relativePath = $folder.FullName.Replace($sourceFolder, "").TrimStart('\')
    $pathParts = $relativePath -split '\\'
    
    if ($pathParts.Count -gt 0 -and $organizedCategories -contains $pathParts[0]) {
        continue
    }
    
    # CHECK: Folder is empty?
    try {
        $items = Get-ChildItem -Path $folder.FullName -Force -ErrorAction Stop
        
        if ($items.Count -eq 0) {
            try {
                $relativeFolder = $folder.FullName.Replace($sourceFolder, "").TrimStart('\')
                Write-Host "DELETED EMPTY FOLDER  $relativeFolder" -ForegroundColor Yellow
                
                Remove-Item -Path $folder.FullName -Force -Recurse
                $removedCount++
            } catch {
                # Skip (no permission or in use)
            }
        }
    } catch {
        # Skip folder (access denied)
    }
}

Write-Progress -Activity "Cleaning Empty Folders" -Completed

# SECOND PASS (if any folders removed in first pass)
$totalRemoved = $removedCount
if ($removedCount -gt 0) {
    Write-Host "Running second cleanup pass..." -ForegroundColor Yellow
    $secondPassRemoved = 0
    
    $allFolders = Get-ChildItem -Path $sourceFolder -Recurse -Directory -ErrorAction SilentlyContinue | Sort-Object -Property @{Expression={$_.FullName.Length}; Descending=$true}
    
    foreach ($folder in $allFolders) {
        # CHECK: Is system folder?
        $isSystemFolder = $false
        foreach ($sysFolder in $systemFolders) {
            if ($folder.FullName -like "*$sysFolder*") {
                $isSystemFolder = $true
                break
            }
        }
        if ($isSystemFolder) { continue }
        
        # CHECK: Is organized category folder or subfolder?
        $relativePath = $folder.FullName.Replace($sourceFolder, "").TrimStart('\')
        $pathParts = $relativePath -split '\\'
        
        if ($pathParts.Count -gt 0 -and $organizedCategories -contains $pathParts[0]) {
            continue
        }
        
        # CHECK: Folder is empty?
        try {
            $items = Get-ChildItem -Path $folder.FullName -Force -ErrorAction Stop
            
            if ($items.Count -eq 0) {
                try {
                    $relativeFolder = $folder.FullName.Replace($sourceFolder, "").TrimStart('\')
                    Write-Host "DELETED EMPTY FOLDER  $relativeFolder" -ForegroundColor Yellow
                    
                    Remove-Item -Path $folder.FullName -Force -Recurse
                    $secondPassRemoved++
                } catch {
                    # Skip
                }
            }
        } catch {
            # Skip folder
        }
    }
    
    $totalRemoved = $removedCount + $secondPassRemoved
    
    if ($secondPassRemoved -gt 0) {
        Write-Host "Second pass removed $secondPassRemoved more folders" -ForegroundColor Yellow
    }
}

# DISPLAY cleanup results
Write-Host ""
Write-Host "═══════════════════════════════════" -ForegroundColor White
if ($totalRemoved -gt 0) {
    Write-Host "Checkmark $totalRemoved empty folders removed" -ForegroundColor Green
} else {
    Write-Host "No empty folders found" -ForegroundColor Gray
}

# ═══════════════════════════════════════════════════════════
# DISPLAY Final Results
# ═══════════════════════════════════════════════════════════
Write-Host ""
Write-Host "═══════════════════════════════════" -ForegroundColor White
Write-Host "    ORGANIZATION COMPLETE" -ForegroundColor White
Write-Host "═══════════════════════════════════" -ForegroundColor White
Write-Host ""
Write-Host "Files scanned:         $totalCount" -ForegroundColor White
Write-Host "Files moved:           $movedCount" -ForegroundColor Green
Write-Host "Files skipped:         $skippedCount" -ForegroundColor Gray
Write-Host "Empty folders removed: $totalRemoved" -ForegroundColor Yellow

if ($errorCount -eq 0) {
    Write-Host "Errors encountered:    0" -ForegroundColor Green
} else {
    Write-Host "Errors encountered:    $errorCount" -ForegroundColor Red
}

Write-Host ""
Write-Host "═══════════════════════════════════" -ForegroundColor White
$again = Read-Host "Organize another folder? (Y/N)"

if ($again -eq 'Y' -or $again -eq 'y') {
    # Clear screen and restart
    Clear-Host
    & $MyInvocation.MyCommand.Path
    exit 0
} else {
    Write-Host ""
    Write-Host "Thank you for using File Organizer!" -ForegroundColor Green
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    [void][System.Console]::ReadKey()
    exit 0
}

# This code should not be reached, but keeping for safety
exit 0
