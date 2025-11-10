#requires -Version 5.1
<#
.SYNOPSIS
    Smart file organizer for Downloads and Documents folders
.DESCRIPTION
    Organizes files by extension with duplicate detection, parallel hashing,
    and automatic empty folder cleanup. All files organized into Documents folder.
#>

[CmdletBinding()]
param()

# ==================== CONFIGURATION ====================
$Script:Config = @{
    EnableDuplicateDetection = $true
    DuplicatePreference = 'Newest'  # 'Newest', 'Largest', or 'Smallest'
    ParallelHashingThreshold = 50
    EnableEmptyFolderCleanup = $true
}

# Known system/application folders to skip
$Script:KnownFoldersToSkip = @(
    'Windows', 'Program Files', 'Program Files (x86)', 'ProgramData',
    'System Volume Information', '$Recycle.Bin', 'Recovery',
    'WindowsApps', 'OneDrive', 'Dropbox', 'Google Drive',
    '.git', '.svn', 'node_modules', '.vscode', '.idea',
    'AppData', 'Application Data', 'Cookies', 'Local Settings',
    'NetHood', 'PrintHood', 'Recent', 'SendTo', 'Start Menu',
    'Templates', 'Desktop', 'My Documents', 'My Music', 
    'My Pictures', 'My Videos', 'Saved Games', 'Searches',
    'Favorites', 'Links', 'Contacts'
)

# Extensions to skip (temporary/incomplete downloads)
$Script:SkipExtensions = @(
    'tmp', 'crdownload', 'part', 'filepart', 'download',
    'opdownload', '!qb', 'bc!', 'dlm', 'partial'
)

