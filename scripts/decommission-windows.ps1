# Windows Machine Decommission Script
# Removes repos, configs, credentials, and optionally uninstalls apps
#
# Run in PowerShell as Administrator for full cleanup
#
# Usage:
#   .\decommission-windows.ps1              # Interactive, confirm each step
#   .\decommission-windows.ps1 -DryRun      # Preview what would be removed
#   .\decommission-windows.ps1 -All         # Skip confirmations (use with caution!)

param(
    [switch]$DryRun,
    [switch]$All,
    [switch]$Relocated  # Internal flag - set when running from temp location
)

$ErrorActionPreference = "Stop"

# =============================================================================
# LOGGING
# =============================================================================
$LogDir = "$env:TEMP\dotfiles-decommission-logs"
$LogFile = "$LogDir\decommission-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

Start-Transcript -Path $LogFile | Out-Null
Write-Host "Logging to: $LogFile" -ForegroundColor DarkGray
Write-Host "PowerShell version: $($PSVersionTable.PSVersion)" -ForegroundColor DarkGray
Write-Host "Script path: $($MyInvocation.MyCommand.Path)" -ForegroundColor DarkGray
Write-Host "Working directory: $(Get-Location)" -ForegroundColor DarkGray
Write-Host "Relocated flag: $Relocated" -ForegroundColor DarkGray
Write-Host "DryRun flag: $DryRun" -ForegroundColor DarkGray
Write-Host "All flag: $All" -ForegroundColor DarkGray
Write-Host ""

trap {
    Write-Host ""
    Write-Host "ERROR: $_" -ForegroundColor Red
    Write-Host "Line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
    Write-Host "Command: $($_.InvocationInfo.Line.Trim())" -ForegroundColor Red
    Write-Host ""
    Write-Host "Log saved to: $LogFile" -ForegroundColor Yellow
    Stop-Transcript | Out-Null
    break
}

# =============================================================================
# RELOCATE IF RUNNING FROM REPOS
# =============================================================================
# If running from within a repos directory, copy to temp and re-launch
# This allows the script to delete the repos directory

$repoPaths = @(
    "$env:USERPROFILE\repos",
    "$env:USERPROFILE\source\repos"
)

$scriptPath = $MyInvocation.MyCommand.Path
$runningFromRepos = $false

if ($scriptPath -and -not $Relocated) {
    foreach ($repoPath in $repoPaths) {
        if ($scriptPath -like "$repoPath*") {
            $runningFromRepos = $true
            break
        }
    }

    if ($runningFromRepos) {
        Write-Host ""
        Write-Host "Detected: Running from within repos directory" -ForegroundColor Yellow
        Write-Host "Relocating script to temp directory..." -ForegroundColor Yellow

        $tempScript = "$env:TEMP\decommission-windows.ps1"
        Copy-Item -Path $scriptPath -Destination $tempScript -Force

        # Build args to pass through
        $args = @("-Relocated")
        if ($DryRun) { $args += "-DryRun" }
        if ($All) { $args += "-All" }

        Write-Host "Re-launching from: $tempScript" -ForegroundColor Yellow
        Write-Host ""

        # Change to a safe directory before re-launching
        Set-Location $env:USERPROFILE

        # Re-launch and exit this instance
        & powershell -ExecutionPolicy Bypass -File $tempScript @args
        exit $LASTEXITCODE
    }
}

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-Action {
    param([string]$Message)
    Write-Host "    $Message" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Message)
    Write-Host "    [OK] $Message" -ForegroundColor Green
}

function Write-Skip {
    param([string]$Message)
    Write-Host "    [SKIP] $Message" -ForegroundColor DarkGray
}

function Write-DryRun {
    param([string]$Message)
    Write-Host "    [DRY RUN] $Message" -ForegroundColor Magenta
}

