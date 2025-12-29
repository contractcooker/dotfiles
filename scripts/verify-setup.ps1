# Verify Windows Development Environment Setup
#
# Run this after setup-windows.ps1 to confirm everything is working,
# or anytime to check the health of your development environment.

$ReposRoot = "C:\source\repos"
$ConfigPath = "$ReposRoot\dev\config"
$DotfilesPath = "$ReposRoot\dev\dotfiles"

$Pass = 0
$Fail = 0
$Warn = 0

function Write-Pass {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
    $script:Pass++
}

function Write-Fail {
    param([string]$Message)
    Write-Host "[FAIL] $Message" -ForegroundColor Red
    $script:Fail++
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
    $script:Warn++
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  Environment Verification" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Package Management
Write-Host "==> Package Management" -ForegroundColor White

if (Get-Command scoop -ErrorAction SilentlyContinue) {
    Write-Pass "Scoop installed"
} else {
    Write-Fail "Scoop not installed"
}

if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Pass "winget installed"
} else {
    Write-Fail "winget not installed"
}

# Core CLI Tools
Write-Host ""
Write-Host "==> Core Tools" -ForegroundColor White

$coreTools = @("git", "gh", "jq", "gum")
foreach ($tool in $coreTools) {
    if (Get-Command $tool -ErrorAction SilentlyContinue) {
        Write-Pass "$tool installed"
    } else {
        Write-Fail "$tool not installed"
    }
}

# fnm and Node
Write-Host ""
Write-Host "==> Node.js" -ForegroundColor White

if (Get-Command fnm -ErrorAction SilentlyContinue) {
    Write-Pass "fnm installed"

    # Initialize fnm for this shell
    fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression 2>$null

    if (Get-Command node -ErrorAction SilentlyContinue) {
        $nodeVersion = node --version 2>$null
        $nodePath = (Get-Command node).Source

        if ($nodePath -match "fnm") {
            Write-Pass "Node $nodeVersion (via fnm)"
        } else {
            Write-Warn "Node $nodeVersion found but not via fnm ($nodePath)"
        }
    } else {
        Write-Fail "Node not installed (run: fnm install --lts)"
    }
} else {
    Write-Fail "fnm not installed"
}

# uv and Python
Write-Host ""
Write-Host "==> Python" -ForegroundColor White

if (Get-Command uv -ErrorAction SilentlyContinue) {
    Write-Pass "uv installed"

    $pythonList = uv python list --only-installed 2>$null
    if ($pythonList -match "cpython") {
        $pythonVersion = ($pythonList | Select-Object -First 1) -split "\s+" | Select-Object -First 1
        Write-Pass "Python $pythonVersion (via uv)"
    } else {
        Write-Fail "Python not installed (run: uv python install)"
    }

    $precommit = uv tool list 2>$null | Select-String "pre-commit"
    if ($precommit) {
        Write-Pass "pre-commit installed (via uv)"
    } else {
        Write-Warn "pre-commit not installed (run: uv tool install pre-commit)"
    }
} else {
    Write-Fail "uv not installed"
}

# Claude Code
Write-Host ""
Write-Host "==> Claude Code" -ForegroundColor White

if (Get-Command claude -ErrorAction SilentlyContinue) {
    Write-Pass "Claude Code installed"
} else {
    Write-Fail "Claude Code not installed (run: npm install -g @anthropic-ai/claude-code)"
}

$claudeSettings = "$env:USERPROFILE\.claude\CLAUDE.md"
if (Test-Path $claudeSettings) {
    Write-Pass "Claude global settings configured"
} else {
    Write-Warn "Claude global settings not found (~\.claude\CLAUDE.md)"
}

# Git Configuration
Write-Host ""
Write-Host "==> Git Configuration" -ForegroundColor White

$gitName = git config user.name 2>$null
$gitEmail = git config user.email 2>$null

if ($gitName) {
    Write-Pass "Git user.name: $gitName"
} else {
    Write-Fail "Git user.name not set"
}

if ($gitEmail) {
    Write-Pass "Git user.email: $gitEmail"
} else {
    Write-Fail "Git user.email not set"
}

$autocrlf = git config core.autocrlf 2>$null
if ($autocrlf -eq "true") {
    Write-Pass "Git core.autocrlf: true"
} else {
    Write-Warn "Git core.autocrlf not set to true (CRLF issues possible)"
}

# GitHub CLI
Write-Host ""
Write-Host "==> GitHub CLI" -ForegroundColor White

