# Windows Development Environment Setup
# Run in PowerShell as Administrator
#
# Usage:
#   irm https://raw.githubusercontent.com/contractcooker/dotfiles/main/scripts/setup-windows.ps1 | iex
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

    Write-Host ""
    Write-Host "    NOTE: Restart your terminal to pick up new PATH entries" -ForegroundColor Yellow
}

# Step 2: Authenticate GitHub CLI
Write-Step "Checking GitHub CLI authentication"

$ghStatus = gh auth status 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Skip "Already authenticated with GitHub"
} else {
    Write-Host "    Opening browser for GitHub authentication..."
    gh auth login --web --git-protocol ssh
    Write-Success "GitHub authenticated"
}

# Step 3: Clone config repo (private - needs auth first)
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

# Step 4: Configure Git from config
if (-not $SkipGitConfig) {
    Write-Step "Configuring Git"

    $identityPath = "$configPath\identity.json"
    if (Test-Path $identityPath) {
        $identity = Get-Content $identityPath | ConvertFrom-Json

        git config --global user.name $identity.name
        git config --global user.email $identity.email
        git config --global init.defaultBranch main
        git config --global core.autocrlf true

        Write-Success "Git configured"
        Write-Host "    user.name: $($identity.name)"
        Write-Host "    user.email: $($identity.email)"
        Write-Host "    init.defaultBranch: main"
        Write-Host "    core.autocrlf: true"
    } else {
        Write-Host "    [ERROR] identity.json not found in config repo" -ForegroundColor Red
        exit 1
    }
}

# Step 5: Clone dotfiles and other repos
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

# Step 6: SSH config for 1Password
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

        $sshConfig = @"
# Git services
Host github.com
  HostName github.com
  User git

# Homelab servers
Host *.$($hosts.homelab_domain)
  User $($hosts.homelab_user)

# Default settings - 1Password agent for all connections
Host *
  IdentityAgent "\\.\pipe\openssh-ssh-agent"
"@
        $sshConfig | Out-File -FilePath $sshConfigPath -Encoding utf8
        Write-Success "SSH config created"
        Write-Host "    Enable 1Password SSH Agent in 1Password settings to use"
    } else {
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

# Done
Write-Host ""
Write-Host "======================================" -ForegroundColor Green
Write-Host "  Setup Complete!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Restart your terminal"
Write-Host "  2. Enable 1Password SSH Agent (Settings > Developer > SSH Agent)"
Write-Host "  3. Test SSH: ssh -T git@github.com"
Write-Host ""
Write-Host "Your repos are at: $HOME\repos\" -ForegroundColor Cyan
