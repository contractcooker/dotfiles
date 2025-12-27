# Install Windows packages with profile-based selection
#
# Parses Winfile for packages. Base packages install automatically.
# Optional packages filtered by profile with hardware auto-detection.
#
# Profiles:
#   Personal - base, desktop, dev, gaming, personal, browser, communication, utility
#   Work     - base, desktop, dev, browser, communication, utility
#   Server   - base only (CLI tools)
#
# Usage:
#   .\install-packages.ps1                    # Interactive profile selection
#   .\install-packages.ps1 -Profile Personal  # Use specific profile
#   .\install-packages.ps1 -All               # Install everything
#   .\install-packages.ps1 -BaseOnly          # Only base packages

param(
    [ValidateSet("Personal", "Work", "Server")]
    [string]$Profile,

    [switch]$All,
    [switch]$BaseOnly
)

$ErrorActionPreference = "Stop"

# =============================================================================
# Helper Functions
# =============================================================================

function Refresh-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    $scoopShims = "$env:USERPROFILE\scoop\shims"
    if ((Test-Path $scoopShims) -and ($env:Path -notlike "*$scoopShims*")) {
        $env:Path = "$scoopShims;$env:Path"
    }
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

function Write-Skip {
    param([string]$Message)
    Write-Host "    [SKIP] $Message" -ForegroundColor Yellow
}

function Write-Fail {
    param([string]$Message)
    Write-Host "    [FAIL] $Message" -ForegroundColor Red
}

# =============================================================================
# Hardware Detection
# =============================================================================

function Test-NvidiaGpu {
    $gpu = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue |
           Where-Object { $_.Name -match "NVIDIA" }
    return [bool]$gpu
}

function Get-NvidiaGpuName {
    $gpu = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue |
           Where-Object { $_.Name -match "NVIDIA" }
    return $gpu.Name
}

function Test-AsusRogLaptop {
    $system = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
    return ($system.Model -match "ROG") -or
           ($system.Model -match "Zephyrus") -or
           ($system.Model -match "Strix") -or
           ($system.Model -match "TUF Gaming")
}

function Get-AsusModelName {
    $system = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
    return $system.Model
}

# =============================================================================
# Profile Configuration
# =============================================================================

# Categories each profile can access (in addition to base)
$ProfileCategories = @{
    "Personal" = @("desktop", "dev", "gaming", "browser", "communication", "personal", "utility")
    "Work"     = @("desktop", "dev", "browser", "communication", "utility")
    "Server"   = @()  # Base only
}

# =============================================================================
# Main Script
# =============================================================================

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DotfilesPath = Split-Path -Parent $ScriptDir
$Winfile = Join-Path $DotfilesPath "Winfile"

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  Package Installation" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

# =============================================================================
# Step 1: Install Scoop
# =============================================================================
Write-Step "Checking Scoop"

if (Get-Command scoop -ErrorAction SilentlyContinue) {
    Write-Success "Scoop installed"
} else {
    Write-Host "    Installing Scoop..."
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
    Refresh-Path
    Write-Success "Scoop installed"
}

# Add extras bucket
$buckets = scoop bucket list 2>$null
if ($buckets -notcontains "extras") {
    Write-Host "    Adding extras bucket..."
    scoop bucket add extras
    Write-Success "Extras bucket added"
}

# =============================================================================
# Step 2: Install gum
# =============================================================================
Write-Step "Checking gum"

if ((Get-Command gum -ErrorAction SilentlyContinue) -or (Get-Command gm -ErrorAction SilentlyContinue)) {
    Write-Success "gum installed"
} else {
    Write-Host "    Installing gum..."
    scoop install gum
    Refresh-Path
    Write-Success "gum installed"
}

# Determine gum command path
$gumCmd = $null
$gumExe = "$env:USERPROFILE\scoop\shims\gum.exe"
$gmExe = "$env:USERPROFILE\scoop\shims\gm.exe"
if (Test-Path $gumExe) {
    $gumCmd = $gumExe
} elseif (Test-Path $gmExe) {
    $gumCmd = $gmExe
}

# =============================================================================
# Step 3: Profile Selection
# =============================================================================
Write-Step "Profile Selection"

if (-not $Profile -and -not $All -and -not $CoreOnly) {
    if ($gumCmd) {
        Write-Host ""
        $profileOptions = @(
            "Personal - Full setup with personal apps, gaming optional"
            "Work - Work-focused, no gaming or personal apps"
            "Server - CLI only, core packages"
        )
        $selected = $profileOptions | & $gumCmd choose --header "Select machine profile:"
        if ($selected) {
            $Profile = $selected.Split(" ")[0]
        } else {
            Write-Host "    No profile selected, defaulting to Personal" -ForegroundColor Yellow
            $Profile = "Personal"
        }
    } else {
        Write-Host "    gum not available, defaulting to Personal profile" -ForegroundColor Yellow
        $Profile = "Personal"
    }
}

