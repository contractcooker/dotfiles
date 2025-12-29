# Windows Development Environment Setup
# Run in PowerShell as Administrator
#
# Optimized order:
#   1. Scoop              - package foundation
#   2. Profile selection  - Personal/Work/Server
#   3. 1Password          - enables all auth
#   4. 1Password SSH      - configure agent
#   5. Core CLI tools     - git, gh, jq, gum, fnm, uv, starship
#   6. GitHub CLI auth    - via SSH
#   7. Clone repos        - config + dotfiles
#   8. Link dotfiles      - PowerShell profile
#   9. Node + Claude      - troubleshooting available!
#   10. Git + SSH config  - from config repo
#   11. Python/uv         - dev tools
#   12. Clone all repos   - everything ready
#   13. Optional packages - profile-filtered, interactive
#   14. Dropbox           - file sync (skip for Server)
#   15. Windows prefs     - system config
#   16. Hardware check    - NVIDIA, ASUS detection
#
# Usage:
#   irm https://raw.githubusercontent.com/contractcooker/dotfiles/main/scripts/setup-windows.ps1 | iex
#   .\setup-windows.ps1
#   .\setup-windows.ps1 -Profile Personal  # Specify profile
#   .\setup-windows.ps1 -All               # Non-interactive

param(
    [string]$SetupProfile,
    [switch]$All,
    [switch]$SkipPackages,
    [switch]$SkipRepos
)

# Validate profile manually (ValidateSet doesn't work with iex)
if ($SetupProfile -and $SetupProfile -notin @("Personal", "Work", "Server")) {
    Write-Host "ERROR: Invalid profile '$SetupProfile'. Must be Personal, Work, or Server." -ForegroundColor Red
    exit 1
}

$ErrorActionPreference = "Stop"
$LogDir = "$env:TEMP\dotfiles-setup-logs"
$LogFile = "$LogDir\setup-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# Create log directory and rotate old logs (keep last 10)
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}
Get-ChildItem -Path $LogDir -Filter "setup-*.log" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -Skip 9 |
    Remove-Item -Force

# Start logging
Start-Transcript -Path $LogFile | Out-Null
Write-Host "Logging to: $LogFile" -ForegroundColor DarkGray

trap {
    Write-Host ""
    Write-Host "ERROR: $_" -ForegroundColor Red
    Write-Host "Line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
    Write-Host ""
    Write-Host "See full log: $LogFile" -ForegroundColor Yellow
    Stop-Transcript | Out-Null
    break
}

$ReposRoot = "$env:USERPROFILE\source\repos"
$ConfigPath = "$ReposRoot\dev\config"
$DotfilesPath = "$ReposRoot\dev\dotfiles"
$ScriptDir = "$DotfilesPath\scripts"

function Write-Step {
    param([int]$Number, [int]$Total, [string]$Message)
    Write-Host ""
    Write-Host "==> [$Number/$Total] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "    [OK] $Message" -ForegroundColor Green
}

function Write-Skip {
    param([string]$Message)
    Write-Host "    [SKIP] $Message" -ForegroundColor Yellow
}

function Write-Action {
    param([string]$Message)
    Write-Host ""
    Write-Host "    ACTION REQUIRED:" -ForegroundColor Yellow
    Write-Host "    $Message" -ForegroundColor White
}

function Refresh-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    # Explicitly add scoop shims if not present (handles edge cases with registry timing)
    $scoopShims = "$env:USERPROFILE\scoop\shims"
    if ((Test-Path $scoopShims) -and ($env:Path -notlike "*$scoopShims*")) {
        $env:Path = "$scoopShims;$env:Path"
    }
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  Windows Development Setup" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

$TotalSteps = 16

# =============================================================================
# 1. SCOOP
# =============================================================================
Write-Step 1 $TotalSteps "Scoop Package Manager"

if (Get-Command scoop -ErrorAction SilentlyContinue) {
    Write-Success "Scoop installed"
} else {
    Write-Host "    Installing Scoop..."
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    irm get.scoop.sh -outfile "$env:TEMP\scoop-install.ps1"
    & "$env:TEMP\scoop-install.ps1" -RunAsAdmin
    Remove-Item "$env:TEMP\scoop-install.ps1" -ErrorAction SilentlyContinue
    Refresh-Path
    Write-Success "Scoop installed"
}

