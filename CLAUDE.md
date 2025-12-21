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
# Install all packages from Brewfile (macOS)
brew bundle --file=~/repos/dev/dotfiles/Brewfile

# Clone all repos from manifest
~/repos/dev/dotfiles/scripts/clone-repos.sh

# Create a new GitHub repo (run from repo root after initial commit)
~/repos/dev/dotfiles/scripts/gh-create <repo-name> [description]
```

## Structure

- `Brewfile` - Homebrew package manifest (macOS)
- `scripts/`
  - `setup-mac.sh` - macOS bootstrap (one-liner)
  - `setup-windows.ps1` - Windows bootstrap (one-liner)
  - `clone-repos.sh` / `clone-repos.ps1` - Clone repos from manifest
  - `gh-create` - Create new GitHub repos with standard settings
- `docs/` - Strategy documentation
  - `windows-setup.md` - Windows development environment guide
  - `ssh-strategy.md` - SSH key management (1Password)
  - `package-management.md` - Homebrew rationale
  - `github-config.md` - Git and GitHub CLI config

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
