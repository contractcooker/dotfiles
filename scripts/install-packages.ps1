# Install Windows packages with interactive selection
#
# Parses Winfile for packages tagged with [core] or [category].
# Core packages install automatically, optional packages shown in picker.
#
# Usage:
#   .\install-packages.ps1              # Interactive mode
#   .\install-packages.ps1 -All         # Install everything
#   .\install-packages.ps1 -CoreOnly    # Only core packages

param(
    [switch]$All,
    [switch]$CoreOnly
)

$ErrorActionPreference = "Stop"

# Refresh PATH from registry (picks up changes from scoop/winget installs)
function Refresh-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DotfilesPath = Split-Path -Parent $ScriptDir
$Winfile = Join-Path $DotfilesPath "Winfile"

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

    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    Write-Success "Scoop installed"
}

# Add extras bucket for more packages
$buckets = scoop bucket list 2>$null
if ($buckets -notcontains "extras") {
    Write-Host "    Adding extras bucket..."
    scoop bucket add extras
    Write-Success "Extras bucket added"
}

# =============================================================================
# Step 2: Parse Winfile
# =============================================================================
Write-Step "Parsing Winfile"

if (-not (Test-Path $Winfile)) {
    Write-Fail "Winfile not found at $Winfile"
    exit 1
}

# Package storage
$CoreScoop = @()
$CoreWinget = @()
$OptionalScoop = @{}   # name -> "category|description"
$OptionalWinget = @{}  # name -> "category|description"

Get-Content $Winfile | ForEach-Object {
    $line = $_.Trim()

    # Skip empty lines and comments
    if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith("#")) {
        return
    }

    # Match: scoop "name" # [tag] description
    if ($line -match '^scoop\s+"([^"]+)"\s*#\s*\[([^\]]+)\]\s*(.*)$') {
        $name = $Matches[1]
        $tag = $Matches[2]
        $desc = $Matches[3]

        if ($tag -eq "core") {
            $script:CoreScoop += $name
        } else {
            $script:OptionalScoop[$name] = "${tag}|${desc}"
        }
    }

    # Match: winget "name" # [tag] description
    if ($line -match '^winget\s+"([^"]+)"\s*#\s*\[([^\]]+)\]\s*(.*)$') {
        $name = $Matches[1]
        $tag = $Matches[2]
        $desc = $Matches[3]

        if ($tag -eq "core") {
            $script:CoreWinget += $name
        } else {
            $script:OptionalWinget[$name] = "${tag}|${desc}"
        }
    }
}

Write-Success "Found $($CoreScoop.Count) core scoop, $($CoreWinget.Count) core winget"
Write-Success "Found $($OptionalScoop.Count) optional scoop, $($OptionalWinget.Count) optional winget"

# =============================================================================
# Step 3: Install gum (needed for interactive UI)
# =============================================================================
Write-Step "Checking gum"

if (Get-Command gum -ErrorAction SilentlyContinue) {
    Write-Success "gum installed"
} else {
    Write-Host "    Installing gum..."
    scoop install gum
    Refresh-Path
    Write-Success "gum installed"
}

# =============================================================================
# Step 4: Install core packages
# =============================================================================
Write-Step "Installing core packages"

function Install-ScoopPackage {
    param([string]$Package)

    $installed = scoop list 2>$null | Select-String "^\s*$Package\s"
    if ($installed) {
        Write-Success "$Package (scoop)"
    } else {
        Write-Host "    Installing $Package..."
        scoop install $Package
        if ($LASTEXITCODE -eq 0) {
            Write-Success "$Package (scoop)"
        } else {
            Write-Fail "$Package (scoop)"
        }
    }
}

function Install-WingetPackage {
    param([string]$Package)

    $installed = winget list --id $Package 2>$null | Select-String $Package
    if ($installed) {
        Write-Success "$Package (winget)"
    } else {
        Write-Host "    Installing $Package..."
        winget install --id $Package --accept-source-agreements --accept-package-agreements --silent
        if ($LASTEXITCODE -eq 0) {
            Write-Success "$Package (winget)"
        } else {
            Write-Fail "$Package (winget)"
        }
    }
}

foreach ($pkg in $CoreScoop) {
    Install-ScoopPackage $pkg
}

foreach ($pkg in $CoreWinget) {
    Install-WingetPackage $pkg
}

if ($CoreOnly) {
    Write-Host ""
    Write-Success "Core packages installed (-CoreOnly)"
    exit 0
}

# =============================================================================
# Step 5: Optional packages
# =============================================================================
Write-Step "Optional packages"

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

if ($All) {
    Write-Host "    Installing all optional packages (-All)"
    Write-Host ""

    foreach ($pkg in $OptionalScoop.Keys) {
        Install-ScoopPackage $pkg
    }

    foreach ($pkg in $OptionalWinget.Keys) {
        Install-WingetPackage $pkg
    }
} else {
    # Refresh PATH to ensure gum is available (especially when run via iex)
    Refresh-Path

    # Interactive mode with gum

    # Build scoop options (uninstalled only)
    Write-Host ""
    Write-Host "    Select Scoop packages to install (space=toggle, enter=confirm):" -ForegroundColor Cyan
    Write-Host ""

    $scoopOptions = @()
    foreach ($pkg in $OptionalScoop.Keys | Sort-Object) {
        if (-not (Get-InstalledScoop $pkg)) {
            $data = $OptionalScoop[$pkg]
            $category = $data.Split("|")[0]
            $desc = $data.Split("|")[1]
            $scoopOptions += "$pkg - [$category] $desc"
        }
    }

    if ($scoopOptions.Count -gt 0) {
        $selected = $scoopOptions | Sort-Object | gum choose --no-limit --header "Scoop packages:"

        if ($selected) {
            $selected | ForEach-Object {
                $pkg = $_.Split(" ")[0]
                Install-ScoopPackage $pkg
            }
        }
    } else {
        Write-Host "    All Scoop packages already installed"
    }

    # Build winget options (uninstalled only)
    Write-Host ""
    Write-Host "    Select Winget packages to install (space=toggle, enter=confirm):" -ForegroundColor Cyan
    Write-Host ""

    $wingetOptions = @()
    foreach ($pkg in $OptionalWinget.Keys | Sort-Object) {
        if (-not (Get-InstalledWinget $pkg)) {
            $data = $OptionalWinget[$pkg]
            $category = $data.Split("|")[0]
            $desc = $data.Split("|")[1]
            $wingetOptions += "$pkg - [$category] $desc"
        }
    }

    if ($wingetOptions.Count -gt 0) {
        $selected = $wingetOptions | Sort-Object | gum choose --no-limit --header "Winget packages:"

        if ($selected) {
            $selected | ForEach-Object {
                $pkg = $_.Split(" ")[0]
                Install-WingetPackage $pkg
            }
        }
    } else {
        Write-Host "    All Winget packages already installed"
    }
}

Write-Host ""
Write-Step "Package installation complete"
Write-Host ""
