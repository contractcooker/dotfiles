# Bootstrap script to clone core repos with detailed diagnostics
# Tries multiple methods: SSH with pre-populated known_hosts, HTTPS fallback
#
# Usage:
#   irm "https://api.github.com/repos/contractcooker/dotfiles/contents/scripts/bootstrap-repos.ps1" -Headers @{Accept="application/vnd.github.v3.raw"} | iex

$ErrorActionPreference = "Continue"
$LogFile = "$env:TEMP\bootstrap-repos-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
Start-Transcript -Path $LogFile | Out-Null

Write-Host "Bootstrap Repos Script" -ForegroundColor Cyan
Write-Host "Log: $LogFile" -ForegroundColor DarkGray
Write-Host ""

# Determine repos location (OneDrive-aware)
if (Test-Path "$env:USERPROFILE\OneDrive*") {
    $ReposRoot = "$env:USERPROFILE\source\repos"
} else {
    $ReposRoot = "$env:USERPROFILE\repos"
}
Write-Host "Repos location: $ReposRoot" -ForegroundColor Cyan

# Diagnostics
Write-Host ""
Write-Host "=== DIAGNOSTICS ===" -ForegroundColor Yellow

Write-Host "1. Git version:"
git --version

Write-Host ""
Write-Host "2. GitHub CLI version:"
gh --version

Write-Host ""
Write-Host "3. GitHub CLI auth status:"
gh auth status

Write-Host ""
Write-Host "4. GitHub CLI git protocol:"
gh config get git_protocol

Write-Host ""
Write-Host "5. SSH directory contents:"
$sshDir = "$env:USERPROFILE\.ssh"
if (Test-Path $sshDir) {
    Get-ChildItem $sshDir -Force | ForEach-Object { Write-Host "   $($_.Name)" }
} else {
    Write-Host "   .ssh directory does not exist"
}

Write-Host ""
Write-Host "6. known_hosts content:"
$knownHosts = "$sshDir\known_hosts"
if (Test-Path $knownHosts) {
    Get-Content $knownHosts | ForEach-Object { Write-Host "   $_" }
} else {
    Write-Host "   known_hosts does not exist"
}

Write-Host ""
Write-Host "7. SSH config:"
$sshConfig = "$sshDir\config"
if (Test-Path $sshConfig) {
    Get-Content $sshConfig | ForEach-Object { Write-Host "   $_" }
} else {
    Write-Host "   SSH config does not exist"
}

Write-Host ""
Write-Host "8. Git global config (sshCommand):"
git config --global core.sshCommand

Write-Host ""
Write-Host "9. Existing repos in $ReposRoot\dev:"
$devDir = "$ReposRoot\dev"
if (Test-Path $devDir) {
    Get-ChildItem $devDir -Directory | ForEach-Object {
        $gitDir = Join-Path $_.FullName ".git"
        $hasGit = Test-Path $gitDir
        $fileCount = (Get-ChildItem $_.FullName -File -ErrorAction SilentlyContinue | Measure-Object).Count
        Write-Host "   $($_.Name): .git=$hasGit, files=$fileCount"
    }
} else {
    Write-Host "   dev directory does not exist"
}

Write-Host ""
Write-Host "10. Testing SSH connection to GitHub:"
$env:GIT_SSH_COMMAND = "C:/Windows/System32/OpenSSH/ssh.exe -o BatchMode=yes -o StrictHostKeyChecking=accept-new"
ssh -T git@github.com 2>&1 | ForEach-Object { Write-Host "   $_" }

# Try to set up known_hosts
Write-Host ""
Write-Host "=== SETTING UP KNOWN_HOSTS ===" -ForegroundColor Yellow

if (-not (Test-Path $sshDir)) {
    Write-Host "Creating .ssh directory..."
    New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
}

$githubKeys = @"
github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=
github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=
"@

