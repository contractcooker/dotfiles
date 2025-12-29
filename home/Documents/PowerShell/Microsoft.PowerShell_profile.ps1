# =============================================================================
# PowerShell Profile
# =============================================================================
# This file is symlinked from ~/repos/dev/dotfiles/home/Documents/PowerShell/
# Edit there, not here.

# -----------------------------------------------------------------------------
# Version Managers
# -----------------------------------------------------------------------------

# fnm (Node.js version manager)
if (Get-Command fnm -ErrorAction SilentlyContinue) {
    fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression
}

# -----------------------------------------------------------------------------
# Prompt
# -----------------------------------------------------------------------------

# Starship prompt (https://starship.rs)
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}

# -----------------------------------------------------------------------------
# Aliases
# -----------------------------------------------------------------------------

# Git shortcuts
Set-Alias -Name g -Value git
function gs { git status $args }
function gd { git diff $args }
function gl { git log --oneline -20 $args }
function gp { git pull $args }

# Editor
if (Get-Command code -ErrorAction SilentlyContinue) {
    Set-Alias -Name c -Value code
}

# Navigation (PowerShell doesn't have cd shortcuts like bash)
function .. { Set-Location .. }
function ... { Set-Location ../.. }
function .... { Set-Location ../../.. }

# List files (ls is already aliased to Get-ChildItem)
function ll { Get-ChildItem -Force $args }

# Create directory and cd into it
function mkcd {
    param([string]$Path)
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
    Set-Location $Path
}

# Quick access to repos
function repos { Set-Location "$env:USERPROFILE\source\repos" }
function dev { Set-Location "$env:USERPROFILE\source\repos\dev" }
function dotfiles { Set-Location "$env:USERPROFILE\source\repos\dev\dotfiles" }

# Chris Titus Tech Windows Utility
function winutil { irm "https://christitus.com/win" | iex }

# -----------------------------------------------------------------------------
# Environment
# -----------------------------------------------------------------------------

# Add uv tools to PATH (Python CLI apps like pre-commit)
$uvPath = "$env:USERPROFILE\.local\bin"
if (Test-Path $uvPath) {
    $env:Path = "$uvPath;$env:Path"
}

# -----------------------------------------------------------------------------
# Local overrides (not version controlled)
# -----------------------------------------------------------------------------

# Source local config if it exists (for machine-specific settings)
$localProfile = "$env:USERPROFILE\.profile.local.ps1"
if (Test-Path $localProfile) {
    . $localProfile
}