$Script:Categories = @{
    
    # ========================================================================
    # DOCUMENTS - Office & Productivity
    # ========================================================================
    
    # Microsoft Office - Word Processing
    'Documents\Microsoft\Word' = @('doc', 'docx', 'dot', 'dotx', 'docm', 'dotm')
    
    # Microsoft Office - Spreadsheets
    'Documents\Microsoft\Excel' = @('xls', 'xlsx', 'xlsm', 'xlsb', 'xlt', 'xltx', 'xltm', 'xlam', 'csv', 'tsv')
    
    # Microsoft Office - Presentations
    'Documents\Microsoft\PowerPoint' = @('ppt', 'pptx', 'pptm', 'pps', 'ppsx', 'ppsm', 'pot', 'potx', 'potm', 'ppam')
    
    # Microsoft Office - Other
    'Documents\Microsoft\Access' = @('mdb', 'accdb', 'accde', 'accdt', 'accdr')
    'Documents\Microsoft\Publisher' = @('pub')
    'Documents\Microsoft\Visio' = @('vsd', 'vsdx', 'vss', 'vssx', 'vst', 'vstx')
    'Documents\Microsoft\Project' = @('mpp', 'mpt')
    'Documents\Microsoft\OneNote' = @('one', 'onetoc2', 'onepkg')
    
    # LibreOffice & OpenOffice
    'Documents\OpenOffice\Writer' = @('odt', 'ott', 'sxw', 'stw', 'fodt')
    'Documents\OpenOffice\Calc' = @('ods', 'ots', 'sxc', 'stc', 'fods')
    'Documents\OpenOffice\Impress' = @('odp', 'otp', 'sxi', 'sti', 'fodp')
    'Documents\OpenOffice\Draw' = @('odg', 'otg', 'sxd', 'std')
    'Documents\OpenOffice\Base' = @('odb')
    'Documents\OpenOffice\Math' = @('odf', 'sxm')
    
    # Apple iWork
    'Documents\Apple\Pages' = @('pages', 'pages-tef')
    'Documents\Apple\Numbers' = @('numbers', 'numbers-tef')
    'Documents\Apple\Keynote' = @('key', 'keynote')
    
    # Google Workspace (local/export formats)
    'Documents\Google' = @('gdoc', 'gsheet', 'gslides', 'gdraw')
    
    # Other Word Processors
    'Documents\WordProcessors' = @('wpd', 'wps', 'wpt', 'abw', 'aww', 'zabw')
    
    # PDF & Fixed Layout
    'Documents\PDF' = @('pdf', 'xps', 'oxps')
    
    # Plain Text & Markup
    'Documents\Text' = @('txt', 'text', 'rtf', 'rtfd', 'md', 'markdown', 'mdown', 'mkd', 'mdx', 'rmd', 'tex', 'latex', 'ltx', 'log', 'readme', 'changelog', 'license', 'authors', 'todo', 'nfo', 'diz')
    
    # E-books & Digital Publishing
    'Documents\Ebooks' = @('epub', 'epub3', 'mobi', 'azw', 'azw3', 'azw4', 'kfx', 'kf8', 'fb2', 'lit', 'prc', 'djvu', 'djv', 'ibooks', 'cbr', 'cbz', 'cb7', 'cbt', 'cba')
    
    # Forms & Templates
    'Documents\Forms' = @('form', 'xfdl', 'fdf', 'xfdf')
    
    # Note-taking Apps
    'Documents\Notes' = @('enex', 'enml', 'note', 'nb', 'nbk', 'notebook')
    
    
    # ========================================================================
    # IMAGES - Graphics & Photography
    # ========================================================================
    
    # Common Photo Formats (grouped by similarity)
    'Images\Photos' = @('jpg', 'jpeg', 'jpe', 'jif', 'jfif', 'jfi', 'png', 'apng', 'webp', 'gif', 'bmp', 'dib', 'tif', 'tiff', 'heic', 'heif', 'heics', 'avif', 'jxl', 'ppm', 'pgm', 'pbm', 'pnm', 'pcx', 'tga', 'icb', 'vda', 'vst')
    
    # Camera RAW Formats (all together)
    'Images\RAW' = @('cr2', 'cr3', 'crw', 'nef', 'nrw', 'arw', 'srf', 'sr2', 'raf', 'orf', 'rw2', 'raw', 'pef', 'ptx', 'dng', 'rwl', '3fr', 'fff', 'iiq', 'x3f', 'dcr', 'kdc', 'erf', 'mef', 'mos', 'mrw', 'ndd', 'ari')
    
    # Vector Graphics
    'Images\Vector' = @('svg', 'svgz', 'eps', 'epsf', 'epsi', 'emf', 'wmf', 'cgm', 'vml')
    
    # Icons & Cursors
    'Images\Icons' = @('ico', 'icns', 'cur', 'ani')
    
    
    # ========================================================================
    # DESIGN - Professional Creative Software
    # ========================================================================
    
    # Adobe Creative Suite
    'Design\Adobe\Photoshop' = @('psd', 'psb')
    'Design\Adobe\Illustrator' = @('ai', 'ait')
    'Design\Adobe\InDesign' = @('indd', 'indt', 'indl', 'indb', 'inx', 'idml')
    'Design\Adobe\XD' = @('xd')
    'Design\Adobe\Lightroom' = @('lrcat', 'lrtemplate')
    'Design\Adobe\Premiere' = @('prproj', 'psq')
    'Design\Adobe\AfterEffects' = @('aep', 'aet', 'aepx')
    'Design\Adobe\Animate' = @('fla', 'xfl')
    'Design\Adobe\Dimension' = @('dn')
    'Design\Adobe\Dreamweaver' = @('dw')
    'Design\Adobe\Muse' = @('muse')
    
    # Affinity Suite
    'Design\Affinity\Photo' = @('afphoto')
    'Design\Affinity\Designer' = @('afdesign')
    'Design\Affinity\Publisher' = @('afpub')
    
    # CorelDRAW Suite
    'Design\Corel\Draw' = @('cdr', 'cdt', 'cmx')
    'Design\Corel\PaintShop' = @('psp', 'pspimage')
    'Design\Corel\PhotoPaint' = @('cpt')
    
    # Sketch & Figma
    'Design\Sketch' = @('sketch')
    'Design\Figma' = @('fig')
    
    # Other Design Tools
    'Design\Other' = @('canva', 'gvdesign', 'pxm', 'pxd', 'acorn')
    
    
    # ========================================================================
    # 3D & CAD - Modeling & Engineering
    # ========================================================================
    
    # Common 3D Formats (universal exchange formats)
    '3D\Models' = @('obj', 'fbx', 'dae', 'gltf', 'glb', '3ds', 'ply', 'stl', 'x3d', 'usd', 'usdz')
    
    # 3D Software Projects
    '3D\Blender' = @('blend', 'blend1')
    '3D\Maya' = @('ma', 'mb')
    '3D\3dsMax' = @('max')
    '3D\Cinema4D' = @('c4d')
    '3D\ZBrush' = @('zpr', 'ztl', 'zbr')
    '3D\Houdini' = @('hip', 'hipnc', 'hiplc')
    '3D\Modo' = @('lxo')
    '3D\LightWave' = @('lwo', 'lws')
    '3D\SketchUp' = @('skp')
    '3D\Rhino' = @('3dm')
    '3D\Substance' = @('sbs', 'sbsar')
    '3D\Unreal' = @('uasset', 'umap', 'upk')
    '3D\Unity' = @('unity', 'prefab', 'mat', 'asset')
    
    # CAD Software
    'CAD\AutoCAD' = @('dwg', 'dxf', 'dwf', 'dwt')
    'CAD\SolidWorks' = @('sldprt', 'sldasm', 'slddrw')
    'CAD\Inventor' = @('ipt', 'iam', 'idw')
    'CAD\CATIA' = @('catpart', 'catproduct', 'catdrawing')
    'CAD\Fusion360' = @('f3d')
    'CAD\Revit' = @('rvt', 'rfa', 'rte')
    'CAD\Universal' = @('step', 'stp', 'iges', 'igs', 'sat', 'ifc', 'pln', 'dwfx')
    
    
    # ========================================================================
    # AUDIO - Music & Sound
    # ========================================================================
    
    # Lossless Audio Formats
    'Audio\Lossless' = @('flac', 'alac', 'ape', 'wv', 'tta', 'tak', 'wav', 'aiff', 'aif', 'aifc', 'au', 'snd', 'pcm')
    
    # Compressed Audio Formats
    'Audio\Compressed' = @('mp3', 'aac', 'm4a', 'ogg', 'oga', 'opus', 'wma', 'mp2', 'mpa')
    
    # MIDI & Sheet Music
    'Audio\MIDI' = @('mid', 'midi', 'kar', 'rmi')
    'Audio\SheetMusic' = @('mscz', 'mscx', 'sib', 'mus', 'musx', 'cap', 'capx', 'xml', 'mxl', 'gp', 'gp3', 'gp4', 'gp5', 'gpx')
    
    # Audiobooks
    'Audio\Audiobooks' = @('m4b', 'aa', 'aax', 'aaxc')
    
    # DAW Projects - Ableton Live
    'Audio\DAW\AbletonLive' = @('als', 'alp', 'adg', 'adv', 'ams', 'amxd')
    
    # DAW Projects - FL Studio
    'Audio\DAW\FLStudio' = @('flp', 'flm')
    
    # DAW Projects - Cubase/Nuendo
    'Audio\DAW\Cubase' = @('cpr', 'npr')
    
    # DAW Projects - Logic Pro
    'Audio\DAW\LogicPro' = @('logic', 'logicx')
    
    # DAW Projects - Pro Tools
    'Audio\DAW\ProTools' = @('ptx', 'ptf', 'pts')
    
    # DAW Projects - Reaper
    'Audio\DAW\Reaper' = @('rpp', 'rpp-bak')
    
    # DAW Projects - Studio One
    'Audio\DAW\StudioOne' = @('song')
    
    # DAW Projects - Reason
    'Audio\DAW\Reason' = @('reason', 'rns')
    
    # DAW Projects - GarageBand
    'Audio\DAW\GarageBand' = @('band')
    
    # DAW Projects - Audacity
    'Audio\DAW\Audacity' = @('aup', 'aup3')
    
    # Audio Samples & Instruments
    'Audio\Samples' = @('sfz', 'sf2', 'exs', 'nki', 'nkm', 'nksf', 'akai', 'rex', 'rx2', 'wav', 'aif')
    
    
    # ========================================================================
    # VIDEO - Movies & Video Editing
    # ========================================================================
    
    # Common Video Formats (all grouped together)
    'Video\Movies' = @('mp4', 'm4v', 'mkv', 'avi', 'mov', 'qt', 'webm', 'wmv', 'asf', 'mpg', 'mpeg', 'mpe', 'm2v', 'vob', '3gp', '3g2', '3gpp', 'ogv', 'ogm', 'ts', 'm2ts', 'mts', 'mxf', 'rm', 'rmvb', 'divx', 'xvid', 'flv', 'f4v', 'swf')
    
    # Video Editing Projects - Adobe Premiere
    'Video\Projects\Premiere' = @('prproj', 'psq')
    
    # Video Editing Projects - Final Cut Pro
    'Video\Projects\FinalCut' = @('fcpproject', 'fcpbundle', 'fcpxml')
    
    # Video Editing Projects - DaVinci Resolve
    'Video\Projects\DaVinciResolve' = @('drp')
    
    # Video Editing Projects - Sony Vegas
    'Video\Projects\Vegas' = @('veg', 'vf')
    
    # Video Editing Projects - Avid
    'Video\Projects\Avid' = @('avp', 'aaf')
    
    # Video Editing Projects - Camtasia
    'Video\Projects\Camtasia' = @('cmproj', 'tscproj')
    
    # Video Editing Projects - iMovie
    'Video\Projects\iMovie' = @('imovieproject', 'rcproject')
    
    # Subtitles & Captions
    'Video\Subtitles' = @('srt', 'ass', 'ssa', 'vtt', 'sub', 'sbv', 'idx', 'smi', 'sami', 'usf')
    
    
    # ========================================================================
    # ARCHIVES & COMPRESSED FILES
    # ========================================================================
    
    # ZIP-based Archives
    'Archives\ZIP' = @('zip', 'zipx', 'jar', 'apk', 'ipa', 'xpi', 'crx', 'oxt', 'docx', 'xlsx', 'pptx')
    
    # RAR Archives
    'Archives\RAR' = @('rar', 'rev', 'r00', 'r01')
    
    # 7-Zip Archives
    'Archives\7Z' = @('7z')
    
    # TAR Archives
    'Archives\TAR' = @('tar', 'tgz', 'tar.gz', 'tbz', 'tbz2', 'tar.bz2', 'txz', 'tar.xz', 'tlz', 'tar.lz')
    
    # Other Compression
    'Archives\Other' = @('gz', 'bz2', 'xz', 'lz', 'z', 'cab', 'arj', 'lzh', 'ace', 'uue', 'zoo', 'sit', 'sitx', 'sea')
    
    # Disk Images
    'Archives\DiskImages' = @('iso', 'img', 'dmg', 'vhd', 'vhdx', 'vmdk', 'vdi', 'toast', 'cue', 'bin', 'mdf', 'mds', 'nrg', 'cdi')
    
    # Package Installers
    'Archives\Installers' = @('pkg', 'deb', 'rpm', 'AppImage', 'snap', 'flatpak')
    
    
    # ========================================================================
    # PROGRAMS & EXECUTABLES
    # ========================================================================
    
    # Windows Programs
    'Programs\Windows' = @('exe', 'msi', 'msp', 'msix', 'appx', 'bat', 'cmd', 'com', 'scr')
    
    # macOS Programs
    'Programs\macOS' = @('app', 'dmg', 'pkg')
    
    # Linux Programs
    'Programs\Linux' = @('bin', 'run', 'sh', 'deb', 'rpm', 'AppImage')
    
    # Mobile Apps
    'Programs\Mobile\Android' = @('apk', 'xapk', 'apks', 'apkm', 'obb', 'aab')
    'Programs\Mobile\iOS' = @('ipa')
    
    # Scripts
    'Programs\Scripts' = @('ps1', 'psm1', 'psd1', 'sh', 'bash', 'zsh', 'fish', 'vbs', 'vbe', 'wsf', 'wsh', 'py', 'pyc', 'rb', 'pl', 'php', 'js', 'ts', 'lua', 'groovy', 'r', 'rscript')
    
    # System Files
    'Programs\System' = @('dll', 'sys', 'drv', 'ocx', 'cpl')
    
    # Registry Files
    'Programs\Registry' = @('reg', 'pol')
    
    
    # ========================================================================
    # FONTS
    # ========================================================================
    
    'Fonts' = @('ttf', 'otf', 'woff', 'woff2', 'eot', 'fon', 'pfb', 'pfm', 'afm', 'ttc', 'otc', 'dfont', 'suit')
    
    
    # ========================================================================
    # GAME FILES
    # ========================================================================
    
    # Game ROMs & ISOs
    'Games\ROMs\Nintendo' = @('nes', 'snes', 'sfc', 'n64', 'z64', 'v64', 'nds', 'gba', 'gbc', 'gb', '3ds', 'cia', 'nsp', 'xci')
    'Games\ROMs\Sony' = @('iso', 'cso', 'pbp', 'bin', 'cue')
    'Games\ROMs\Sega' = @('smd', 'gen', 'sms', 'gg', 'cdi', 'gdi')
    'Games\ROMs\Other' = @('a26', 'a78', 'lnx', 'jag')
    
    # Game Saves & Profiles
    'Games\Saves' = @('sav', 'save', 'dat', 'gci', 'vmp', 'srm', 'mcr', 'psx', 'profile')
    
    # Game Mods
    'Games\Mods' = @('pak', 'vpk', 'wad', 'pk3', 'bsp', 'esp', 'esm')
    
    
    # ========================================================================
    # EBOOKS & DOCUMENTS (Digital Reading)
    # ========================================================================
    
    'Books\EPUB' = @('epub', 'epub3')
    'Books\Kindle' = @('mobi', 'azw', 'azw3', 'azw4', 'kfx', 'kf8')
    'Books\Comics' = @('cbr', 'cbz', 'cb7', 'cbt', 'cba')
    'Books\Other' = @('fb2', 'lit', 'prc', 'djvu', 'djv', 'ibooks')
    
    
    
    # ========================================================================
    # SHORTCUTS & LINKS
    # ========================================================================
    
    'Shortcuts' = @('lnk', 'desktop', 'directory', 'alias')
    
    
    # ========================================================================
    # EMAIL & CALENDAR
    # ========================================================================
    
    'Email\Messages' = @('eml', 'emlx', 'msg', 'oft', 'ost', 'pst', 'mbox', 'mbx')
    'Email\Calendar' = @('ics', 'ical', 'vcs', 'ifb')
    'Email\Contacts' = @('vcf', 'vcard', 'ldif')
    
    
    # ========================================================================
    # CERTIFICATES & SECURITY
    # ========================================================================
    
    'Security\Certificates' = @('cer', 'crt', 'der', 'p7b', 'p7c', 'p12', 'pfx', 'pem', 'csr', 'key')
    'Security\Keys' = @('asc', 'sig', 'gpg', 'pgp', 'kdb', 'kdbx')
    
    
    # ========================================================================
    # VIRTUAL MACHINES
    # ========================================================================
    
    'VirtualMachines\VMware' = @('vmdk', 'vmx', 'vmxf', 'vmsd', 'vmsn', 'nvram', 'vmem')
    'VirtualMachines\VirtualBox' = @('vdi', 'vbox', 'vbox-prev', 'ovf', 'ova')
    'VirtualMachines\HyperV' = @('vhd', 'vhdx', 'avhd', 'avhdx')
    'VirtualMachines\Parallels' = @('pvm', 'pvs', 'hdd')
    
    
    # ========================================================================
    # MISCELLANEOUS
    # ========================================================================
    
    'Misc\Licenses' = @('key', 'lic', 'license', 'serial')
    'Misc\Config' = @('conf', 'config', 'cfg', 'ini', 'plist', 'toml', 'yaml', 'yml', 'json')
    'Misc\Logs' = @('log')
    'Misc\Unknown' = @()
}

