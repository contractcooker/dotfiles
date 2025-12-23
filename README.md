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
# Run as Administrator (API URL to avoid CDN caching during development)
(irm "https://api.github.com/repos/contractcooker/dotfiles/contents/scripts/setup-windows.ps1" -Headers @{Accept="application/vnd.github.v3.raw"}) | iex
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

## Documentation

### Platform Setup
- [Windows Setup](docs/windows-setup.md) - Full Windows development environment guide

### Strategies
- [SSH Strategy](docs/ssh-strategy.md) - SSH key management and configuration approach
- [Package Management](docs/package-management.md) - Homebrew strategy and rationale
- [GitHub Config](docs/github-config.md) - Git and GitHub CLI configuration
- [Dropbox Sync](docs/dropbox-sync.md) - Cross-platform file sync setup