$ghStatus = gh auth status 2>&1
if ($LASTEXITCODE -eq 0) {
    $ghUser = gh api user --jq '.login' 2>$null
    Write-Pass "GitHub authenticated as $ghUser"
} else {
    Write-Fail "GitHub CLI not authenticated (run: gh auth login)"
}

# SSH
Write-Host ""
Write-Host "==> SSH Configuration" -ForegroundColor White

$sshConfig = "$env:USERPROFILE\.ssh\config"
if (Test-Path $sshConfig) {
    Write-Pass "SSH config exists"

    $sshContent = Get-Content $sshConfig -Raw
    if ($sshContent -match "openssh-ssh-agent") {
        Write-Pass "1Password SSH agent configured"
    } else {
        Write-Warn "1Password SSH agent not in SSH config"
    }
} else {
    Write-Fail "SSH config not found (~\.ssh\config)"
}

# Test GitHub SSH connection
Write-Host ""
Write-Host "==> SSH Connectivity" -ForegroundColor White

$sshOutput = ssh -T git@github.com 2>&1
if ($sshOutput -match "successfully authenticated") {
    $ghSshUser = $sshOutput -replace ".*Hi ([^!]+).*", '$1'
    Write-Pass "GitHub SSH working ($ghSshUser)"
} else {
    Write-Fail "GitHub SSH not working (check 1Password SSH agent)"
    Write-Host "      Response: $sshOutput" -ForegroundColor DarkGray
}

# Repos
Write-Host ""
Write-Host "==> Repository Structure" -ForegroundColor White

if (Test-Path $ConfigPath) {
    Write-Pass "Config repo exists"
} else {
    Write-Fail "Config repo not found ($ConfigPath)"
}

if (Test-Path $DotfilesPath) {
    Write-Pass "Dotfiles repo exists"
} else {
    Write-Fail "Dotfiles repo not found ($DotfilesPath)"
}

if (Test-Path $ReposRoot) {
    $repoCount = (Get-ChildItem -Path $ReposRoot -Recurse -Directory -Filter ".git" -Depth 3).Count
    Write-Pass "$repoCount repositories in ~/repos/"
}

# NVIDIA (for 3080 Ti)
Write-Host ""
Write-Host "==> Graphics (3080 Ti)" -ForegroundColor White

$nvidia = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -match "NVIDIA" }
if ($nvidia) {
    Write-Pass "NVIDIA GPU: $($nvidia.Name)"

    $nvidiaDriver = $nvidia.DriverVersion
    if ($nvidiaDriver) {
        Write-Pass "Driver version: $nvidiaDriver"
    }
} else {
    Write-Warn "NVIDIA GPU not detected"
}

# Check for Ollama (local LLMs)
if (Get-Command ollama -ErrorAction SilentlyContinue) {
    Write-Pass "Ollama installed (local LLMs ready)"
} else {
    Write-Warn "Ollama not installed (optional: scoop install ollama)"
}

# PowerShell Profile
Write-Host ""
Write-Host "==> Shell Configuration" -ForegroundColor White

if (Test-Path $PROFILE) {
    Write-Pass "PowerShell profile exists"

    $profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
    if ($profileContent -match "starship") {
        Write-Pass "Starship prompt configured"
    } else {
        Write-Warn "Starship not in profile"
    }

    if ($profileContent -match "fnm") {
        Write-Pass "fnm configured in profile"
    } else {
        Write-Warn "fnm not in profile"
    }
} else {
    Write-Warn "PowerShell profile not found"
}

# Windows Settings (spot check)
Write-Host ""
Write-Host "==> Windows Settings" -ForegroundColor White

$hideExt = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt").HideFileExt
if ($hideExt -eq 0) {
    Write-Pass "Show file extensions enabled"
} else {
    Write-Warn "Show file extensions disabled"
}

$darkMode = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -ErrorAction SilentlyContinue).AppsUseLightTheme
if ($darkMode -eq 0) {
    Write-Pass "Dark mode enabled"
} else {
    Write-Warn "Dark mode not enabled"
}

# Summary
Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  Summary" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Passed:   $Pass" -ForegroundColor Green
Write-Host "  Failed:   $Fail" -ForegroundColor Red
Write-Host "  Warnings: $Warn" -ForegroundColor Yellow
Write-Host ""

if ($Fail -eq 0) {
    Write-Host "  Environment looks good!" -ForegroundColor Green
} else {
    Write-Host "  Some checks failed. Review above for details." -ForegroundColor Yellow
}
Write-Host ""