# ==================== HELPER FUNCTIONS ====================

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Type = 'Info'
    )
    
    $color = switch ($Type) {
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
        'Info' { 'Cyan' }
        default { 'White' }
    }
    
    Write-Host $Message -ForegroundColor $color
}

function Get-FolderChoice {
    Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║        SMART DOWNLOADS ORGANIZER - SELECT FOLDERS          ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    Write-Host "Which folders would you like to organize?`n" -ForegroundColor Yellow
    Write-Host "  [1] Downloads folder → organized in Documents" -ForegroundColor White
    Write-Host "  [2] Documents folder → organized in Documents" -ForegroundColor White
    Write-Host "  [3] Both Downloads and Documents → organized in Documents" -ForegroundColor White
    Write-Host "  [4] Cancel`n" -ForegroundColor Gray
    
    do {
        $choice = Read-Host "Enter your choice (1-4)"
        $validChoice = $choice -match '^[1-4]$'
        if (-not $validChoice) {
            Write-ColorOutput "Invalid choice. Please enter 1, 2, 3, or 4." 'Warning'
        }
    } while (-not $validChoice)
    
    return [int]$choice
}

function Get-UserConsent {
    param([string[]]$Paths)
    
    Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              CONSENT REQUIRED - PLEASE REVIEW              ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    Write-Host "This script will:" -ForegroundColor Yellow
    Write-Host "  • Scan files in: $($Paths -join ', ')" -ForegroundColor White
    Write-Host "  • Organize them into: $env:USERPROFILE\Documents" -ForegroundColor White
    Write-Host "  • Create category subfolders (Images, Video, etc.)" -ForegroundColor White
    Write-Host "  • Detect and remove duplicate files" -ForegroundColor White
    Write-Host "  • Move empty folders to Recycle Bin" -ForegroundColor White
    Write-Host "  • Skip system and application folders`n" -ForegroundColor White
    
    do {
        $response = Read-Host "Do you want to proceed? (Y/N)"
        $response = $response.ToUpper()
        $validResponse = $response -eq 'Y' -or $response -eq 'N'
        if (-not $validResponse) {
            Write-ColorOutput "Please enter Y or N" 'Warning'
        }
    } while (-not $validResponse)
    
    return ($response -eq 'Y')
}

