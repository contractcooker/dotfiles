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
irm https://raw.githubusercontent.com/contractcooker/dotfiles/main/scripts/setup-windows.ps1 -OutFile $env:TEMP\setup.ps1; & $env:TEMP\setup.ps1; rm $env:TEMP\setup.ps1
```

## Commands

```bash
# Full setup (interactive)
~/repos/dev/dotfiles/scripts/setup-mac.sh

# Individual scripts (can run standalone)
~/repos/dev/dotfiles/scripts/install-packages.sh   # Homebrew packages
~/repos/dev/dotfiles/scripts/configure-dev.sh      # Git, SSH, Node, Python
~/repos/dev/dotfiles/scripts/configure-macos.sh    # macOS preferences
~/repos/dev/dotfiles/scripts/verify-setup.sh       # Verify environment

# Clone all repos from manifest
~/repos/dev/dotfiles/scripts/clone-repos.sh

# Create a new GitHub repo (run from repo root after initial commit)
~/repos/dev/dotfiles/scripts/gh-create <repo-name> [description]
```

## Structure

- `Brewfile` - Homebrew package manifest (core + optional packages)
- `scripts/`
  - `setup-mac.sh` - Main orchestrator (calls other scripts)
  - `install-packages.sh` - Interactive Homebrew package installer (uses gum)
  - `configure-dev.sh` - Dev environment (Git, SSH, Node/fnm, Python/uv, Claude)
  - `configure-macos.sh` - macOS system preferences (dev + personal sections)
  - `verify-setup.sh` - Environment health check
  - `setup-windows.ps1` - Windows bootstrap
  - `clone-repos.sh` / `clone-repos.ps1` - Clone repos from manifest
  - `gh-create` - Create new GitHub repos with standard settings
- `claude/` - Claude Code settings
  - `global.md` - Global Claude settings (copied to ~/.claude/CLAUDE.md)
- `docs/` - Strategy documentation
  - `dropbox-sync.md` - Cross-platform file sync
  - `ssh-strategy.md` - SSH key management (1Password)
  - `package-management.md` - Homebrew rationale
  - `github-config.md` - Git and GitHub CLI config
  - `windows-setup.md` - Windows development environment guide

## Relationship to config repo

This repo contains **scripts and templates**. The private `config` repo contains **personal values**:

| dotfiles (public) | config (private) |
|-------------------|------------------|
| setup-mac.sh | identity.json (name, email) |
| setup-windows.ps1 | repos.json (repo manifest) |
| clone-repos.sh | hosts.json (domains) |

Scripts read from `config` to personalize setup.

## Key Conventions

- **Package management**: Homebrew on macOS, winget on Windows
- **SSH**: All SSH keys managed via 1Password SSH agent on both platforms
- **Git commits**: No AI attribution or co-author tags in commit messages
- **New repos**: Use `gh-create` script (auto-updates config/repos.json)
- **Directory structure**: `~/repos/dev/`, `~/repos/personal/`, `~/repos/everything/`
