# Windows Setup

Development environment setup for Windows machines.

## Overview

This guide mirrors the macOS setup but uses Windows-native tools where appropriate. The goal is consistency across platforms where possible (1Password, gh CLI, git config, fnm, uv).

## Pre-Installation (Optional)

For a clean, debloated Windows 11 installation on unsupported hardware (like 7th gen Intel):

1. Create debloated ISO with MicroWin
2. Use Rufus to bypass TPM/CPU checks
3. Run winutil post-install for additional tweaks

See **[windows-preinstall.md](windows-preinstall.md)** for detailed instructions.

## Prerequisites

- Windows 10/11
- Admin access for initial setup
- 1Password account (for SSH keys)

## Quick Start

```powershell
# One-liner (run as Administrator)
irm https://raw.githubusercontent.com/contractcooker/dotfiles/main/scripts/setup-windows.ps1 -OutFile $env:TEMP\setup.ps1; & $env:TEMP\setup.ps1; rm $env:TEMP\setup.ps1
```

This will:
1. Install Scoop (package manager for CLI tools)
2. Install 1Password and configure SSH Agent
3. Install core tools: git, gh, jq, gum, fnm, uv, starship
4. Authenticate with GitHub (opens browser)
5. Clone config and dotfiles repos
6. Link dotfiles (PowerShell profile, starship config)
7. Install Node.js (via fnm) and Claude Code
8. Configure git and SSH from config repo values
9. Install Python (via uv)
10. Clone all repos from manifest
11. Offer optional package installation
12. Configure Windows preferences

## Package Management

We use two package managers:

| Manager | Purpose | Examples |
|---------|---------|----------|
| **Scoop** | CLI tools | git, gh, fnm, uv, starship, ollama |
| **winget** | GUI apps | 1Password, VS Code, Steam |

### Why both?

- **Scoop**: No admin required, cleaner uninstalls, better CLI ecosystem
- **winget**: Built-in, better for desktop applications

### Core Packages

Installed automatically via `setup-windows.ps1`:

```
Scoop: git, gh, jq, gum, fnm, uv, starship
Winget: 1Password, Dropbox, Windows Terminal
```

### Optional Packages

Interactive selection via `install-packages.ps1`:

```powershell
.\install-packages.ps1        # Interactive mode
.\install-packages.ps1 -All   # Install everything
```

Packages are defined in `Winfile` (like macOS Brewfile).

## Individual Scripts

Run standalone if needed:

```powershell
# Full setup (interactive)
.\scripts\setup-windows.ps1

# Package installation only
.\scripts\install-packages.ps1

# Windows preferences only
.\scripts\configure-windows.ps1

# Verify environment
.\scripts\verify-setup.ps1

# Clone all repos from manifest
.\scripts\clone-repos.ps1
```

## Shell Configuration

### PowerShell + Starship

Primary shell is PowerShell with starship prompt for a modern experience:

```powershell
# Profile location
$PROFILE  # Usually: Documents\PowerShell\Microsoft.PowerShell_profile.ps1
```

Profile includes:
- Starship prompt initialization
- fnm auto-switching for Node versions
- Git aliases (gs, gd, gl, gp)
- Navigation shortcuts (.., ..., repos, dotfiles)

### Git Bash

Available when you need Unix-like commands. Installed with Git.

## SSH Configuration

### 1Password SSH Agent

Same strategy as macOS - 1Password manages all SSH keys.

**Enable in 1Password:**
1. Open 1Password → Settings → Developer
2. Enable "Use the SSH Agent"

**SSH config** is auto-generated using the Windows named pipe:
```
Host *
  IdentityAgent "\\.\pipe\openssh-ssh-agent"
```

### Verify SSH

```powershell
ssh -T git@github.com
# Should see: "Hi <username>! You've successfully authenticated..."
```

## Git Configuration

Git config is set automatically from `config/identity.json`. Windows-specific settings:

```powershell
git config --global core.autocrlf true          # CRLF handling
git config --global core.sshCommand "C:/Windows/System32/OpenSSH/ssh.exe"  # 1Password compatibility
```

## Directory Structure

Same as macOS:

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

## Windows Preferences

Configure via `configure-windows.ps1`:

**Dev Settings:**
- File Explorer: show extensions, hidden files
- Git: autocrlf, Windows OpenSSH
- Power plan: High Performance

**Debloat:**
- Disable telemetry and ads
- Disable Cortana
- Keep Xbox Game Bar (for gaming)

**Personal:**
- Dark mode
- Taskbar cleanup
- Disable mouse acceleration

## Gaming Rig (3080 Ti)

For systems with NVIDIA GPUs:

```powershell
# Install GeForce Experience for driver updates
winget install Nvidia.GeForceExperience

# Install Ollama for local LLMs (uses CUDA automatically)
scoop install ollama

# Run a model
ollama run llama2
```

## Platform Differences

| Aspect | macOS | Windows |
|--------|-------|---------|
| Package manager | Homebrew | Scoop + winget |
| Shell | zsh | PowerShell |
| SSH agent socket | `~/Library/.../agent.sock` | `\\.\pipe\openssh-ssh-agent` |
| Line endings | LF | CRLF (git handles) |
| Profile | `.zshrc` | `Microsoft.PowerShell_profile.ps1` |

## Claude Code on Windows

Claude Code works on Windows but has some quirks:

**CRLF Issues**: The Edit tool may fail with "unexpectedly modified" errors. Workarounds are documented in `~/.claude/CLAUDE.md`:
- Use `sed -i` for single-line changes
- Use heredocs to rewrite entire files
- Use PowerShell for complex .ps1 edits

## Troubleshooting

### SSH not using 1Password

1. Verify 1Password SSH Agent is enabled in settings
2. Check `~\.ssh\config` has correct `IdentityAgent` path
3. Restart terminal after enabling agent
4. Ensure Windows OpenSSH Agent service is disabled:
   ```powershell
   Get-Service ssh-agent
   # Should show: Status = Stopped, StartType = Disabled
   ```

### Git push fails with permission denied

```powershell
# Verify SSH works
ssh -T git@github.com

# Check gh auth status
gh auth status

# Re-authenticate if needed
gh auth login --web --git-protocol ssh --skip-ssh-key
```

### Scoop commands fail

```powershell
# Update Scoop
scoop update

# Reset a package
scoop reset <package>

# Check for issues
scoop checkup
```

### winget not found

- Windows 11: Should be built-in
- Windows 10: Install "App Installer" from Microsoft Store

## References

- [Scoop](https://scoop.sh/)
- [winget](https://docs.microsoft.com/en-us/windows/package-manager/winget/)
- [1Password SSH Agent - Windows](https://developer.1password.com/docs/ssh/get-started/#step-3-turn-on-the-1password-ssh-agent)
- [Starship Prompt](https://starship.rs/)
- [fnm - Fast Node Manager](https://github.com/Schniz/fnm)
- [uv - Python Manager](https://github.com/astral-sh/uv)