function Test-ShouldSkipFolder {
    param([string]$FolderPath)
    
    $folderName = Split-Path -Leaf $FolderPath
    
    # Only skip if folder name EXACTLY matches known system folders
    # AND the folder is in a system location
    $isSystemLocation = $FolderPath -match '\\Windows\\|\\Program Files|\\ProgramData|\\AppData\\'
    
    if ($isSystemLocation -and ($folderName -in $Script:KnownFoldersToSkip)) {
        return $true
    }
    
    # Always skip if folder name is in critical system list
    $criticalFolders = @('Windows', 'System32', 'Program Files', 'Program Files (x86)', 
                         'ProgramData', '$Recycle.Bin', 'Recovery')
    
    return ($folderName -in $criticalFolders)
}

function Get-FastFileHash {
    param([string]$Path)
    
    try {
        if (Test-Path -LiteralPath $Path) {
            return (Get-FileHash -LiteralPath $Path -Algorithm MD5 -ErrorAction Stop).Hash
        }
    }
    catch {
        # Silent fail for missing files
    }
    return $null
}

function Get-ParallelFileHashes {
    param([System.IO.FileInfo[]]$Files)
    
    $syncHash = [hashtable]::Synchronized(@{})
    $runspacePool = [runspacefactory]::CreateRunspacePool(1, 10)
    $runspacePool.Open()
    $runspaces = @()
    
    foreach ($file in $Files) {
        $powershell = [powershell]::Create()
        $powershell.RunspacePool = $runspacePool
        
        [void]$powershell.AddScript({
            param($FilePath, $HashTable)
            try {
                if (Test-Path -LiteralPath $FilePath) {
                    $hash = (Get-FileHash -LiteralPath $FilePath -Algorithm MD5 -ErrorAction Stop).Hash
                    $HashTable[$FilePath] = $hash
                }
            }
            catch { }
        }).AddArgument($file.FullName).AddArgument($syncHash)
        
        $runspaces += [PSCustomObject]@{
            Pipe = $powershell
            Status = $powershell.BeginInvoke()
        }
    }
    
    foreach ($runspace in $runspaces) {
        $runspace.Pipe.EndInvoke($runspace.Status) | Out-Null
        $runspace.Pipe.Dispose()
    }
    
    $runspacePool.Close()
    $runspacePool.Dispose()
    
    return $syncHash
}

