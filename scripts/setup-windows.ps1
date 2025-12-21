# Windows Development Environment Setup
# Run in PowerShell as Administrator
#
# Usage:
#   irm https://raw.githubusercontent.com/contractcooker/dotfiles/main/scripts/setup-windows.ps1 -OutFile $env:TEMP\setup.ps1; & $env:TEMP\setup.ps1; rm $env:TEMP\setup.ps1
#
# Or if you've already cloned dotfiles:
#   .\setup-windows.ps1

param(
    [switch]$SkipPackages,
    [switch]$SkipGitConfig,
    [switch]$SkipRepos
)

$ErrorActionPreference = "Stop"

$reposRoot = "$HOME\repos"
$configPath = "$reposRoot\dev\config"
$dotfilesPath = "$reposRoot\dev\dotfiles"

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

# Check if running as admin for winget
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  Windows Development Setup" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

# Step 1: Install packages
if (-not $SkipPackages) {
    Write-Step "Installing packages via winget"

    $packages = @(
        "AgileBits.1Password",
        "Git.Git",
        "GitHub.cli",
        "Microsoft.WindowsTerminal"
    )

    foreach ($pkg in $packages) {
        $installed = winget list --id $pkg 2>$null | Select-String $pkg
        if ($installed) {
            Write-Skip "$pkg (already installed)"
        } else {
            Write-Host "    Installing $pkg..."
            winget install --id $pkg --accept-source-agreements --accept-package-agreements
            Write-Success "$pkg"
        }
    }

    # Refresh PATH to pick up newly installed tools
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    Write-Success "PATH refreshed"
}

# Step 2: Disable OpenSSH Agent (conflicts with 1Password SSH Agent)
Write-Step "Disabling OpenSSH Agent"

$sshAgent = Get-Service ssh-agent -ErrorAction SilentlyContinue
if ($sshAgent) {
    Write-Host "    Found OpenSSH Agent service (Status: $($sshAgent.Status), StartType: $($sshAgent.StartType))"
    if ($sshAgent.Status -eq 'Running') {
        Write-Host "    Stopping ssh-agent service..."
        Stop-Service ssh-agent
        Write-Host "    Stopped ssh-agent service"
    }
    if ($sshAgent.StartType -ne 'Disabled') {
        Write-Host "    Disabling ssh-agent service..."
        Set-Service ssh-agent -StartupType Disabled
    }
    Write-Success "OpenSSH Agent disabled (1Password will handle SSH)"
} else {
    Write-Skip "OpenSSH Agent service not found"
}

# Step 3: Configure 1Password SSH Agent
Write-Step "1Password SSH Agent Setup"
Write-Host ""
Write-Host "    ACTION REQUIRED:" -ForegroundColor Yellow
Write-Host "      1. Open 1Password"
Write-Host "      2. Go to Settings > Developer"
Write-Host "      3. Enable 'Use the SSH Agent'"
Write-Host ""
Read-Host "    Press Enter when done"
Write-Success "1Password SSH Agent configured"

# Step 4: Install Node.js (via fnm) and Claude Code
Write-Step "Setting up Node.js and Claude Code"

$fnmInstalled = winget list --id Schniz.fnm 2>$null | Select-String "Schniz.fnm"
if (-not $fnmInstalled) {
    Write-Host "    Installing fnm (Node version manager)..."
    winget install --id Schniz.fnm --accept-source-agreements --accept-package-agreements
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    Write-Success "fnm installed"
} else {
    Write-Skip "fnm (already installed)"
}

# Initialize fnm for this session
fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression

# Add fnm to PowerShell profile if not already there
$profilePath = $PROFILE
$fnmInit = 'fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression'
if (Test-Path $profilePath) {
    $profileContent = Get-Content $profilePath -Raw
    if ($profileContent -notmatch "fnm env") {
        Add-Content -Path $profilePath -Value "`n# fnm (Node version manager)`n$fnmInit"
        Write-Success "fnm added to PowerShell profile"
    } else {
        Write-Skip "fnm already in PowerShell profile"
    }
} else {
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
    Add-Content -Path $profilePath -Value "# fnm (Node version manager)`n$fnmInit"
    Write-Success "PowerShell profile created with fnm"
}

# Install Node.js LTS
$nodeInstalled = fnm list 2>$null | Select-String "lts"
if (-not $nodeInstalled) {
    Write-Host "    Installing Node.js LTS..."
    fnm install --lts
    fnm use lts-latest
    fnm default lts-latest
    Write-Success "Node.js LTS installed"
} else {
    fnm use lts-latest 2>$null
    Write-Skip "Node.js LTS (already installed)"
}

# Install Claude Code
$claudeInstalled = npm list -g @anthropic-ai/claude-code 2>$null | Select-String "claude-code"
if (-not $claudeInstalled) {
    Write-Host "    Installing Claude Code..."
    npm install -g @anthropic-ai/claude-code
    Write-Success "Claude Code installed"
} else {
    Write-Skip "Claude Code (already installed)"
}

# Configure Claude Code global settings
$claudeDir = "$HOME\.claude"
$claudeSettings = "$claudeDir\CLAUDE.md"
$claudeSource = "$dotfilesPath\claude\global.md"

if (-not (Test-Path $claudeDir)) {
    New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
}

if (Test-Path $claudeSettings) {
    $item = Get-Item $claudeSettings -Force
    if ($item.LinkType -eq "SymbolicLink") {
        Write-Skip "Claude global settings (symlink exists)"
    } else {
        Write-Host "    [WARN] Claude settings exists as file, backing up and symlinking" -ForegroundColor Yellow
        Move-Item $claudeSettings "$claudeSettings.backup"
        New-Item -ItemType SymbolicLink -Path $claudeSettings -Target $claudeSource | Out-Null
        Write-Success "Claude global settings symlinked"
    }
} else {
    New-Item -ItemType SymbolicLink -Path $claudeSettings -Target $claudeSource | Out-Null
    Write-Success "Claude global settings symlinked"
}

