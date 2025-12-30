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

**Troubleshooting:** If repos fail to clone (SSH issues, corporate network):

```powershell
# Step 1: Add GitHub SSH keys to known_hosts (run this first if prompted for host authenticity)
mkdir -Force $env:USERPROFILE\.ssh
@"
github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=
"@ | Out-File -Encoding utf8 -FilePath $env:USERPROFILE\.ssh\known_hosts

# Step 2: Clone repos
cd $env:USERPROFILE\source\repos\dev
rm -r config, dotfiles -ErrorAction SilentlyContinue
gh repo clone config
gh repo clone dotfiles

# Alternative: Run bootstrap script for full diagnostics
irm "https://api.github.com/repos/contractcooker/dotfiles/contents/scripts/bootstrap-repos.ps1" -Headers @{Accept="application/vnd.github.v3.raw"} | iex
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