# Git is required for buckets
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "    Installing git (required for buckets)..."
    scoop install git
    Refresh-Path
}

# Add extras bucket
$buckets = scoop bucket list 2>$null
if ($buckets -notcontains "extras") {
    Write-Host "    Adding extras bucket..."
    scoop bucket add extras
}

# =============================================================================
# 2. PROFILE SELECTION
# =============================================================================
Write-Step 2 $TotalSteps "Profile Selection"

# Install gum early for profile selection (if not already installed)
$gumCmd = $null
$gumExe = "$env:USERPROFILE\scoop\shims\gum.exe"
$gmExe = "$env:USERPROFILE\scoop\shims\gm.exe"
if (-not (Test-Path $gumExe) -and -not (Test-Path $gmExe)) {
    Write-Host "    Installing gum for interactive prompts..."
    scoop install gum
    Refresh-Path
}
if (Test-Path $gumExe) { $gumCmd = $gumExe }
elseif (Test-Path $gmExe) { $gumCmd = $gmExe }

if (-not $SetupProfile) {
    if ($gumCmd) {
        $profileOptions = @(
            "Personal - Full setup with personal apps, gaming optional"
            "Work - Work-focused, no gaming or personal apps"
            "Server - CLI only, core packages"
        )
        $selected = $profileOptions | & $gumCmd choose --header "Select machine profile:"
        if ($selected) {
            $SetupProfile = $selected.Split(" ")[0]
        } else {
            $SetupProfile = "Personal"
        }
    } else {
        Write-Host "    Select profile:" -ForegroundColor Cyan
        Write-Host "      1. Personal - Full setup"
        Write-Host "      2. Work - Work-focused"
        Write-Host "      3. Server - CLI only"
        $choice = Read-Host "    Enter choice [1]"
        switch ($choice) {
            "2" { $SetupProfile = "Work" }
            "3" { $SetupProfile = "Server" }
            default { $SetupProfile = "Personal" }
        }
    }
}
Write-Success "Profile: $SetupProfile"

# Store profile for later use
$script:SelectedProfile = $SetupProfile

# =============================================================================
# 3. 1PASSWORD
# =============================================================================
Write-Step 3 $TotalSteps "1Password"

# Check common install locations and registry
$1pPaths = @(
    "C:\Program Files\1Password\app\8\1Password.exe",
    "$env:LOCALAPPDATA\1Password\app\8\1Password.exe",
    "$env:LOCALAPPDATA\Programs\1Password\app\8\1Password.exe",
    "$env:LOCALAPPDATA\Microsoft\WindowsApps\1Password.exe"
)
$1pInstalled = $1pPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

# Also check registry for installed apps
if (-not $1pInstalled) {
    $1pReg = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
             Where-Object { $_.DisplayName -like "*1Password*" }
    if ($1pReg) { $1pInstalled = $true }
}

if ($1pInstalled) {
    Write-Success "1Password installed"
}

# Force-install 1Password Edge extension via policy (requires admin, skip on corporate machines)
try {
    $edgeExtPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist"
    $1pExtId = "dppgmdbiimibapkepcbdbmkaabgiofem;https://edge.microsoft.com/extensionwebstorebase/v1/crx"
    if (-not (Test-Path $edgeExtPath)) {
        New-Item -Path $edgeExtPath -Force | Out-Null
    }
    $existingExts = Get-ItemProperty -Path $edgeExtPath -ErrorAction SilentlyContinue
    $1pExtInstalled = $existingExts.PSObject.Properties.Value -contains $1pExtId
    if (-not $1pExtInstalled) {
        $nextId = ((Get-ItemProperty -Path $edgeExtPath -ErrorAction SilentlyContinue).PSObject.Properties.Name |
                   Where-Object { $_ -match '^\d+$' } | Measure-Object -Maximum).Maximum + 1
        if (-not $nextId) { $nextId = 1 }
        New-ItemProperty -Path $edgeExtPath -Name $nextId -Value $1pExtId -PropertyType String -Force | Out-Null
        Write-Success "1Password Edge extension will install on next Edge launch"
    } else {
        Write-Success "1Password Edge extension configured"
    }
} catch {
    Write-Skip "1Password Edge extension (no admin access - install manually from Edge Add-ons)"
}