# Try multiple methods to write known_hosts
Write-Host "Attempting to write known_hosts..."

# Method 1: Out-File
try {
    $githubKeys | Out-File -FilePath $knownHosts -Encoding utf8 -Force -ErrorAction Stop
    Write-Host "   Method 1 (Out-File): SUCCESS" -ForegroundColor Green
} catch {
    Write-Host "   Method 1 (Out-File): FAILED - $_" -ForegroundColor Red

    # Method 2: Set-Content
    try {
        Set-Content -Path $knownHosts -Value $githubKeys -Force -ErrorAction Stop
        Write-Host "   Method 2 (Set-Content): SUCCESS" -ForegroundColor Green
    } catch {
        Write-Host "   Method 2 (Set-Content): FAILED - $_" -ForegroundColor Red

        # Method 3: .NET
        try {
            [System.IO.File]::WriteAllText($knownHosts, $githubKeys)
            Write-Host "   Method 3 (.NET): SUCCESS" -ForegroundColor Green
        } catch {
            Write-Host "   Method 3 (.NET): FAILED - $_" -ForegroundColor Red

            # Method 4: Via temp file
            try {
                $tempFile = "$env:TEMP\known_hosts_temp"
                $githubKeys | Out-File -FilePath $tempFile -Encoding utf8 -Force
                Copy-Item $tempFile $knownHosts -Force -ErrorAction Stop
                Remove-Item $tempFile -Force
                Write-Host "   Method 4 (temp copy): SUCCESS" -ForegroundColor Green
            } catch {
                Write-Host "   Method 4 (temp copy): FAILED - $_" -ForegroundColor Red
                Write-Host "   ALL METHODS FAILED - SSH may prompt for host verification" -ForegroundColor Yellow
            }
        }
    }
}

# Verify known_hosts
Write-Host ""
Write-Host "Verifying known_hosts:"
if (Test-Path $knownHosts) {
    $content = Get-Content $knownHosts -Raw
    if ($content -match "github\.com") {
        Write-Host "   known_hosts contains GitHub keys" -ForegroundColor Green
    } else {
        Write-Host "   known_hosts exists but no GitHub keys found" -ForegroundColor Yellow
    }
} else {
    Write-Host "   known_hosts does not exist" -ForegroundColor Red
}

# Clean up broken repos
Write-Host ""
Write-Host "=== CLEANING UP BROKEN REPOS ===" -ForegroundColor Yellow

$configPath = "$ReposRoot\dev\config"
$dotfilesPath = "$ReposRoot\dev\dotfiles"

foreach ($repoPath in @($configPath, $dotfilesPath)) {
    if (Test-Path $repoPath) {
        $fileCount = (Get-ChildItem $repoPath -File -ErrorAction SilentlyContinue | Measure-Object).Count
        if ($fileCount -eq 0) {
            Write-Host "Removing empty repo: $repoPath"
            Remove-Item $repoPath -Recurse -Force
        } else {
            Write-Host "Repo has files, keeping: $repoPath ($fileCount files)"
        }
    }
}

# Ensure dev directory exists
if (-not (Test-Path "$ReposRoot\dev")) {
    New-Item -ItemType Directory -Path "$ReposRoot\dev" -Force | Out-Null
}

# Clone repos
Write-Host ""
Write-Host "=== CLONING REPOS ===" -ForegroundColor Yellow

# Set environment to auto-accept new host keys and use Windows SSH
$env:GIT_SSH_COMMAND = "C:/Windows/System32/OpenSSH/ssh.exe -o BatchMode=no -o StrictHostKeyChecking=accept-new"