if ($Profile) {
    Write-Success "Profile: $Profile"
}

# =============================================================================
# Step 4: Parse Winfile
# =============================================================================
Write-Step "Parsing Winfile"

if (-not (Test-Path $Winfile)) {
    Write-Fail "Winfile not found at $Winfile"
    exit 1
}

$BaseScoop = @()
$BaseWinget = @()
$OptionalScoop = @{}   # name -> "category|description"
$OptionalWinget = @{}  # name -> "category|description"

Get-Content $Winfile | ForEach-Object {
    $line = $_.Trim()

    if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith("#")) {
        return
    }

    if ($line -match '^scoop\s+"([^"]+)"\s*#\s*\[([^\]]+)\]\s*(.*)$') {
        $name = $Matches[1]
        $tag = $Matches[2]
        $desc = $Matches[3]

        if ($tag -eq "base") {
            $script:BaseScoop += $name
        } else {
            $script:OptionalScoop[$name] = "${tag}|${desc}"
        }
    }

    if ($line -match '^winget\s+"([^"]+)"\s*#\s*\[([^\]]+)\]\s*(.*)$') {
        $name = $Matches[1]
        $tag = $Matches[2]
        $desc = $Matches[3]

        if ($tag -eq "base") {
            $script:BaseWinget += $name
        } else {
            $script:OptionalWinget[$name] = "${tag}|${desc}"
        }
    }
}

$baseCount = $BaseScoop.Count + $BaseWinget.Count
$optionalCount = $OptionalScoop.Count + $OptionalWinget.Count
Write-Success "Found $baseCount base, $optionalCount optional packages"

# =============================================================================
# Step 5: Install packages
# =============================================================================

function Install-ScoopPackage {
    param([string]$Package)

    $installed = scoop list 2>$null | Select-String "^\s*$Package\s"
    if ($installed) {
        Write-Success "$Package (scoop)"
        return $true
    } else {
        Write-Host "    Installing $Package..."
        scoop install $Package
        if ($LASTEXITCODE -eq 0) {
            Write-Success "$Package (scoop)"
            return $true
        } else {
            Write-Fail "$Package (scoop)"
            return $false
        }
    }
}

function Install-WingetPackage {
    param([string]$Package)

    $installed = winget list --id $Package 2>$null | Select-String $Package
    if ($installed) {
        Write-Success "$Package (winget)"
        return $true
    } else {
        Write-Host "    Installing $Package..."
        winget install --id $Package --accept-source-agreements --accept-package-agreements --silent
        if ($LASTEXITCODE -eq 0) {
            Write-Success "$Package (winget)"
            return $true
        } else {
            Write-Fail "$Package (winget)"
            return $false
        }
    }
}

function Get-InstalledScoop {
    param([string]$Package)
    $installed = scoop list 2>$null | Select-String "^\s*$Package\s"
    return [bool]$installed
}

function Get-InstalledWinget {
    param([string]$Package)
    $installed = winget list --id $Package 2>$null | Select-String $Package
    return [bool]$installed
}

# -----------------------------------------------------------------------------
# Base packages (always installed)
# -----------------------------------------------------------------------------
Write-Step "Installing base packages"

foreach ($pkg in $BaseScoop) {
    Install-ScoopPackage $pkg | Out-Null
}

foreach ($pkg in $BaseWinget) {
    Install-WingetPackage $pkg | Out-Null
}

# Exit early if BaseOnly
if ($BaseOnly) {
    Write-Host ""
    Write-Success "Base packages installed (-BaseOnly)"
    exit 0
}

# Exit early for Server profile
if ($Profile -eq "Server") {
    Write-Host ""
    Write-Success "Server profile complete (base only)"
    exit 0
}

# =============================================================================
# Step 6: Hardware Detection + Prompts
# =============================================================================
Write-Step "Hardware Detection"

$HardwarePrompts = @()

if (Test-NvidiaGpu) {
    $gpuName = Get-NvidiaGpuName
    Write-Success "NVIDIA GPU detected: $gpuName"
    $HardwarePrompts += @{
        Category = "nvidia"
        Prompt = "Install GeForce Experience for driver updates?"
    }
} else {
    Write-Skip "No NVIDIA GPU detected"
}