if (-not $1pInstalled) {
    Write-Host "    Downloading 1Password..." -NoNewline
    $1pInstaller = "$env:TEMP\1PasswordSetup-latest.exe"
    $ProgressPreference = 'SilentlyContinue'  # Speed up download
    Invoke-WebRequest -Uri "https://downloads.1password.com/win/1PasswordSetup-latest.exe" -OutFile $1pInstaller
    $ProgressPreference = 'Continue'
    Write-Host " done" -ForegroundColor Green
    Write-Host "    Installing 1Password (silent, may take a minute)..." -NoNewline
    Start-Process -FilePath $1pInstaller -ArgumentList "--silent" -Wait
    Write-Host " done" -ForegroundColor Green
    Remove-Item $1pInstaller -ErrorAction SilentlyContinue
    Write-Success "1Password installed"
}

# =============================================================================
# 4. 1PASSWORD SSH AGENT
# =============================================================================
Write-Step 4 $TotalSteps "1Password SSH Agent"

# Disable OpenSSH Agent (conflicts with 1Password SSH Agent)
$sshAgent = Get-Service ssh-agent -ErrorAction SilentlyContinue
if ($sshAgent) {
    if ($sshAgent.Status -eq 'Running') {
        Stop-Service ssh-agent -ErrorAction SilentlyContinue
    }
    if ($sshAgent.StartType -ne 'Disabled') {
        Set-Service ssh-agent -StartupType Disabled -ErrorAction SilentlyContinue
    }
    Write-Success "Windows OpenSSH Agent disabled"
}

Write-Action "Enable 1Password SSH Agent"
Write-Host "      1. Open 1Password"
Write-Host "      2. Settings > Developer"
Write-Host "      3. Enable 'Use the SSH Agent'"
Write-Host ""
Read-Host "    Press Enter when done"

# =============================================================================
# 5. CORE CLI TOOLS
# =============================================================================
Write-Step 5 $TotalSteps "Core CLI Tools"

$coreTools = @("git", "gh", "jq", "gum", "fnm", "uv", "starship")

foreach ($tool in $coreTools) {
    $installed = scoop list 2>$null | Select-String "^\s*$tool\s"
    if ($installed) {
        Write-Success "$tool"
    } else {
        Write-Host "    Installing $tool..."
        scoop install $tool
    }
}

Refresh-Path

# =============================================================================
# 6. GITHUB CLI AUTH
# =============================================================================
Write-Step 6 $TotalSteps "GitHub Authentication"

# Check auth status using gh auth token (more reliable than status)
$ghToken = gh auth token -h github.com 2>$null
if ($ghToken) {
    $ghUser = gh api user --jq '.login' 2>$null
    Write-Success "Authenticated as $ghUser"
} else {
    Write-Host "    Authenticating with GitHub..."
    Write-Host "    (Using SSH protocol with 1Password agent)"
    gh auth login --web --git-protocol ssh --skip-ssh-key --scopes admin:public_key
    if ($LASTEXITCODE -eq 0) {
        Write-Success "GitHub authenticated"
    } else {
        Write-Host "    [ERROR] GitHub authentication failed" -ForegroundColor Red
        exit 1
    }
}

# SSH key check is optional - skip it to avoid complications with scopes
# The key is likely already on GitHub from initial setup

# =============================================================================
# 7. CLONE CONFIG + DOTFILES
# =============================================================================
Write-Step 7 $TotalSteps "Clone Repositories"

# Set up SSH for 1Password agent (needed before clone)
$sshDir = "$env:USERPROFILE\.ssh"
$sshConfig = "$sshDir\config"
if (-not (Test-Path $sshDir)) {
    New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
}

# Check if config needs to be created or fixed (backslashes don't work)
$needsConfig = -not (Test-Path $sshConfig)
if (-not $needsConfig -and (Test-Path $sshConfig)) {
    $existingConfig = Get-Content $sshConfig -Raw
    if ($existingConfig -match '\\\\\.\\\\pipe') {
        Write-Host "    Fixing SSH config (backslashes -> forward slashes)..."
        $needsConfig = $true
    }
}

if ($needsConfig) {
    Write-Host "    Creating SSH config for 1Password agent..."
    $sshConfigContent = @"
Host github.com
  HostName github.com
  User git
  IdentityAgent "//./pipe/openssh-ssh-agent"

Host *
  IdentityAgent "//./pipe/openssh-ssh-agent"
"@
    [System.IO.File]::WriteAllText($sshConfig, $sshConfigContent)
    Write-Success "SSH config created"
}