# Try SSH first, fall back to HTTPS
function Clone-Repo {
    param([string]$Name)

    $targetPath = "$ReposRoot\dev\$Name"

    if (Test-Path $targetPath) {
        $fileCount = (Get-ChildItem $targetPath -File -ErrorAction SilentlyContinue | Measure-Object).Count
        if ($fileCount -gt 0) {
            Write-Host "$Name : Already exists with $fileCount files" -ForegroundColor Green
            return $true
        }
        Write-Host "$Name : Removing empty directory..."
        Remove-Item $targetPath -Recurse -Force
    }

    Push-Location "$ReposRoot\dev"

    # Method 1: gh clone with SSH
    Write-Host "$Name : Trying gh clone (SSH)..."
    $result = gh repo clone $Name 2>&1
    if ($LASTEXITCODE -eq 0 -and (Test-Path "$targetPath\*")) {
        Write-Host "$Name : SUCCESS via gh clone (SSH)" -ForegroundColor Green
        Pop-Location
        return $true
    }
    Write-Host "$Name : gh clone (SSH) failed: $result" -ForegroundColor Yellow

    # Clean up failed attempt
    if (Test-Path $targetPath) { Remove-Item $targetPath -Recurse -Force }

    # Method 2: gh clone with HTTPS
    Write-Host "$Name : Trying gh clone (HTTPS)..."
    gh config set git_protocol https 2>$null
    $result = gh repo clone $Name 2>&1
    gh config set git_protocol ssh 2>$null  # Reset to SSH
    if ($LASTEXITCODE -eq 0 -and (Test-Path "$targetPath\*")) {
        Write-Host "$Name : SUCCESS via gh clone (HTTPS)" -ForegroundColor Green
        Pop-Location
        return $true
    }
    Write-Host "$Name : gh clone (HTTPS) failed: $result" -ForegroundColor Yellow

    # Clean up failed attempt
    if (Test-Path $targetPath) { Remove-Item $targetPath -Recurse -Force }

    # Method 3: git clone with HTTPS URL directly
    Write-Host "$Name : Trying git clone (HTTPS URL)..."
    $ghUser = gh api user --jq '.login' 2>$null
    if ($ghUser) {
        git clone "https://github.com/$ghUser/$Name.git" 2>&1
        if ($LASTEXITCODE -eq 0 -and (Test-Path "$targetPath\*")) {
            Write-Host "$Name : SUCCESS via git clone (HTTPS)" -ForegroundColor Green
            Pop-Location
            return $true
        }
    }
    Write-Host "$Name : git clone (HTTPS) failed" -ForegroundColor Yellow

    # Clean up failed attempt
    if (Test-Path $targetPath) { Remove-Item $targetPath -Recurse -Force }

    Pop-Location
    Write-Host "$Name : ALL METHODS FAILED" -ForegroundColor Red
    return $false
}

$configOk = Clone-Repo "config"
$dotfilesOk = Clone-Repo "dotfiles"

# Summary
Write-Host ""
Write-Host "=== SUMMARY ===" -ForegroundColor Yellow
Write-Host "config:   $(if ($configOk) { 'OK' } else { 'FAILED' })" -ForegroundColor $(if ($configOk) { 'Green' } else { 'Red' })
Write-Host "dotfiles: $(if ($dotfilesOk) { 'OK' } else { 'FAILED' })" -ForegroundColor $(if ($dotfilesOk) { 'Green' } else { 'Red' })
Write-Host ""
Write-Host "Log saved to: $LogFile" -ForegroundColor Cyan

if ($configOk -and $dotfilesOk) {
    Write-Host ""
    Write-Host "SUCCESS! Now run the main setup script:" -ForegroundColor Green
    Write-Host '  irm "https://api.github.com/repos/contractcooker/dotfiles/contents/scripts/setup-windows.ps1" -Headers @{Accept="application/vnd.github.v3.raw"} | iex' -ForegroundColor White
}

Stop-Transcript | Out-Null
Write-Host ""
Write-Host "Please commit the log file to the dotfiles repo for troubleshooting:" -ForegroundColor Yellow
Write-Host "  Copy-Item $LogFile $ReposRoot\dev\dotfiles\" -ForegroundColor White
