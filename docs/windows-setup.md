# Windows Setup

Development environment setup for Windows machines.

## Overview

This guide mirrors the macOS setup but uses Windows-native tools where appropriate. The goal is consistency across platforms where possible (1Password, gh CLI, git config).

## Prerequisites

- Windows 10/11
- 1Password installed with SSH Agent enabled
- Admin access for initial setup

## Quick Start

```powershell
# One-liner (run as Administrator)
irm https://raw.githubusercontent.com/contractcooker/dotfiles/main/scripts/setup-windows.ps1 | iex
```

This will:
1. Install Git, GitHub CLI, Windows Terminal via winget
2. Authenticate with GitHub (opens browser)
3. Clone the private `config` repo (contains your personal settings)
4. Configure git using values from `config/identity.json`
5. Clone all repos listed in `config/repos.json`
6. Set up SSH config using values from `config/hosts.json`

## Manual Setup

If you prefer to run steps manually:

```powershell
# 1. Install core tools via winget
winget install Git.Git
winget install GitHub.cli

# 2. Restart terminal to pick up new PATH entries

# 3. Authenticate GitHub CLI
gh auth login --web --git-protocol ssh

# 4. Clone config repo (private - has your personal settings)
mkdir $HOME\repos\dev
cd $HOME\repos\dev
gh repo clone config

# 5. Configure git from config
$identity = Get-Content config\identity.json | ConvertFrom-Json
git config --global user.name $identity.name
git config --global user.email $identity.email
git config --global init.defaultBranch main
git config --global core.autocrlf true

# 6. Clone dotfiles and other repos
gh repo clone dotfiles
.\dotfiles\scripts\clone-repos.ps1
```

## Package Management

### winget (Recommended)

Windows Package Manager - built into Windows 11, available for Windows 10.

```powershell
# Install a package
winget install <package-id>

# Search for packages
winget search <query>

# List installed
winget list

# Upgrade all
winget upgrade --all
```

### Core Packages

```powershell
# Development essentials
winget install Git.Git
winget install GitHub.cli
winget install Microsoft.WindowsTerminal
winget install Microsoft.VisualStudioCode

# Optional - Python and Node
winget install Python.Python.3.12
winget install OpenJS.NodeJS.LTS
```

### Alternative: Scoop

For more Unix-like experience and portable apps:

```powershell
# Install Scoop
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression

# Then install packages
scoop install git gh python nodejs
```

## SSH Configuration

### 1Password SSH Agent (Recommended)

Same strategy as macOS - 1Password manages all SSH keys.

**Enable in 1Password:**
1. Open 1Password → Settings → Developer
2. Enable "Use the SSH Agent"
3. Enable "Integrate with 1Password CLI" (optional)

**SSH config is auto-generated** by the setup script using values from `config/hosts.json`. The config uses the Windows named pipe for 1Password: `\\.\pipe\openssh-ssh-agent`

### Verify SSH is working

```powershell
ssh -T git@github.com
# Should see: "Hi <username>! You've successfully authenticated..."
```

## Git Configuration

Git config is set automatically from `config/identity.json`. Windows-specific setting:

```powershell
# Convert LF to CRLF on checkout, CRLF to LF on commit
git config --global core.autocrlf true
```

### Git Credential Manager

Git for Windows includes Git Credential Manager. For SSH auth via 1Password, this isn't needed, but it's there as fallback for HTTPS.

## Terminal Setup

### Windows Terminal (Recommended)

```powershell
winget install Microsoft.WindowsTerminal
```

**Configure default profile:**
1. Open Settings (Ctrl+,)
2. Set default profile to PowerShell or Git Bash
3. Optional: Add custom color scheme

### Git Bash

Included with Git for Windows. Provides Unix-like environment:

```powershell
# Available after installing Git.Git
# Access via: Start → Git Bash
# Or: Right-click folder → "Git Bash Here"
```

## Directory Structure

Mirror the macOS structure:

```
C:\Users\<username>\repos\
├── dev\
│   ├── config\      # Private settings (identity, hosts, repo list)
│   ├── dotfiles\    # Public scripts and templates
│   └── homelab\
├── personal\
│   └── ...
└── everything\
```

PowerShell equivalent of `~/repos`:

```powershell
# In PowerShell, ~ expands to $HOME (C:\Users\<username>)
cd ~/repos/personal
```

## Platform Differences

| Aspect | macOS | Windows |
|--------|-------|---------|
| Package manager | Homebrew | winget / Scoop |
| Shell | zsh/bash | PowerShell / Git Bash |
| SSH agent socket | `~/Library/.../agent.sock` | `\\.\pipe\openssh-ssh-agent` |
| Line endings | LF | CRLF (git handles conversion) |
| Path separator | `/` | `\` (but `/` works in most tools) |
| Home directory | `~` or `$HOME` | `~` or `$HOME` or `$env:USERPROFILE` |

## Troubleshooting

### SSH not using 1Password

1. Verify 1Password SSH Agent is enabled in settings
2. Check `~\.ssh\config` has correct `IdentityAgent` path
3. Restart terminal after enabling agent
4. Try: `ssh-add -l` (should list keys from 1Password)

### Git push fails with permission denied

```powershell
# Verify SSH works
ssh -T git@github.com

# If not, check gh auth status
gh auth status

# Re-authenticate if needed
gh auth login --web --git-protocol ssh
```

### winget not found

- Windows 11: Should be built-in
- Windows 10: Install "App Installer" from Microsoft Store

## References

- [1Password SSH Agent - Windows](https://developer.1password.com/docs/ssh/get-started/#step-3-turn-on-the-1password-ssh-agent)
- [Git for Windows](https://gitforwindows.org/)
- [Windows Package Manager (winget)](https://docs.microsoft.com/en-us/windows/package-manager/winget/)
- [Windows Terminal](https://docs.microsoft.com/en-us/windows/terminal/)