function Get-ExtensionCategory {
    param([string]$Extension)
    
    $ext = $Extension.TrimStart('.').ToLower()
    
    # Build lookup table once
    if (-not $Script:ExtensionLookup) {
        $Script:ExtensionLookup = @{}
        foreach ($category in $Script:Categories.Keys) {
            foreach ($e in $Script:Categories[$category]) {
                # Store first match only to avoid duplicates
                if (-not $Script:ExtensionLookup.ContainsKey($e)) {
                    $Script:ExtensionLookup[$e] = $category
                }
            }
        }
    }
    
    if ($Script:ExtensionLookup.ContainsKey($ext)) {
        return $Script:ExtensionLookup[$ext]
    }
    
    return 'Misc\Unknown'
}

function Resolve-DuplicateFile {
    param(
        [System.IO.FileInfo]$NewFile,
        [System.IO.FileInfo]$ExistingFile
    )
    
    switch ($Script:Config.DuplicatePreference) {
        'Newest' {
            if ($NewFile.LastWriteTime -gt $ExistingFile.LastWriteTime) {
                return $NewFile
            }
            return $ExistingFile
        }
        'Largest' {
            if ($NewFile.Length -gt $ExistingFile.Length) {
                return $NewFile
            }
            return $ExistingFile
        }
        'Smallest' {
            if ($NewFile.Length -lt $ExistingFile.Length) {
                return $NewFile
            }
            return $ExistingFile
        }
        default {
            return $ExistingFile
        }
    }
}

