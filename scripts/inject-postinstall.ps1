# Inject Post-Install Script into MicroWin Image
# Run in PowerShell as Administrator
#
# This script modifies a MicroWin install.wim to run setup-windows.ps1
# automatically on first login.
#
# Usage:
#   .\inject-postinstall.ps1 -WimPath "E:\sources\install.wim"
#   .\inject-postinstall.ps1 -IsoPath "C:\ISOs\Win11-MicroWin.iso" -OutputIso "C:\ISOs\Win11-MicroWin-Custom.iso"
#
# For Ventoy users: Point -WimPath directly at the WIM inside your extracted ISO folder

param(
    [Parameter(Mandatory=$false)]
    [string]$WimPath,

    [Parameter(Mandatory=$false)]
    [string]$IsoPath,

    [Parameter(Mandatory=$false)]
    [string]$OutputIso,

    [Parameter(Mandatory=$false)]
    [string]$MountDir = "$env:TEMP\MicroWinMount",

    [Parameter(Mandatory=$false)]
    [int]$ImageIndex = 1,

    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# Validate parameters
if (-not $WimPath -and -not $IsoPath) {
    Write-Host "Error: Specify either -WimPath or -IsoPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Cyan
    Write-Host "  # Modify WIM directly (for Ventoy)"
    Write-Host "  .\inject-postinstall.ps1 -WimPath 'E:\Win11\sources\install.wim'"
    Write-Host ""
    Write-Host "  # Create new ISO"
    Write-Host "  .\inject-postinstall.ps1 -IsoPath 'C:\ISOs\original.iso' -OutputIso 'C:\ISOs\custom.iso'"
    exit 1
}

if ($IsoPath -and -not $OutputIso) {
    Write-Host "Error: -OutputIso required when using -IsoPath" -ForegroundColor Red
    exit 1
}

# Check for admin privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Error: This script requires Administrator privileges" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "    [OK] $Message" -ForegroundColor Green
}

# The script to inject - calls our setup on first login
$PostInstallScript = @'

# =============================================================================
# Dotfiles Post-Install (injected by inject-postinstall.ps1)
# =============================================================================
Write-Host "Starting dotfiles setup..." -ForegroundColor Cyan

try {
    irm https://raw.githubusercontent.com/contractcooker/dotfiles/main/scripts/setup-windows.ps1 | iex
} catch {
    Write-Host "Dotfiles setup failed: $_" -ForegroundColor Red
    Write-Host "Run manually: irm https://raw.githubusercontent.com/contractcooker/dotfiles/main/scripts/setup-windows.ps1 | iex" -ForegroundColor Yellow
}
# =============================================================================
'@

# =============================================================================
# MAIN
# =============================================================================

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  MicroWin Post-Install Injector" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

$isoExtractDir = $null
$wimToModify = $WimPath