# Force git to use Windows OpenSSH (not Git Bash's ssh) for 1Password agent compatibility
git config --global core.sshCommand "C:/Windows/System32/OpenSSH/ssh.exe"
Write-Success "Git configured to use Windows OpenSSH"

# Add GitHub's SSH host key to known_hosts (avoid interactive prompt)
$knownHosts = "$sshDir\known_hosts"
$needsGithubKey = $true
if (Test-Path $knownHosts) {
    $hasGithub = Select-String -Path $knownHosts -Pattern "github\.com" -Quiet -ErrorAction SilentlyContinue
    if ($hasGithub) { $needsGithubKey = $false }
}
if ($needsGithubKey) {
    Write-Host "    Adding GitHub to known_hosts..."
    $knownHostsUrl = "https://raw.githubusercontent.com/contractcooker/dotfiles/main/home/.ssh/known_hosts"
    $ProgressPreference = 'SilentlyContinue'
    try {
        Invoke-WebRequest -Uri $knownHostsUrl -OutFile $knownHosts -ErrorAction Stop
        $ProgressPreference = 'Continue'
        Write-Success "GitHub host keys added"
    } catch {
        $ProgressPreference = 'Continue'
        Write-Host "    Note: You may be prompted to accept GitHub's host key (type 'yes')"
    }
}

if (-not (Test-Path "$ReposRoot\dev")) {
    New-Item -ItemType Directory -Path "$ReposRoot\dev" -Force | Out-Null
}

if (Test-Path $ConfigPath) {
    Write-Success "config repo exists"
} else {
    Write-Host "    Cloning config..."
    Push-Location "$ReposRoot\dev"
    # Temporarily allow stderr (gh clone outputs progress to stderr)
    $ErrorActionPreference = "Continue"
    gh repo clone config 2>&1 | Out-Null
    $cloneExitCode = $LASTEXITCODE
    $ErrorActionPreference = "Stop"
    Pop-Location
    if ($cloneExitCode -ne 0 -or -not (Test-Path $ConfigPath)) {
        Write-Host "    [ERROR] Failed to clone config (exit code: $cloneExitCode)" -ForegroundColor Red
        exit 1
    }
    Write-Success "config cloned"
}

if (Test-Path $DotfilesPath) {
    Write-Success "dotfiles repo exists"
} else {
    Write-Host "    Cloning dotfiles..."
    Push-Location "$ReposRoot\dev"
    # Temporarily allow stderr (gh clone outputs progress to stderr)
    $ErrorActionPreference = "Continue"
    gh repo clone dotfiles 2>&1 | Out-Null
    $cloneExitCode = $LASTEXITCODE
    $ErrorActionPreference = "Stop"
    Pop-Location
    if ($cloneExitCode -ne 0 -or -not (Test-Path $DotfilesPath)) {
        Write-Host "    [ERROR] Failed to clone dotfiles (exit code: $cloneExitCode)" -ForegroundColor Red
        exit 1
    }
    Write-Success "dotfiles cloned"
}

# =============================================================================
# 8. LINK DOTFILES
# =============================================================================
Write-Step 8 $TotalSteps "Link Dotfiles"