function Confirm-Action {
    param([string]$Message)
    if ($All) { return $true }
    if ($DryRun) { return $true }

    Write-Host ""
    $response = Read-Host "    $Message (y/N)"
    return $response -eq 'y' -or $response -eq 'Y'
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Red
Write-Host "  Windows Machine Decommission" -ForegroundColor Red
Write-Host "======================================" -ForegroundColor Red

if ($DryRun) {
    Write-Host ""
    Write-Host "  DRY RUN MODE - No changes will be made" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "This script will remove:" -ForegroundColor White
Write-Host "  - All cloned repositories"
Write-Host "  - Git configuration and credentials"
Write-Host "  - SSH configuration"
Write-Host "  - PowerShell profile symlink"
Write-Host "  - GitHub CLI authentication"
Write-Host "  - Scoop packages and Scoop itself"
Write-Host "  - Winget-installed apps from setup"
Write-Host ""

if (-not $All -and -not $DryRun) {
    $confirm = Read-Host "Continue with decommission? (y/N)"
    if ($confirm -ne 'y' -and $confirm -ne 'Y') {
        Write-Host "Aborted." -ForegroundColor Yellow
        exit 0
    }
}

# =============================================================================
# 1. REPOSITORIES
# =============================================================================
Write-Step "1. Repositories"

# $repoPaths already defined at top of script
foreach ($repoPath in $repoPaths) {
    if (Test-Path $repoPath) {
        Write-Action "Found: $repoPath"

        # List what's there
        $dirs = Get-ChildItem -Path $repoPath -Directory -ErrorAction SilentlyContinue
        if ($dirs) {
            Write-Host "      Contents: $($dirs.Name -join ', ')"
        }

        if (Confirm-Action "Delete $repoPath and all contents?") {
            if ($DryRun) {
                Write-DryRun "Would remove $repoPath"
            } else {
                Remove-Item -Path $repoPath -Recurse -Force
                Write-Success "Removed $repoPath"
            }
        } else {
            Write-Skip "Kept $repoPath"
        }
    }
}

# =============================================================================
# 2. GIT CONFIGURATION
# =============================================================================
Write-Step "2. Git Configuration"

$gitConfigs = @(
    "$env:USERPROFILE\.gitconfig",
    "$env:USERPROFILE\.gitconfig.local"
)

foreach ($config in $gitConfigs) {
    if (Test-Path $config) {
        Write-Action "Found: $config"
        if (Confirm-Action "Delete $config?") {
            if ($DryRun) {
                Write-DryRun "Would remove $config"
            } else {
                Remove-Item -Path $config -Force
                Write-Success "Removed $config"
            }
        } else {
            Write-Skip "Kept $config"
        }
    }
}

# Git credential manager cached credentials
Write-Action "Checking Git credential manager..."
if (Confirm-Action "Clear Git credential manager cache?") {
    if ($DryRun) {
        Write-DryRun "Would run: git credential-manager erase"
    } else {
        # Clear GitHub credentials
        $null = "host=github.com`nprotocol=https" | git credential reject 2>$null
        Write-Success "Cleared cached Git credentials"
    }
}

# =============================================================================
# 3. SSH CONFIGURATION
# =============================================================================
Write-Step "3. SSH Configuration"

$sshPath = "$env:USERPROFILE\.ssh"
if (Test-Path $sshPath) {
    Write-Action "Found: $sshPath"

    $sshFiles = Get-ChildItem -Path $sshPath -ErrorAction SilentlyContinue
    if ($sshFiles) {
        Write-Host "      Contents: $($sshFiles.Name -join ', ')"
    }

    if (Confirm-Action "Delete SSH config directory?") {
        if ($DryRun) {
            Write-DryRun "Would remove $sshPath"
        } else {
            Remove-Item -Path $sshPath -Recurse -Force
            Write-Success "Removed $sshPath"
        }
    } else {
        Write-Skip "Kept $sshPath"
    }
}

# =============================================================================
# 4. POWERSHELL PROFILE
# =============================================================================
Write-Step "4. PowerShell Profile"

if (Test-Path $PROFILE) {
    $profileTarget = Get-Item $PROFILE -ErrorAction SilentlyContinue
    Write-Action "Found: $PROFILE"

    if ($profileTarget.LinkType -eq "SymbolicLink") {
        Write-Host "      (Symlink to: $($profileTarget.Target))"
    }

    if (Confirm-Action "Remove PowerShell profile?") {
        if ($DryRun) {
            Write-DryRun "Would remove $PROFILE"
        } else {
            Remove-Item -Path $PROFILE -Force
            Write-Success "Removed PowerShell profile"
        }
    } else {
        Write-Skip "Kept PowerShell profile"
    }
}

# Starship config
$starshipConfig = "$env:USERPROFILE\.config\starship.toml"
if (Test-Path $starshipConfig) {
    Write-Action "Found: $starshipConfig"
    if (Confirm-Action "Remove Starship config?") {
        if ($DryRun) {
            Write-DryRun "Would remove $starshipConfig"
        } else {
            Remove-Item -Path $starshipConfig -Force
            Write-Success "Removed Starship config"
        }
    }
}

# =============================================================================
# 5. GITHUB CLI
# =============================================================================
Write-Step "5. GitHub CLI Authentication"

if (Get-Command gh -ErrorAction SilentlyContinue) {
    $ghStatus = gh auth status 2>&1
    if ($ghStatus -notmatch "not logged") {
        Write-Action "GitHub CLI is authenticated"
        if (Confirm-Action "Logout from GitHub CLI?") {
            if ($DryRun) {
                Write-DryRun "Would run: gh auth logout"
            } else {
                gh auth logout --hostname github.com 2>$null
                Write-Success "Logged out of GitHub CLI"
            }
        } else {
            Write-Skip "Kept GitHub CLI auth"
        }
    } else {
        Write-Skip "GitHub CLI not authenticated"
    }
} else {
    Write-Skip "GitHub CLI not installed"
}

# =============================================================================
# 6. SCOOP PACKAGES
# =============================================================================
Write-Step "6. Scoop Packages"

if (Get-Command scoop -ErrorAction SilentlyContinue) {
    $scoopApps = scoop list 2>$null | Select-Object -Skip 1
    if ($scoopApps) {
        Write-Action "Installed Scoop packages:"
        scoop list 2>$null | ForEach-Object { Write-Host "      $_" }

        if (Confirm-Action "Uninstall all Scoop packages and Scoop itself?") {
            if ($DryRun) {
                Write-DryRun "Would uninstall all Scoop packages"
                Write-DryRun "Would remove Scoop"
            } else {
                # Uninstall all apps
                scoop list 2>$null | ForEach-Object {
                    $appName = ($_ -split '\s+')[0]
                    if ($appName -and $appName -ne "Name") {
                        scoop uninstall $appName 2>$null
                    }
                }

                # Remove Scoop itself
                $scoopPath = "$env:USERPROFILE\scoop"
                if (Test-Path $scoopPath) {
                    Remove-Item -Path $scoopPath -Recurse -Force
                }

                # Remove from PATH (user environment)
                $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
                $newPath = ($userPath -split ';' | Where-Object { $_ -notlike "*scoop*" }) -join ';'
                [Environment]::SetEnvironmentVariable("Path", $newPath, "User")

                Write-Success "Removed Scoop and all packages"
            }
        } else {
            Write-Skip "Kept Scoop packages"
        }
    }
} else {
    Write-Skip "Scoop not installed"
}

# =============================================================================
# 7. WINGET APPS
# =============================================================================
Write-Step "7. Winget Apps (from setup)"

# Apps that the setup script installs via winget
$wingetApps = @(
    "AgileBits.1Password",
    "Dropbox.Dropbox",
    "Microsoft.WindowsTerminal",
    "Microsoft.VisualStudioCode",
    "JetBrains.Toolbox",
    "ScooterSoftware.BeyondCompare5",
    "Google.Chrome",
    "SlackTechnologies.Slack",
    "Discord.Discord",
    "Zoom.Zoom",
    "Microsoft.PowerToys",
    "AnyDeskSoftwareGmbH.AnyDesk",
    "Valve.Steam",
    "GOG.Galaxy",
    "EpicGames.EpicGamesLauncher",
    "OpenWhisperSystems.Signal",
    "Spotify.Spotify",
    "Plex.PlexMediaServer",
    "Nvidia.GeForceExperience",
    "seerge.g-helper"
)

Write-Action "Checking for installed apps..."
$installedApps = @()

foreach ($app in $wingetApps) {
    $installed = winget list --id $app 2>$null | Select-String $app
    if ($installed) {
        $installedApps += $app
    }
}

if ($installedApps.Count -gt 0) {
    Write-Host "      Found $($installedApps.Count) apps from setup:"
    foreach ($app in $installedApps) {
        Write-Host "        - $app"
    }

    if (Confirm-Action "Uninstall these apps?") {
        foreach ($app in $installedApps) {
            if ($DryRun) {
                Write-DryRun "Would uninstall: $app"
            } else {
                Write-Host "      Uninstalling $app..."
                winget uninstall --id $app --silent 2>$null
            }
        }
        if (-not $DryRun) {
            Write-Success "Uninstalled winget apps"
        }
    } else {
        Write-Skip "Kept winget apps"
    }
} else {
    Write-Skip "No setup-installed winget apps found"
}

# =============================================================================
# 8. CLAUDE CODE
# =============================================================================
Write-Step "8. Claude Code"

$claudeConfig = "$env:USERPROFILE\.claude"
if (Test-Path $claudeConfig) {
    Write-Action "Found Claude config: $claudeConfig"
    if (Confirm-Action "Remove Claude Code config?") {
        if ($DryRun) {
            Write-DryRun "Would remove $claudeConfig"
        } else {
            Remove-Item -Path $claudeConfig -Recurse -Force
            Write-Success "Removed Claude config"
        }
    }
}

# Uninstall Claude Code npm package
if (Get-Command npm -ErrorAction SilentlyContinue) {
    $claudeInstalled = npm list -g @anthropic-ai/claude-code 2>$null
    if ($claudeInstalled -notmatch "empty") {
        Write-Action "Claude Code npm package installed"
        if (Confirm-Action "Uninstall Claude Code?") {
            if ($DryRun) {
                Write-DryRun "Would run: npm uninstall -g @anthropic-ai/claude-code"
            } else {
                npm uninstall -g @anthropic-ai/claude-code 2>$null
                Write-Success "Uninstalled Claude Code"
            }
        }
    }
}

# =============================================================================
# 9. MANUAL STEPS REMINDER
# =============================================================================
Write-Step "9. Manual Steps Required"

Write-Host ""
Write-Host "    The following require manual action:" -ForegroundColor Yellow
Write-Host ""
Write-Host "    - Sign out of 1Password and remove from browser"
Write-Host "    - Sign out of Dropbox (if installed)"
Write-Host "    - Clear browser data (history, passwords, cookies)"
Write-Host "    - Sign out of any JetBrains IDEs"
Write-Host "    - Remove Windows credentials (Control Panel > Credential Manager)"
Write-Host "    - Check for any remaining personal files in Documents/Desktop/Downloads"
Write-Host ""

# =============================================================================
# COMPLETE
# =============================================================================
Write-Host ""
Write-Host "======================================" -ForegroundColor Green
if ($DryRun) {
    Write-Host "  Dry run complete" -ForegroundColor Green
} else {
    Write-Host "  Decommission complete" -ForegroundColor Green
}
Write-Host "======================================" -ForegroundColor Green
Write-Host ""

if (-not $DryRun) {
    Write-Host "Restart your computer to complete cleanup." -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "Log saved to: $LogFile" -ForegroundColor DarkGray
Stop-Transcript | Out-Null