# If working with ISO, extract it first
if ($IsoPath) {
    Write-Step "Extracting ISO"

    if (-not (Test-Path $IsoPath)) {
        Write-Host "Error: ISO not found: $IsoPath" -ForegroundColor Red
        exit 1
    }

    $isoExtractDir = "$env:TEMP\MicroWinISO"
    if (Test-Path $isoExtractDir) {
        Remove-Item $isoExtractDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $isoExtractDir -Force | Out-Null

    # Mount ISO and copy contents
    $isoMount = Mount-DiskImage -ImagePath $IsoPath -PassThru
    $driveLetter = ($isoMount | Get-Volume).DriveLetter

    Write-Host "    Copying ISO contents to $isoExtractDir..."
    robocopy "${driveLetter}:\" $isoExtractDir /E /NFL /NDL /NJH /NJS /NC /NS /NP | Out-Null

    Dismount-DiskImage -ImagePath $IsoPath | Out-Null
    Write-Success "ISO extracted"

    $wimToModify = "$isoExtractDir\sources\install.wim"

    # Remove read-only attribute
    attrib -R $wimToModify
}

# Validate WIM exists
if (-not (Test-Path $wimToModify)) {
    Write-Host "Error: WIM not found: $wimToModify" -ForegroundColor Red
    exit 1
}

# Check if WIM is read-only
$wimItem = Get-Item $wimToModify
if ($wimItem.IsReadOnly) {
    Write-Host "Error: WIM is read-only. Copy it to a writable location first." -ForegroundColor Red
    exit 1
}

Write-Step "Mounting WIM image"
Write-Host "    WIM: $wimToModify"
Write-Host "    Mount point: $MountDir"

if (Test-Path $MountDir) {
    # Check if already mounted
    $mounted = dism /Get-MountedWimInfo 2>$null | Select-String $MountDir
    if ($mounted) {
        Write-Host "    Unmounting existing mount..."
        dism /Unmount-Wim /MountDir:$MountDir /Discard | Out-Null
    }
    Remove-Item $MountDir -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path $MountDir -Force | Out-Null

if ($DryRun) {
    Write-Host "    [DRY RUN] Would mount: $wimToModify" -ForegroundColor Yellow
} else {
    dism /Mount-Wim /WimFile:$wimToModify /Index:$ImageIndex /MountDir:$MountDir
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to mount WIM" -ForegroundColor Red
        exit 1
    }
    Write-Success "WIM mounted"
}

Write-Step "Injecting post-install script"

$firstStartupPath = "$MountDir\Windows\FirstStartup.ps1"

if ($DryRun) {
    Write-Host "    [DRY RUN] Would modify: $firstStartupPath" -ForegroundColor Yellow
    Write-Host "    Script to append:" -ForegroundColor Yellow
    Write-Host $PostInstallScript -ForegroundColor DarkGray
} else {
    if (Test-Path $firstStartupPath) {
        # Append to existing FirstStartup.ps1
        Write-Host "    Appending to existing FirstStartup.ps1..."
        Add-Content -Path $firstStartupPath -Value $PostInstallScript
    } else {
        # Create new FirstStartup.ps1
        Write-Host "    Creating FirstStartup.ps1..."

        # Create full script with logging
        $fullScript = @'
# FirstStartup.ps1 - Created by inject-postinstall.ps1
Start-Transcript -Path "C:\Windows\LogFirstRun.txt" -Append

Write-Host "FirstStartup.ps1 running..." -ForegroundColor Cyan

'@ + $PostInstallScript + @'

Stop-Transcript
'@
        Set-Content -Path $firstStartupPath -Value $fullScript

        # Also need to ensure unattend.xml triggers it
        # MicroWin should have already set this up, but if not, warn the user
        $unattendPath = "$MountDir\Windows\Panther\unattend.xml"
        if (-not (Test-Path $unattendPath)) {
            Write-Host "    Warning: unattend.xml not found. FirstStartup.ps1 may not auto-run." -ForegroundColor Yellow
            Write-Host "    If MicroWin created this image, it should already be configured." -ForegroundColor Yellow
        }
    }
    Write-Success "Post-install script injected"
}

Write-Step "Unmounting and committing changes"

if ($DryRun) {
    Write-Host "    [DRY RUN] Would unmount and commit" -ForegroundColor Yellow
} else {
    dism /Unmount-Wim /MountDir:$MountDir /Commit
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to unmount WIM" -ForegroundColor Red
        Write-Host "Try: dism /Unmount-Wim /MountDir:$MountDir /Discard" -ForegroundColor Yellow
        exit 1
    }
    Write-Success "Changes committed"
}

# If working with ISO, rebuild it
if ($IsoPath -and -not $DryRun) {
    Write-Step "Rebuilding ISO"

    # Find oscdimg.exe
    $oscdimg = $null
    $possiblePaths = @(
        "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe",
        "$env:TEMP\oscdimg.exe",
        ".\oscdimg.exe"
    )

    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $oscdimg = $path
            break
        }
    }

    if (-not $oscdimg) {
        Write-Host "Error: oscdimg.exe not found" -ForegroundColor Red
        Write-Host "Download from MicroWin (it offers to download it) or install Windows ADK" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Your modified files are at: $isoExtractDir" -ForegroundColor Cyan
        Write-Host "You can manually create the ISO with:" -ForegroundColor Cyan
        Write-Host "  oscdimg -m -o -u2 -udfver102 -bootdata:2#p0,e,b$isoExtractDir\boot\etfsboot.com#pEF,e,b$isoExtractDir\efi\microsoft\boot\efisys.bin $isoExtractDir $OutputIso"
        exit 1
    }

    Write-Host "    Using: $oscdimg"
    Write-Host "    Creating: $OutputIso"

    $bootData = "2#p0,e,b$isoExtractDir\boot\etfsboot.com#pEF,e,b$isoExtractDir\efi\microsoft\boot\efisys.bin"
    & $oscdimg -m -o -u2 -udfver102 -bootdata:$bootData $isoExtractDir $OutputIso

    if ($LASTEXITCODE -eq 0) {
        Write-Success "ISO created: $OutputIso"

        # Cleanup
        Write-Host "    Cleaning up temp files..."
        Remove-Item $isoExtractDir -Recurse -Force -ErrorAction SilentlyContinue
    } else {
        Write-Host "Error: Failed to create ISO" -ForegroundColor Red
        Write-Host "Modified files remain at: $isoExtractDir" -ForegroundColor Yellow
        exit 1
    }
}

# Cleanup mount directory
Remove-Item $MountDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "======================================" -ForegroundColor Green
Write-Host "  Done!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""

if ($WimPath -and -not $IsoPath) {
    Write-Host "Modified WIM: $WimPath" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "On first Windows login, setup-windows.ps1 will run automatically." -ForegroundColor White
}

if ($OutputIso) {
    Write-Host "Custom ISO: $OutputIso" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Copy to Ventoy USB or burn to disk." -ForegroundColor White
}