# Enable Developer Mode (required for symlinks without elevation)
$devModePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
$devModeEnabled = (Get-ItemProperty -Path $devModePath -Name AllowDevelopmentWithoutDevLicense -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense
if ($devModeEnabled -eq 1) {
    Write-Success "Developer Mode already enabled"
} else {
    # Try to enable it (requires admin) - use SilentlyContinue to avoid terminating error
    if (-not (Test-Path $devModePath)) {
        New-Item -Path $devModePath -Force -ErrorAction SilentlyContinue | Out-Null
    }
    Set-ItemProperty -Path $devModePath -Name AllowDevelopmentWithoutDevLicense -Value 1 -ErrorAction SilentlyContinue
    # Check if it worked
    $devModeEnabled = (Get-ItemProperty -Path $devModePath -Name AllowDevelopmentWithoutDevLicense -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense
    if ($devModeEnabled -eq 1) {
        Write-Success "Developer Mode enabled"
    } else {
        Write-Host "    [WARN] Could not enable Developer Mode (need admin)" -ForegroundColor Yellow
        Write-Host "    Enable manually: Settings > Privacy & Security > For developers > Developer Mode" -ForegroundColor DarkGray
    }
}

$dotfilesHome = "$DotfilesPath\home"
$backupDir = "$env:USERPROFILE\.dotfiles-backup"

if (Test-Path $dotfilesHome) {
    # Find all files in home/
    Get-ChildItem -Path $dotfilesHome -Recurse -File | ForEach-Object {
        $relativePath = $_.FullName.Substring($dotfilesHome.Length + 1)
        $source = $_.FullName
        $target = "$env:USERPROFILE\$relativePath"
        $targetDir = Split-Path $target -Parent

        # Ensure parent directory exists
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }

        # Check if target already exists
        if (Test-Path $target) {
            # Check if it's already the correct symlink
            $existing = Get-Item $target -Force
            if ($existing.LinkType -eq "SymbolicLink" -and $existing.Target -eq $source) {
                Write-Success "$relativePath (already linked)"
                return
            }

            # Backup existing file
            if (-not (Test-Path $backupDir)) {
                New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
            }
            $backupPath = "$backupDir\$relativePath.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            $backupParent = Split-Path $backupPath -Parent
            if (-not (Test-Path $backupParent)) {
                New-Item -ItemType Directory -Path $backupParent -Force | Out-Null
            }

            if ($existing.LinkType -eq "SymbolicLink") {
                Remove-Item $target -Force
                Write-Host "    [->] $relativePath (updating symlink)" -ForegroundColor White
            } else {
                Move-Item $target $backupPath -Force
                Write-Host "    [->] $relativePath (backed up)" -ForegroundColor White
            }
        } else {
            Write-Host "    [->] $relativePath (creating)" -ForegroundColor White
        }

        # Create symlink
        New-Item -ItemType SymbolicLink -Path $target -Target $source -Force | Out-Null
    }
} else {
    Write-Skip "No dotfiles home directory found"
}

# =============================================================================
# 9. NODE + CLAUDE CODE
# =============================================================================
Write-Step 9 $TotalSteps "Node.js + Claude Code"

# Initialize fnm for this session
fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression

# Install Node LTS
$nodeInstalled = fnm list 2>$null | Select-String "lts"
if ($nodeInstalled) {
    fnm use lts-latest 2>$null
    Write-Success "Node.js LTS"
} else {
    Write-Host "    Installing Node.js LTS..."
    fnm install --lts
    fnm use lts-latest
    fnm default lts-latest
    Write-Success "Node.js LTS installed"
}

# Install Claude Code
$claudeInstalled = npm list -g @anthropic-ai/claude-code 2>$null | Select-String "claude-code"
if ($claudeInstalled) {
    Write-Success "Claude Code"
} else {
    Write-Host "    Installing Claude Code..."
    npm install -g @anthropic-ai/claude-code
    Write-Success "Claude Code installed"
}

# Configure Claude settings
$claudeDir = "$env:USERPROFILE\.claude"
$claudeSettings = "$claudeDir\CLAUDE.md"
$globalSource = "$DotfilesPath\claude\global.md"
$windowsSource = "$DotfilesPath\claude\windows.md"

if (-not (Test-Path $claudeDir)) {
    New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
}

if ((Test-Path $globalSource) -and (Test-Path $windowsSource)) {
    Get-Content $globalSource, $windowsSource | Set-Content $claudeSettings
    Write-Success "Claude settings configured"
} elseif (Test-Path $globalSource) {
    Copy-Item $globalSource $claudeSettings
    Write-Success "Claude settings configured"
}

Write-Host ""
Write-Host "    Claude Code is now available!" -ForegroundColor Green
Write-Host "    Run 'claude' if you need help from here." -ForegroundColor DarkGray

# =============================================================================
# 10. GIT + SSH CONFIG
# =============================================================================
Write-Step 10 $TotalSteps "Git + SSH Configuration"

# Git config from identity.json
$identityPath = "$ConfigPath\identity.json"
if (Test-Path $identityPath) {
    $identity = Get-Content $identityPath | ConvertFrom-Json

    git config --global user.name $identity.name
    git config --global user.email $identity.email
    git config --global init.defaultBranch main
    git config --global core.autocrlf true
    git config --global core.sshCommand "C:/Windows/System32/OpenSSH/ssh.exe"

    Write-Success "Git configured"
    Write-Host "      user.name: $($identity.name)"
    Write-Host "      user.email: $($identity.email)"
} else {
    Write-Skip "identity.json not found"
}

# SSH config
$sshDir = "$env:USERPROFILE\.ssh"
$sshConfig = "$sshDir\config"

if (-not (Test-Path $sshDir)) {
    New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
}

if (-not (Test-Path $sshConfig)) {
    $hostsPath = "$ConfigPath\hosts.json"
    if (Test-Path $hostsPath) {
        $hosts = Get-Content $hostsPath | ConvertFrom-Json
        $homelabDomain = $hosts.homelab_domain
        $homelabUser = $hosts.homelab_user

        $sshConfigContent = @"
# Git services
Host github.com
  HostName github.com
  User git

# Homelab servers
Host *.$homelabDomain
  User $homelabUser

# Default - 1Password SSH agent
Host *
  IdentityAgent "//./pipe/openssh-ssh-agent"
"@
        [System.IO.File]::WriteAllText($sshConfig, $sshConfigContent)
        Write-Success "SSH config created (with homelab)"
    } else {
        $sshConfigContent = @"
# Git services
Host github.com
  HostName github.com
  User git

# Default - 1Password SSH agent
Host *
  IdentityAgent "//./pipe/openssh-ssh-agent"
"@
        [System.IO.File]::WriteAllText($sshConfig, $sshConfigContent)
        Write-Success "SSH config created"
    }
} else {
    Write-Success "SSH config exists"
}

# =============================================================================
# 11. PYTHON / UV
# =============================================================================
Write-Step 11 $TotalSteps "Python (uv)"

# Install Python via uv
$pythonInstalled = uv python list --only-installed 2>$null | Select-String "cpython"
if ($pythonInstalled) {
    Write-Success "Python installed"
} else {
    Write-Host "    Installing Python..."
    uv python install
    Write-Success "Python installed"
}

# Install pre-commit
$ErrorActionPreference = "Continue"
$precommit = uv tool list 2>$null | Select-String "pre-commit"
$ErrorActionPreference = "Stop"
if ($precommit) {
    Write-Success "pre-commit installed"
} else {
    Write-Host "    Installing pre-commit..."
    uv tool install pre-commit
    Write-Success "pre-commit installed"
}

# Ensure uv tools are on PATH
$ErrorActionPreference = "Continue"
uv tool update-shell 2>$null
$ErrorActionPreference = "Stop"

# =============================================================================
# 12. CLONE ALL REPOS
# =============================================================================
Write-Step 12 $TotalSteps "Clone All Repositories"

if (-not $SkipRepos) {
    $cloneScript = "$ScriptDir\clone-repos.ps1"
    if (Test-Path $cloneScript) {
        & $cloneScript
    } else {
        Write-Skip "clone-repos.ps1 not found"
    }
}

# =============================================================================
# 13. OPTIONAL PACKAGES
# =============================================================================
Write-Step 13 $TotalSteps "Optional Packages"

if (-not $SkipPackages) {
    $installScript = "$ScriptDir\install-packages.ps1"
    if (Test-Path $installScript) {
        if ($All) {
            & $installScript -Profile $SetupProfile -BaseOnly
        } else {
            # Check for gum
            $hasGum = (Test-Path "$env:USERPROFILE\scoop\shims\gm.exe") -or
                      (Test-Path "$env:USERPROFILE\scoop\shims\gum.exe") -or
                      (Get-Command gum -ErrorAction SilentlyContinue)
            if ($hasGum) {
                if (Test-Path "$env:USERPROFILE\scoop\shims\gum.exe") {
                    $gumExe = "$env:USERPROFILE\scoop\shims\gum.exe"
                } else {
                    $gumExe = "$env:USERPROFILE\scoop\shims\gm.exe"
                }
                $confirm = "Yes", "No" | & $gumExe choose --header "Install optional packages now?"
                if ($confirm -eq "Yes") {
                    & $installScript -Profile $SetupProfile
                } else {
                    Write-Skip "Run install-packages.ps1 -Profile $SetupProfile later"
                }
            } else {
                $reply = Read-Host "    Install optional packages? [y/N]"
                if ($reply -match "^[Yy]") {
                    & $installScript -Profile $SetupProfile
                } else {
                    Write-Skip "Run install-packages.ps1 -Profile $SetupProfile later"
                }
            }
        }
    }
}

# =============================================================================
# 14. DROPBOX
# =============================================================================
Write-Step 14 $TotalSteps "Dropbox"

if ($SetupProfile -eq "Server") {
    Write-Skip "Dropbox skipped (Server profile)"
} else {
    $dropboxInstalled = winget list --id Dropbox.Dropbox 2>$null | Select-String "Dropbox"
    if ($dropboxInstalled -or (Test-Path "$env:LOCALAPPDATA\Dropbox")) {
        Write-Success "Dropbox installed"
    } else {
        Write-Host "    Installing Dropbox..."
        winget install --id Dropbox.Dropbox --accept-source-agreements --accept-package-agreements --silent
        Write-Success "Dropbox installed"
    }

    Write-Action "Configure Dropbox folder sync"
    Write-Host "      1. Open Dropbox and sign in"
    Write-Host "      2. For each folder (Documents, Desktop, Downloads):"
    Write-Host "         a. Right-click folder in File Explorer sidebar"
    Write-Host "         b. Properties > Location tab"
    Write-Host "         c. Move to Dropbox folder"
    Write-Host ""
    Write-Host "    See docs/dropbox-sync.md for details" -ForegroundColor DarkGray
    Write-Host ""
    Read-Host "    Press Enter when done (or to skip)"
}

# =============================================================================
# 15. WINDOWS PREFERENCES
# =============================================================================
Write-Step 15 $TotalSteps "Windows Preferences"

$configScript = "$ScriptDir\configure-windows.ps1"
if (Test-Path $configScript) {
    if ($All) {
        & $configScript -All
    } else {
        # Check for gum (scoop shim is gm.exe)
        $hasGum = (Test-Path "$env:USERPROFILE\scoop\shims\gm.exe") -or (Get-Command gum -ErrorAction SilentlyContinue)
        if ($hasGum) {
            $gmExe = "$env:USERPROFILE\scoop\shims\gm.exe"
            $confirm = "Yes", "No" | & $gmExe choose --header "Configure Windows preferences?"
            if ($confirm -eq "Yes") {
                & $configScript
            } else {
                Write-Skip "Run configure-windows.ps1 later"
            }
        } else {
            $reply = Read-Host "    Configure Windows preferences? [Y/n]"
            if ($reply -notmatch "^[Nn]") {
                & $configScript
            } else {
                Write-Skip "Run configure-windows.ps1 later"
            }
        }
    }
} else {
    Write-Skip "configure-windows.ps1 not found"
}

# =============================================================================
# 16. GRAPHICS DRIVER CHECK
# =============================================================================
Write-Step 16 $TotalSteps "Graphics Driver"

$nvidia = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -match "NVIDIA" }
if ($nvidia) {
    Write-Success "NVIDIA GPU: $($nvidia.Name)"

    $gfeInstalled = winget list --id Nvidia.GeForceExperience 2>$null | Select-String "GeForce"
    if ($gfeInstalled) {
        Write-Success "GeForce Experience installed"
    } else {
        Write-Host "    Consider installing GeForce Experience for driver updates:"
        Write-Host "      winget install Nvidia.GeForceExperience" -ForegroundColor DarkGray
    }

    # Check for Ollama (local LLMs)
    $ollamaInstalled = scoop list 2>$null | Select-String "ollama"
    if ($ollamaInstalled) {
        Write-Success "Ollama installed (uses CUDA automatically)"
    } else {
        Write-Host "    For local LLMs: scoop install ollama" -ForegroundColor DarkGray
    }
} else {
    Write-Skip "No NVIDIA GPU detected"
}

# =============================================================================
# DONE
# =============================================================================
Write-Host ""
Write-Host "======================================" -ForegroundColor Green
Write-Host "  Setup Complete!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Restart your terminal (for profile changes)"
Write-Host "  2. Test SSH: ssh -T git@github.com"
Write-Host "  3. Verify: .\verify-setup.ps1"
Write-Host ""
Write-Host "Your repos are at: $ReposRoot" -ForegroundColor Cyan
Write-Host ""

if (Get-Command gum -ErrorAction SilentlyContinue) {
    $verify = "Yes", "No" | gum choose --header "Run verification now?"
    if ($verify -eq "Yes") {
        $verifyScript = "$ScriptDir\verify-setup.ps1"
        if (Test-Path $verifyScript) {
            & $verifyScript
        }
    }
}

Stop-Transcript | Out-Null