function Move-ToRecycleBin {
    param([string]$Path)
    
    try {
        Add-Type -AssemblyName Microsoft.VisualBasic
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory(
            $Path,
            [Microsoft.VisualBasic.FileIO.UIOption]::OnlyErrorDialogs,
            [Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin
        )
        return $true
    }
    catch {
        return $false
    }
}

function Remove-EmptyFolders {
    param(
        [string]$RootPath,
        [ref]$RemovedCount,
        [string[]]$PreserveCategories = @()
    )
    
    try {
        # Get all folders, deepest first (important!)
        $folders = Get-ChildItem -LiteralPath $RootPath -Directory -Recurse -Force -ErrorAction SilentlyContinue | 
            Where-Object { 
                -not ($_.Attributes -band [System.IO.FileAttributes]::System)
            } |
            Sort-Object -Property @{Expression={$_.FullName.Length}; Descending=$true}
        
        $foldersChecked = 0
        $totalFolders = $folders.Count
        
        foreach ($folder in $folders) {
            $foldersChecked++
            
            # Progress indicator
            if ($foldersChecked % 20 -eq 0) {
                Write-Progress -Activity "Cleaning Empty Folders" -Status "$foldersChecked of $totalFolders" -PercentComplete (($foldersChecked / $totalFolders) * 100)
            }
            
            # Skip system folders
            if (Test-ShouldSkipFolder -FolderPath $folder.FullName) {
                continue
            }
            
            # Skip organized category folders (we want to keep these even if empty)
            $shouldPreserve = $false
            foreach ($category in $PreserveCategories) {
                $categoryPath = Join-Path -Path $RootPath -ChildPath $category
                if ($folder.FullName -eq $categoryPath -or $folder.FullName.StartsWith($categoryPath + '\')) {
                    $shouldPreserve = $true
                    break
                }
            }
            
            if ($shouldPreserve) {
                continue
            }
            
            # Check if truly empty (no files, no subfolders)
            try {
                $items = @(Get-ChildItem -LiteralPath $folder.FullName -Force -ErrorAction Stop)
                
                if ($items.Count -eq 0) {
                    # Attempt to remove
                    if (Move-ToRecycleBin -Path $folder.FullName) {
                        $RemovedCount.Value++
                        Write-Verbose "Removed empty folder: $($folder.FullName)"
                    }
                }
            }
            catch {
                # Silently skip folders we can't access
                Write-Verbose "Could not access folder: $($folder.FullName)"
            }
        }
        
        Write-Progress -Activity "Cleaning Empty Folders" -Completed
    }
    catch {
        Write-ColorOutput "Error during folder cleanup: $_" 'Warning'
    }
}

# ==================== MAIN LOGIC ====================

function Start-FileOrganization {
    param(
        [string[]]$SourcePaths,
        [string]$DestinationPath
    )
    
    $startTime = Get-Date
    $stats = @{
        TotalFiles = 0
        Moved = 0
        Skipped = 0
        Duplicates = 0
        Errors = 0
        EmptyFoldersRemoved = 0
    }
    
    foreach ($sourcePath in $SourcePaths) {
        if (-not (Test-Path -LiteralPath $sourcePath)) {
            Write-ColorOutput "Path not found: $sourcePath" 'Error'
            continue
        }
        
        Write-ColorOutput "`nScanning: $sourcePath" 'Info'
        
        # Get all files recursively
        $allFiles = @()
        try {
            $allFiles = Get-ChildItem -LiteralPath $sourcePath -File -Recurse -ErrorAction SilentlyContinue |
                Where-Object {
                    $file = $_
                    
                    # Skip if in known folder
                    $pathParts = $file.DirectoryName -split '\\'
                    $skipFolder = $false
                    foreach ($part in $pathParts) {
                        if ($part -in $Script:KnownFoldersToSkip) {
                            $skipFolder = $true
                            break
                        }
                    }
                    if ($skipFolder) { return $false }
                    
                    # Skip hidden/system files
                    if (($file.Attributes -band [System.IO.FileAttributes]::Hidden) -or
                        ($file.Attributes -band [System.IO.FileAttributes]::System)) {
                        return $false
                    }
                    
                    # Skip if already in organized folder structure in destination
                    if ($sourcePath -eq $DestinationPath) {
                        $relativePath = $file.DirectoryName.Replace($sourcePath, '').TrimStart('\')
                        foreach ($category in $Script:Categories.Keys) {
                            if ($relativePath.StartsWith($category)) {
                                return $false
                            }
                        }
                    }
                    
                    return $true
                }
        }
        catch {
            Write-ColorOutput "Error scanning files: $_" 'Error'
            continue
        }
        
        $stats.TotalFiles += $allFiles.Count
        
        if ($allFiles.Count -eq 0) {
            Write-ColorOutput "No files to organize in this folder" 'Warning'
            continue
        }
        
        Write-ColorOutput "Found $($allFiles.Count) files to process" 'Success'
        
        # Hash files
        $fileToHash = @{}
        
        if ($Script:Config.EnableDuplicateDetection) {
            Write-ColorOutput "Computing file hashes..." 'Info'
            
            if ($allFiles.Count -gt $Script:Config.ParallelHashingThreshold) {
                $fileToHash = Get-ParallelFileHashes -Files $allFiles
            }
            else {
                $counter = 0
                foreach ($file in $allFiles) {
                    $counter++
                    if ($counter % 10 -eq 0) {
                        $pct = [math]::Round(($counter / $allFiles.Count) * 100, 1)
                        Write-Progress -Activity "Computing Hashes" -Status "$pct% Complete" -PercentComplete $pct
                    }
                    $hash = Get-FastFileHash -Path $file.FullName
                    if ($hash) {
                        $fileToHash[$file.FullName] = $hash
                    }
                }
                Write-Progress -Activity "Computing Hashes" -Completed
            }
        }
        
        # Process files
        Write-ColorOutput "`nOrganizing files..." 'Info'
        $processed = 0
        $hashMap = @{}
        
        foreach ($file in $allFiles) {
            try {
                $processed++
                $percent = [math]::Round(($processed / $allFiles.Count) * 100, 1)
                
                if ($processed % 10 -eq 0 -or $processed -eq $allFiles.Count) {
                    Write-Progress -Activity "Organizing Files" -Status "$percent% Complete" -PercentComplete $percent
                }
                
                # Validate file still exists
                if (-not (Test-Path -LiteralPath $file.FullName)) {
                    $stats.Skipped++
                    continue
                }
                
                $ext = $file.Extension.TrimStart('.').ToLower()
                
                # Skip if no extension or temp file
                if ([string]::IsNullOrEmpty($ext) -or $ext -in $Script:SkipExtensions) {
                    $stats.Skipped++
                    continue
                }
                
                # Check for duplicates
                if ($Script:Config.EnableDuplicateDetection -and $fileToHash.ContainsKey($file.FullName)) {
                    $hash = $fileToHash[$file.FullName]
                    
                    if ($hashMap.ContainsKey($hash)) {
                        $existingPath = $hashMap[$hash]
                        if (Test-Path -LiteralPath $existingPath) {
                            $existingFile = Get-Item -LiteralPath $existingPath
                            $keepFile = Resolve-DuplicateFile -NewFile $file -ExistingFile $existingFile
                            
                            if ($keepFile.FullName -eq $file.FullName) {
                                Remove-Item -LiteralPath $existingFile.FullName -Force -ErrorAction SilentlyContinue
                                $hashMap[$hash] = $file.FullName
                            }
                            else {
                                Remove-Item -LiteralPath $file.FullName -Force -ErrorAction SilentlyContinue
                                $stats.Duplicates++
                                continue
                            }
                        }
                    }
                    else {
                        $hashMap[$hash] = $file.FullName
                    }
                }
                
                # Determine destination
                $category = Get-ExtensionCategory -Extension $ext
                $destFolder = Join-Path -Path $DestinationPath -ChildPath $category
                
                # Skip if already in correct location
                if ($file.DirectoryName -eq $destFolder) {
                    $stats.Skipped++
                    continue
                }
                
                # Create destination folder
                if (-not (Test-Path -LiteralPath $destFolder)) {
                    New-Item -Path $destFolder -ItemType Directory -Force | Out-Null
                }
                
                # Move file
                $destFile = Join-Path -Path $destFolder -ChildPath $file.Name
                
                # Handle name collision
                $counter = 1
                while (Test-Path -LiteralPath $destFile) {
                    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
                    $destFile = Join-Path -Path $destFolder -ChildPath "${baseName}_${counter}$($file.Extension)"
                    $counter++
                }
                
                Move-Item -LiteralPath $file.FullName -Destination $destFile -Force -ErrorAction Stop
                $stats.Moved++
            }
            catch {
                Write-ColorOutput "Error moving $($file.Name): $_" 'Warning'
                $stats.Errors++
            }
        }
        
        Write-Progress -Activity "Organizing Files" -Completed
    }
    
    # ═══ CLEANUP EMPTY FOLDERS (After ALL file operations) ═══
    if ($Script:Config.EnableEmptyFolderCleanup -and $stats.Moved -gt 0) {
        Write-ColorOutput "`nCleaning up empty folders (this may take a moment)..." 'Info'
        
        # Get list of category folders to preserve
        $categoriesToPreserve = $Script:Categories.Keys
        
        $removedCount = 0
        
        # Clean each source path
        foreach ($srcPath in $SourcePaths) {
            if (Test-Path -LiteralPath $srcPath) {
                Write-ColorOutput "  Scanning: $srcPath" 'Info'
                $beforeCount = $removedCount
                
                # If source == destination, preserve organized folders
                if ($srcPath -eq $DestinationPath) {
                    Remove-EmptyFolders -RootPath $srcPath -RemovedCount ([ref]$removedCount) -PreserveCategories $categoriesToPreserve
                }
                else {
                    Remove-EmptyFolders -RootPath $srcPath -RemovedCount ([ref]$removedCount)
                }
                
                $removed = $removedCount - $beforeCount
                if ($removed -gt 0) {
                    Write-ColorOutput "    Removed $removed empty folders" 'Success'
                }
            }
        }
        
        # Second pass cleanup (catches folders that became empty after first pass)
        if ($removedCount -gt 0) {
            Write-ColorOutput "`nRunning second cleanup pass..." 'Info'
            $secondPassCount = 0
            
            foreach ($srcPath in $SourcePaths) {
                if (Test-Path -LiteralPath $srcPath) {
                    $beforeCount = $secondPassCount
                    if ($srcPath -eq $DestinationPath) {
                        Remove-EmptyFolders -RootPath $srcPath -RemovedCount ([ref]$secondPassCount) -PreserveCategories $categoriesToPreserve
                    }
                    else {
                        Remove-EmptyFolders -RootPath $srcPath -RemovedCount ([ref]$secondPassCount)
                    }
                }
            }
            
            if ($secondPassCount -gt 0) {
                $stats.EmptyFoldersRemoved += $secondPassCount
                Write-ColorOutput "  Additional $secondPassCount folders removed" 'Success'
            }
        }
        
        $stats.EmptyFoldersRemoved = $removedCount
        
        if ($stats.EmptyFoldersRemoved -gt 0) {
            Write-ColorOutput "`n✓ Total empty folders removed: $($stats.EmptyFoldersRemoved)" 'Success'
        }
        else {
            Write-ColorOutput "`n• No empty folders found" 'Info'
        }
    }
    
    # Display results
    $elapsed = (Get-Date) - $startTime
    
    Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                    ORGANIZATION COMPLETE                   ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Green
    
    Write-ColorOutput "Total Files Scanned: $($stats.TotalFiles)" 'Info'
    Write-ColorOutput "Files Moved: $($stats.Moved)" 'Success'
    Write-ColorOutput "Duplicates Removed: $($stats.Duplicates)" 'Info'
    Write-ColorOutput "Files Skipped: $($stats.Skipped)" 'Info'
    Write-ColorOutput "Empty Folders Recycled: $($stats.EmptyFoldersRemoved)" 'Info'
    Write-ColorOutput "Errors: $($stats.Errors)" $(if ($stats.Errors -gt 0) { 'Error' } else { 'Success' })
    Write-ColorOutput "`nTime Elapsed: $($elapsed.ToString('mm\:ss'))" 'Info'
    
    $successPercent = if ($stats.TotalFiles -gt 0) {
        [math]::Round((($stats.Moved) / $stats.TotalFiles) * 100, 1)
    } else { 0 }
    Write-ColorOutput "Organization Rate: $successPercent%" 'Success'
}

# ==================== SCRIPT ENTRY POINT ====================

try {
    Clear-Host
    
    # Get folder choice
    $choice = Get-FolderChoice
    
    if ($choice -eq 4) {
        Write-ColorOutput "`nOperation cancelled." 'Warning'
        Start-Sleep -Seconds 2
        exit 0
    }
    
    # Determine paths
    $sourcePaths = @()
    $destinationPath = "$env:USERPROFILE\Documents"
    
    switch ($choice) {
        1 { $sourcePaths += "$env:USERPROFILE\Downloads" }
        2 { $sourcePaths += "$env:USERPROFILE\Documents" }
        3 {
            $sourcePaths += "$env:USERPROFILE\Downloads"
            $sourcePaths += "$env:USERPROFILE\Documents"
        }
    }
    
    # Validate paths
    $validPaths = $sourcePaths | Where-Object { Test-Path $_ }
    
    if ($validPaths.Count -eq 0) {
        Write-ColorOutput "No valid folders found!" 'Error'
        Start-Sleep -Seconds 3
        exit 1
    }
    
    # Get consent
    if (-not (Get-UserConsent -Paths $validPaths)) {
        Write-ColorOutput "`nOperation cancelled." 'Warning'
        Start-Sleep -Seconds 2
        exit 0
    }
    
    # Start organization
    Start-FileOrganization -SourcePaths $validPaths -DestinationPath $destinationPath
    
    Write-Host "`nWindow will close in 3 seconds..." -ForegroundColor Cyan
    Start-Sleep -Seconds 3
    exit 0
}
catch {
    Write-ColorOutput "`nCritical error: $_" 'Error'
    Write-Host "`nWindow will close in 5 seconds..." -ForegroundColor Red
    Start-Sleep -Seconds 5
    exit 1
}
