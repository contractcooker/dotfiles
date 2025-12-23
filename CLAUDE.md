# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

Public dotfiles repository containing development environment scripts and templates for macOS and Windows. Personal configuration values (identity, repo list, hosts) are stored separately in the private `config` repo.

## Quick Start

### macOS
```bash
curl -fsSL https://raw.githubusercontent.com/contractcooker/dotfiles/main/scripts/setup-mac.sh | bash
```

### Windows (PowerShell as Admin)
```powershell
irm https://raw.githubusercontent.com/contractcooker/dotfiles/main/scripts/setup-windows.ps1 | iex
```

## Commands

### macOS
```bash
~/repos/dev/dotfiles/scripts/setup-mac.sh          # Full setup (interactive)
~/repos/dev/dotfiles/scripts/install-packages.sh   # Homebrew packages
~/repos/dev/dotfiles/scripts/configure-dev.sh      # Git, SSH, Node, Python
~/repos/dev/dotfiles/scripts/configure-macos.sh    # macOS preferences
~/repos/dev/dotfiles/scripts/verify-setup.sh       # Verify environment
~/repos/dev/dotfiles/scripts/clone-repos.sh        # Clone repos from manifest
~/repos/dev/dotfiles/scripts/gh-create <name>      # Create new GitHub repo
```

### Windows (PowerShell)
```powershell
.\scripts\setup-windows.ps1       # Full setup (interactive)
.\scripts\install-packages.ps1    # Scoop + winget packages
.\scripts\configure-windows.ps1   # Windows preferences
.\scripts\verify-setup.ps1        # Verify environment
.\scripts\clone-repos.ps1         # Clone repos from manifest
```

## Structure

- `Brewfile` - macOS Homebrew package manifest
- `Winfile` - Windows Scoop + winget package manifest
- `scripts/`
  - **macOS**:
    - `setup-mac.sh` - Main orchestrator
    - `install-packages.sh` - Interactive Homebrew installer (uses gum)
    - `configure-dev.sh` - Git, SSH, Node/fnm, Python/uv, Claude
    - `configure-macos.sh` - macOS preferences (dev + personal)
    - `verify-setup.sh` - Environment health check
    - `clone-repos.sh` - Clone repos from manifest
    - `link-dotfiles.sh` - Symlink home/* to ~
  - **Windows**:
    - `setup-windows.ps1` - Main orchestrator
    - `install-packages.ps1` - Interactive Scoop + winget installer
    - `configure-windows.ps1` - Windows preferences (dev + debloat + personal)
    - `verify-setup.ps1` - Environment health check
    - `clone-repos.ps1` - Clone repos from manifest
  - **Shared**:
    - `gh-create` - Create new GitHub repos
- `home/` - Dotfiles to symlink
  - `.zshrc`, `.gitconfig` - macOS shell/git config
  - `.config/starship.toml` - Cross-platform prompt
  - `Documents/PowerShell/Microsoft.PowerShell_profile.ps1` - Windows shell
- `claude/` - Claude Code settings
  - `global.md` - Global settings (copied to ~/.claude/CLAUDE.md)
  - `windows.md` - Windows-specific workarounds
- `docs/` - Strategy documentation
  - `windows-preinstall.md` - Microwin + winutil for debloated Windows
  - `windows-setup.md` - Windows development guide
  - `dropbox-sync.md` - Cross-platform file sync
  - `ssh-strategy.md` - 1Password SSH management

## Relationship to config repo

This repo contains **scripts and templates**. The private `config` repo contains **personal values**:

| dotfiles (public) | config (private) |
|-------------------|------------------|
| setup-mac.sh | identity.json (name, email) |
| setup-windows.ps1 | repos.json (repo manifest) |
| clone-repos.sh | hosts.json (domains) |

Scripts read from `config` to personalize setup.

## Key Conventions

- **Package management**: Homebrew on macOS; Scoop (CLI) + winget (GUI) on Windows
- **Version managers**: fnm for Node.js, uv for Python (both platforms)
- **SSH**: All SSH keys managed via 1Password SSH agent on both platforms
- **Git commits**: No AI attribution or co-author tags in commit messages
- **New repos**: Use `gh-create` script (auto-updates config/repos.json)
- **Directory structure**: `~/repos/dev/`, `~/repos/personal/`, `~/repos/everything/`