if (Test-AsusRogLaptop) {
    $modelName = Get-AsusModelName
    Write-Success "ASUS ROG laptop detected: $modelName"
    # Skip ASUS prompts for Work profile
    if ($Profile -ne "Work") {
        $HardwarePrompts += @{
            Category = "asus"
            Prompt = "Install G-Helper (replaces Armoury Crate)?"
        }
    }
} else {
    Write-Skip "No ASUS ROG laptop detected"
}

# Prompt for each detected hardware
$HardwareCategories = @()
foreach ($hw in $HardwarePrompts) {
    if ($gumCmd) {
        $confirm = "Yes", "No" | & $gumCmd choose --header $hw.Prompt
        if ($confirm -eq "Yes") {
            $HardwareCategories += $hw.Category
        }
    } else {
        $reply = Read-Host "    $($hw.Prompt) [Y/n]"
        if ($reply -notmatch "^[Nn]") {
            $HardwareCategories += $hw.Category
        }
    }
}

# =============================================================================
# Step 7: Build allowed categories
# =============================================================================
Write-Step "Building package list"

$AllowedCategories = @()

# Add profile categories
if ($Profile -and $ProfileCategories.ContainsKey($Profile)) {
    $AllowedCategories = $ProfileCategories[$Profile]
}

# Add hardware categories user approved
$AllowedCategories += $HardwareCategories

Write-Success "Categories: $($AllowedCategories -join ', ')"

# =============================================================================
# Step 8: Optional packages
# =============================================================================
Write-Step "Optional packages"

# Filter packages to only allowed categories
$FilteredScoop = @{}
$FilteredWinget = @{}

foreach ($pkg in $OptionalScoop.Keys) {
    $data = $OptionalScoop[$pkg]
    $category = $data.Split("|")[0]
    if ($All -or $category -in $AllowedCategories) {
        $FilteredScoop[$pkg] = $data
    }
}

foreach ($pkg in $OptionalWinget.Keys) {
    $data = $OptionalWinget[$pkg]
    $category = $data.Split("|")[0]
    if ($All -or $category -in $AllowedCategories) {
        $FilteredWinget[$pkg] = $data
    }
}

Write-Success "Available: $($FilteredScoop.Count) scoop, $($FilteredWinget.Count) winget packages"

if ($All) {
    Write-Host "    Installing all packages (-All)"
    Write-Host ""

    foreach ($pkg in $FilteredScoop.Keys) {
        Install-ScoopPackage $pkg | Out-Null
    }

    foreach ($pkg in $FilteredWinget.Keys) {
        Install-WingetPackage $pkg | Out-Null
    }
} else {
    if (-not $gumCmd) {
        Write-Skip "gum not available, skipping interactive selection"
        Write-Host "    Run with -All to install all packages" -ForegroundColor DarkGray
    } else {
        Refresh-Path

        # Scoop packages
        $scoopOptions = @()
        foreach ($pkg in $FilteredScoop.Keys | Sort-Object) {
            if (-not (Get-InstalledScoop $pkg)) {
                $data = $FilteredScoop[$pkg]
                $category = $data.Split("|")[0]
                $desc = $data.Split("|")[1]
                $scoopOptions += "$pkg - [$category] $desc"
            }
        }

        if ($scoopOptions.Count -gt 0) {
            Write-Host ""
            Write-Host "    Select Scoop packages (space=toggle, enter=confirm):" -ForegroundColor Cyan
            Write-Host ""
            $selected = $scoopOptions | Sort-Object | & $gumCmd choose --no-limit --header "Scoop packages:"

            if ($selected) {
                $selected | ForEach-Object {
                    $pkg = $_.Split(" ")[0]
                    Install-ScoopPackage $pkg | Out-Null
                }
            }
        } else {
            Write-Host "    All Scoop packages already installed"
        }

        # Winget packages
        $wingetOptions = @()
        foreach ($pkg in $FilteredWinget.Keys | Sort-Object) {
            if (-not (Get-InstalledWinget $pkg)) {
                $data = $FilteredWinget[$pkg]
                $category = $data.Split("|")[0]
                $desc = $data.Split("|")[1]
                $wingetOptions += "$pkg - [$category] $desc"
            }
        }

        if ($wingetOptions.Count -gt 0) {
            Write-Host ""
            Write-Host "    Select Winget packages (space=toggle, enter=confirm):" -ForegroundColor Cyan
            Write-Host ""
            $selected = $wingetOptions | Sort-Object | & $gumCmd choose --no-limit --header "Winget packages:"

            if ($selected) {
                $selected | ForEach-Object {
                    $pkg = $_.Split(" ")[0]
                    Install-WingetPackage $pkg | Out-Null
                }
            }
        } else {
            Write-Host "    All Winget packages already installed"
        }
    }
}

Write-Host ""
Write-Step "Package installation complete"
Write-Host ""
