# Configure Windows system preferences
#
# Three sections:
#   1. Dev Settings - Recommended for development workflows
#   2. Debloat - Disable telemetry and unnecessary features (complements winutil)
#   3. Personal Settings - Subjective preferences (optional)
#
# Usage:
#   .\configure-windows.ps1              # Interactive mode
#   .\configure-windows.ps1 -All         # Apply all settings
#   .\configure-windows.ps1 -DevOnly     # Only dev settings
#   .\configure-windows.ps1 -Debloat     # Only debloat settings

param(
    [switch]$All,
    [switch]$DevOnly,
    [switch]$DebloatOnly
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-Setting {
    param([string]$Message)
    Write-Host "      [OK] $Message" -ForegroundColor Green
}

function Write-SettingWarn {
    param([string]$Message)
    Write-Host "      [WARN] $Message" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  Windows System Preferences" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

# =============================================================================
# DEV SETTINGS
# =============================================================================

function Apply-DevSettings {
    Write-Step "Applying Dev Settings"

    # -------------------------------------------------------------------------
    # File Explorer
    # -------------------------------------------------------------------------
    Write-Host "    File Explorer:" -ForegroundColor White

    # Show file extensions
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0
    Write-Setting "Show file extensions"

    # Show hidden files
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1
    Write-Setting "Show hidden files"

    # Show full path in title bar
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState" -Name "FullPath" -Value 1
    Write-Setting "Show full path in title bar"

    # Expand to current folder in nav pane
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "NavPaneExpandToCurrentFolder" -Value 1
    Write-Setting "Expand nav pane to current folder"

    # -------------------------------------------------------------------------
    # Git Configuration
    # -------------------------------------------------------------------------
    Write-Host "    Git:" -ForegroundColor White

    # CRLF handling
    git config --global core.autocrlf true
    Write-Setting "core.autocrlf = true"

    # Use Windows OpenSSH for 1Password compatibility
    git config --global core.sshCommand "C:/Windows/System32/OpenSSH/ssh.exe"
    Write-Setting "core.sshCommand = Windows OpenSSH"

    # Default branch
    git config --global init.defaultBranch main
    Write-Setting "init.defaultBranch = main"

    # -------------------------------------------------------------------------
    # Power Settings (for 3080 Ti)
    # -------------------------------------------------------------------------
    Write-Host "    Power:" -ForegroundColor White

    # Set to High Performance
    try {
        $highPerf = powercfg -list | Select-String "High performance" | ForEach-Object { ($_ -split "\s+")[3] }
        if ($highPerf) {
            powercfg -setactive $highPerf
            Write-Setting "High Performance power plan"
        } else {
            Write-SettingWarn "High Performance plan not found"
        }
    } catch {
        Write-SettingWarn "Could not set power plan"
    }

    # Disable USB selective suspend (prevents USB disconnects)
    powercfg -change -usbselectivesuspend-ac off 2>$null
    powercfg -change -usbselectivesuspend-dc off 2>$null
    Write-Setting "Disabled USB selective suspend"

    # -------------------------------------------------------------------------
    # Windows Search
    # -------------------------------------------------------------------------
    Write-Host "    Search Indexing:" -ForegroundColor White

    # Exclude repos folder from indexing
    $reposPath = "$env:USERPROFILE\repos"
    if (Test-Path $reposPath) {
        $indexerPath = "HKCU:\Software\Microsoft\Windows Search\CrawlScopeManager\Windows\SystemIndex\WorkingSet"
        if (-not (Test-Path $indexerPath)) {
            New-Item -Path $indexerPath -Force | Out-Null
        }
        Write-Setting "Note: Exclude ~/repos from indexing via Settings > Privacy > Searching Windows"
    }

    # -------------------------------------------------------------------------
    # Developer Mode
    # -------------------------------------------------------------------------
    Write-Host "    Developer Mode:" -ForegroundColor White

    try {
        $devMode = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowDevelopmentWithoutDevLicense" -ErrorAction SilentlyContinue
        if ($devMode.AllowDevelopmentWithoutDevLicense -eq 1) {
            Write-Setting "Developer Mode enabled"
        } else {
            Write-SettingWarn "Enable Developer Mode: Settings > Privacy & security > For developers"
        }
    } catch {
        Write-SettingWarn "Enable Developer Mode: Settings > Privacy & security > For developers"
    }
}

# =============================================================================
# DEBLOAT SETTINGS
# =============================================================================

function Apply-DebloatSettings {
    Write-Step "Applying Debloat Settings (complements winutil)"

    # -------------------------------------------------------------------------
    # Telemetry
    # -------------------------------------------------------------------------
    Write-Host "    Telemetry:" -ForegroundColor White

    # Disable telemetry
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Write-Setting "Disable telemetry (policy)"

    # Disable advertising ID
    $advertisingPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
    if (-not (Test-Path $advertisingPath)) {
        New-Item -Path $advertisingPath -Force | Out-Null
    }
    Set-ItemProperty -Path $advertisingPath -Name "Enabled" -Value 0 -Type DWord
    Write-Setting "Disable advertising ID"

    # Disable feedback
    $feedbackPath = "HKCU:\Software\Microsoft\Siuf\Rules"
    if (-not (Test-Path $feedbackPath)) {
        New-Item -Path $feedbackPath -Force | Out-Null
    }
    Set-ItemProperty -Path $feedbackPath -Name "NumberOfSIUFInPeriod" -Value 0 -Type DWord
    Write-Setting "Disable feedback requests"

    # -------------------------------------------------------------------------
    # Cortana
    # -------------------------------------------------------------------------
    Write-Host "    Cortana:" -ForegroundColor White

    $cortanaPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
    Set-ItemProperty -Path $cortanaPath -Name "CortanaConsent" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $cortanaPath -Name "BingSearchEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Setting "Disable Cortana and Bing search"

    # -------------------------------------------------------------------------
    # Suggested Apps / Ads
    # -------------------------------------------------------------------------
    Write-Host "    Suggested Apps:" -ForegroundColor White

    $contentDeliveryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    if (Test-Path $contentDeliveryPath) {
        Set-ItemProperty -Path $contentDeliveryPath -Name "SystemPaneSuggestionsEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $contentDeliveryPath -Name "SubscribedContent-338388Enabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $contentDeliveryPath -Name "SubscribedContent-338389Enabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $contentDeliveryPath -Name "SubscribedContent-310093Enabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $contentDeliveryPath -Name "SilentInstalledAppsEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
        Write-Setting "Disable suggested apps and silent installs"
    }

    # -------------------------------------------------------------------------
    # Activity History
    # -------------------------------------------------------------------------
    Write-Host "    Activity History:" -ForegroundColor White

    $activityPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
    if (-not (Test-Path $activityPath)) {
        New-Item -Path $activityPath -Force | Out-Null
    }
    Set-ItemProperty -Path $activityPath -Name "PublishUserActivities" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $activityPath -Name "UploadUserActivities" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Setting "Disable activity history sync"

    # -------------------------------------------------------------------------
    # NOTE: Keep Xbox Game Bar enabled (gaming rig)
    # -------------------------------------------------------------------------
    Write-Host "    Gaming:" -ForegroundColor White
    Write-Setting "Xbox Game Bar: kept enabled (gaming rig)"

    Write-Host ""
    Write-Host "    Note: For additional debloating, run winutil:" -ForegroundColor DarkGray
    Write-Host "      irm 'https://christitus.com/win' | iex" -ForegroundColor DarkGray
}

# =============================================================================
# PERSONAL SETTINGS
# =============================================================================

function Apply-PersonalSettings {
    Write-Step "Applying Personal Settings"

    # -------------------------------------------------------------------------
    # Appearance
    # -------------------------------------------------------------------------
    Write-Host "    Appearance:" -ForegroundColor White

    # Dark mode
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0 -Type DWord
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0 -Type DWord
    Write-Setting "Dark mode enabled"

    # -------------------------------------------------------------------------
    # Taskbar
    # -------------------------------------------------------------------------
    Write-Host "    Taskbar:" -ForegroundColor White

    $taskbarPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

    # Hide search box (use Win key to search)
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 0 -Type DWord
    Write-Setting "Hide search box"

    # Hide Task View button
    Set-ItemProperty -Path $taskbarPath -Name "ShowTaskViewButton" -Value 0 -Type DWord
    Write-Setting "Hide Task View button"

    # Hide Widgets
    Set-ItemProperty -Path $taskbarPath -Name "TaskbarDa" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Setting "Hide Widgets"

    # Hide Chat
    Set-ItemProperty -Path $taskbarPath -Name "TaskbarMn" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Setting "Hide Chat"

    # -------------------------------------------------------------------------
    # Mouse / Keyboard
    # -------------------------------------------------------------------------
    Write-Host "    Input:" -ForegroundColor White

    # Disable mouse acceleration (better for gaming)
    $mousePath = "HKCU:\Control Panel\Mouse"
    Set-ItemProperty -Path $mousePath -Name "MouseSpeed" -Value "0"
    Set-ItemProperty -Path $mousePath -Name "MouseThreshold1" -Value "0"
    Set-ItemProperty -Path $mousePath -Name "MouseThreshold2" -Value "0"
    Write-Setting "Disable mouse acceleration"

    # -------------------------------------------------------------------------
    # Privacy
    # -------------------------------------------------------------------------
    Write-Host "    Privacy:" -ForegroundColor White

    # Disable app launch tracking
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackProgs" -Value 0 -Type DWord
    Write-Setting "Disable app launch tracking"
}

# =============================================================================
# MAIN
# =============================================================================

if ($All) {
    Apply-DevSettings
    Apply-DebloatSettings
    Apply-PersonalSettings
} elseif ($DevOnly) {
    Apply-DevSettings
} elseif ($DebloatOnly) {
    Apply-DebloatSettings
} else {
    # Interactive mode
    Write-Host ""

    if (Get-Command gum -ErrorAction SilentlyContinue) {
        $choices = "Dev Settings", "Debloat", "Personal Settings" | gum choose --no-limit --selected "Dev Settings,Debloat" --header "Select settings to apply:"

        if ($choices -contains "Dev Settings") {
            Apply-DevSettings
        }

        if ($choices -contains "Debloat") {
            Apply-DebloatSettings
        }

        if ($choices -contains "Personal Settings") {
            Apply-PersonalSettings
        }
    } else {
        $devChoice = Read-Host "    Apply Dev Settings? [Y/n]"
        if ($devChoice -notmatch "^[Nn]") {
            Apply-DevSettings
        }

        $debloatChoice = Read-Host "    Apply Debloat Settings? [Y/n]"
        if ($debloatChoice -notmatch "^[Nn]") {
            Apply-DebloatSettings
        }

        $personalChoice = Read-Host "    Apply Personal Settings? [y/N]"
        if ($personalChoice -match "^[Yy]") {
            Apply-PersonalSettings
        }
    }
}

# Restart Explorer to apply changes
Write-Host ""
Write-Step "Restarting Explorer"
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Start-Process explorer
Write-Host "    [OK] Explorer restarted" -ForegroundColor Green

Write-Host ""
Write-Host "======================================" -ForegroundColor Green
Write-Host "  Windows Configuration Complete" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""
Write-Host "Some changes may require logout/restart to take effect."
Write-Host ""