# Step 5: Authenticate GitHub CLI
Write-Step "Authenticating GitHub CLI"

try {
    $ErrorActionPreference = "SilentlyContinue"
    Write-Host "    Checking current auth status..."
    & gh auth status *>$null
    $authStatus = $LASTEXITCODE
    $ErrorActionPreference = "Stop"

    if ($authStatus -eq 0) {
        Write-Skip "Already authenticated with GitHub"
    } else {
        Write-Host "    Not authenticated. Starting login flow..."
        Write-Host ""
        & gh auth login --web --git-protocol ssh --skip-ssh-key
        if ($LASTEXITCODE -eq 0) {
            Write-Success "GitHub authenticated"
        } else {
            throw "GitHub authentication failed"
        }
    }
} catch {
    $ErrorActionPreference = "Stop"
    Write-Host "    [ERROR] GitHub authentication failed: $_" -ForegroundColor Red
    Write-Host "    Try running manually: gh auth login --web --git-protocol ssh --skip-ssh-key" -ForegroundColor Yellow
    exit 1
}

# Step 6: Clone config repo (private - needs auth first)
Write-Step "Setting up config"

if (-not (Test-Path "$reposRoot\dev")) {
    New-Item -ItemType Directory -Path "$reposRoot\dev" -Force | Out-Null
}

if (-not (Test-Path $configPath)) {
    Write-Host "    Cloning config..."
    Push-Location "$reposRoot\dev"
    gh repo clone config
    Pop-Location
    Write-Success "config cloned"
} else {
    Write-Skip "config (already exists)"
}

# Step 7: Configure Git from config
if (-not $SkipGitConfig) {
    Write-Step "Configuring Git"

    $identityPath = "$configPath\identity.json"
    if (Test-Path $identityPath) {
        $identity = Get-Content $identityPath | ConvertFrom-Json

        git config --global user.name $identity.name
        git config --global user.email $identity.email
        git config --global init.defaultBranch main
        git config --global core.autocrlf true
        git config --global core.sshCommand "C:/Windows/System32/OpenSSH/ssh.exe"

        Write-Success "Git configured"
        Write-Host "    user.name: $($identity.name)"
        Write-Host "    user.email: $($identity.email)"
        Write-Host "    init.defaultBranch: main"
        Write-Host "    core.autocrlf: true"
        Write-Host "    core.sshCommand: Windows OpenSSH (for 1Password)"
    } else {
        Write-Host "    [ERROR] identity.json not found in config repo" -ForegroundColor Red
        exit 1
    }
}


# Step 8: SSH Configuration (after config is cloned so we can read hosts.json)
Write-Step "SSH Configuration"

$sshConfigPath = "$HOME\.ssh\config"
$sshDir = "$HOME\.ssh"

if (-not (Test-Path $sshDir)) {
    New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
}

if (-not (Test-Path $sshConfigPath)) {
    $hostsPath = "$configPath\hosts.json"
    if (Test-Path $hostsPath) {
        $hosts = Get-Content $hostsPath | ConvertFrom-Json
        $homelabDomain = $hosts.homelab_domain
        $homelabUser = $hosts.homelab_user

        $sshConfig = @"
# Git services
Host github.com
  HostName github.com
  User git

# Homelab servers
Host *.$homelabDomain
  User $homelabUser

# Default settings - 1Password agent for all connections
Host *
  IdentityAgent "\\.\pipe\openssh-ssh-agent"
"@
        $sshConfig | Out-File -FilePath $sshConfigPath -Encoding utf8
        Write-Success "SSH config created (with homelab)"
    } else {
        Write-Host "    [WARN] hosts.json not found, creating minimal SSH config" -ForegroundColor Yellow
        $sshConfig = @"
# Git services
Host github.com
  HostName github.com
  User git

# Default settings - 1Password agent for all connections
Host *
  IdentityAgent "\\.\pipe\openssh-ssh-agent"
"@
        $sshConfig | Out-File -FilePath $sshConfigPath -Encoding utf8
        Write-Success "SSH config created (minimal)"
    }
} else {
    Write-Skip "SSH config (already exists)"
}

# Force Git to use Windows OpenSSH (not Git Bash's bundled SSH)
git config --global core.sshCommand "C:/Windows/System32/OpenSSH/ssh.exe"
Write-Success "Git configured to use Windows OpenSSH"
# Step 9: Clone dotfiles and other repos
if (-not $SkipRepos) {
    Write-Step "Setting up repos"

    # Clone dotfiles if not present
    if (-not (Test-Path $dotfilesPath)) {
        Write-Host "    Cloning dotfiles..."
        Push-Location "$reposRoot\dev"
        gh repo clone dotfiles
        Pop-Location
        Write-Success "dotfiles cloned"
    } else {
        Write-Skip "dotfiles (already exists)"
    }

    # Run clone-repos script (reads from config/repos.json)
    Write-Host "    Running clone-repos.ps1..."
    & "$dotfilesPath\scripts\clone-repos.ps1"
}

# Done
Write-Host ""
Write-Host "======================================" -ForegroundColor Green
Write-Host "  Setup Complete!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Restart your terminal"
Write-Host "  2. Test SSH: ssh -T git@github.com"
Write-Host ""
Write-Host "Your repos are at: $HOME\repos\" -ForegroundColor Cyan
