# Dotfiles

Personal development environment configuration and setup scripts.

## Quick Start

### macOS

```bash
curl -fsSL https://raw.githubusercontent.com/contractcooker/dotfiles/main/scripts/setup-mac.sh | zsh
```

This will:
- Install Homebrew, 1Password, and core CLI tools
- Configure 1Password SSH agent and authenticate GitHub
- Clone config and dotfiles repos, link shell/git config
- Install Node.js (fnm), Claude Code, Python (uv)
- Clone all repos from manifest
- Interactive package selection (optional apps)
- Configure macOS preferences (dev/debloat/personal)

For non-interactive install (everything): `| zsh -s -- --all`

### Windows

```powershell
# Run as Administrator
irm "https://api.github.com/repos/contractcooker/dotfiles/contents/scripts/setup-windows.ps1" -Headers @{Accept="application/vnd.github.v3.raw"} | iex
```

**Dry Run** - Preview what will be installed without making changes:

```powershell
# Download script first, then run with -DryRun
irm "https://api.github.com/repos/contractcooker/dotfiles/contents/scripts/setup-windows.ps1" -Headers @{Accept="application/vnd.github.v3.raw"} -OutFile setup-windows.ps1
.\setup-windows.ps1 -DryRun
.\setup-windows.ps1 -SetupProfile Work -DryRun
```

**Troubleshooting:** If repos fail to clone (SSH issues, corporate network):

```powershell
# Use direct HTTPS URLs (bypasses SSH entirely)
gh auth setup-git
cd $env:USERPROFILE\source\repos\dev
rm -r config, dotfiles -ErrorAction SilentlyContinue
git clone https://github.com/contractcooker/config.git
git clone https://github.com/contractcooker/dotfiles.git
```

**Fix PowerShell profile** (if not linked):

```powershell
# Find your repos location
$dotfiles = if (Test-Path "$env:USERPROFILE\source\repos") { "$env:USERPROFILE\source\repos\dev\dotfiles" } else { "$env:USERPROFILE\repos\dev\dotfiles" }
# Create profile directory and symlink
mkdir -Force (Split-Path $PROFILE)
New-Item -ItemType SymbolicLink -Path $PROFILE -Target "$dotfiles\home\Documents\PowerShell\Microsoft.PowerShell_profile.ps1" -Force
```

**Decommission** - Remove all repos, configs, and apps when returning a machine:

```powershell
.\scripts\decommission-windows.ps1 -DryRun   # Preview what will be removed
.\scripts\decommission-windows.ps1           # Interactive, confirm each step
```

See [Windows Setup](docs/windows-setup.md) for full guide.

## Contents

- `Brewfile` - Homebrew packages with [core] and [category] tags
- `home/` - Dotfiles symlinked to ~/ (.zshrc, .gitconfig, starship.toml)
- `claude/` - Claude Code global settings
- `scripts/` - Setup and maintenance scripts
- `docs/` - Strategy documentation

## Purpose

This repository contains cross-cutting development environment concerns that apply to all projects:

- SSH configuration and key management strategy
- Git global configuration
- Shell configuration
- Editor and tool preferences
- New machine setup automation

## Decommission

When returning a work machine or doing a clean slate, use the decommission script to remove all personal data:

```powershell
# Preview what will be removed
.\scripts\decommission-windows.ps1 -DryRun

# Interactive - confirms each step
.\scripts\decommission-windows.ps1

# Remove everything without prompts (use with caution)
.\scripts\decommission-windows.ps1 -All
```

**What it removes:**

| Step | Description |
|------|-------------|
| Repositories | `~/repos` and `~/source/repos` |
| Git config | `.gitconfig`, `.gitconfig.local`, credential cache |
| SSH config | `~/.ssh` directory |
| PowerShell | Profile symlink, Starship config |
| GitHub CLI | Logout and clear auth |
| Scoop | All packages and Scoop itself |
| Winget apps | Apps installed by setup script |
| Claude Code | Config directory and npm package |

**Manual steps required after:**
- Sign out of 1Password
- Clear browser data (history, passwords, cookies)
- Sign out of JetBrains IDEs
- Check Windows Credential Manager
- Review Documents/Desktop/Downloads for personal files

## Documentation

### Platform Setup
- [Windows Setup](docs/windows-setup.md) - Full Windows development environment guide

### Strategies
- [SSH Strategy](docs/ssh-strategy.md) - SSH key management and configuration approach
- [Package Management](docs/package-management.md) - Homebrew strategy and rationale
- [GitHub Config](docs/github-config.md) - Git and GitHub CLI configuration
- [Dropbox Sync](docs/dropbox-sync.md) - Cross-platform file sync setup
