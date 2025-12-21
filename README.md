# Dotfiles

Personal development environment configuration and setup scripts.

## Quick Start

### macOS

```bash
# One-liner
curl -fsSL https://raw.githubusercontent.com/contractcooker/dotfiles/main/scripts/setup-mac.sh | bash
```

This installs Homebrew, Git, GitHub CLI, configures git, authenticates with GitHub, and clones all active repos.

### Windows

```powershell
# One-liner (run as Administrator)
irm "https://raw.githubusercontent.com/contractcooker/dotfiles/main/scripts/setup-windows.ps1?v=$(Get-Date -Format 'yyyyMMddHHmmss')" -OutFile $env:TEMP\setup.ps1; & $env:TEMP\setup.ps1; rm $env:TEMP\setup.ps1
```

This installs Git, GitHub CLI, Windows Terminal, configures git, authenticates with GitHub, and clones all active repos.

See [Windows Setup](docs/windows-setup.md) for full guide.

## Contents

- `docs/` - Documentation for development environment strategies
- `ssh/` - SSH configuration files and templates
- `git/` - Git configuration files
- `scripts/` - Setup and maintenance scripts

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
