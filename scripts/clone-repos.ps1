# Clone repos based on repos.json manifest
# Usage:
#   .\clone-repos.ps1                    # Clone active repos only
#   .\clone-repos.ps1 -IncludeParked     # Clone all repos including parked
#   .\clone-repos.ps1 -Status parked     # Clone only parked repos
#   .\clone-repos.ps1 -List              # Just list repos, don't clone

param(
    [string]$ReposRoot = "$HOME\repos",
    [switch]$IncludeParked,
    [string]$Status = "",
    [switch]$List
)

$configPath = Join-Path $ReposRoot "dev\config"
$manifestPath = Join-Path $configPath "repos.json"

if (-not (Test-Path $manifestPath)) {
    Write-Host "Error: repos.json not found at $manifestPath" -ForegroundColor Red
    exit 1
}

$manifest = Get-Content $manifestPath | ConvertFrom-Json

Write-Host "Repos Root: $ReposRoot" -ForegroundColor Cyan
Write-Host ""

$activeCount = 0
$parkedCount = 0
$clonedCount = 0
$skippedCount = 0

foreach ($repo in $manifest.repos) {
    # Filter by status
    if ($Status -and $repo.status -ne $Status) {
        continue
    }
    if (-not $IncludeParked -and -not $Status -and $repo.status -eq "parked") {
        $parkedCount++
        continue
    }

    $activeCount++

    if ($repo.folder) {
        $targetDir = Join-Path $ReposRoot $repo.folder
        $displayPath = Join-Path $repo.folder $repo.name
    } else {
        $targetDir = $ReposRoot
        $displayPath = $repo.name
    }

    $repoPath = Join-Path $targetDir $repo.name

    if ($List) {
        $statusIcon = if ($repo.status -eq "active") { "[active]" } else { "[parked]" }
        Write-Host "  $statusIcon $displayPath" -ForegroundColor $(if ($repo.status -eq "active") { "Green" } else { "DarkGray" })
        continue
    }

    # Create directory if needed
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    # Skip if already cloned
    if (Test-Path $repoPath) {
        Write-Host "  [skip] $displayPath (exists)" -ForegroundColor Yellow
        $skippedCount++
        continue
    }

    Write-Host "  [clone] $displayPath" -ForegroundColor Green
    Push-Location $targetDir
    $ErrorActionPreference = "SilentlyContinue"
    gh repo clone "contractcooker/$($repo.name)" *>$null
    $ErrorActionPreference = "Stop"
    Pop-Location
    $clonedCount++
}

Write-Host ""
if ($List) {
    Write-Host "Active: $activeCount repos" -ForegroundColor Green
    Write-Host "Parked: $parkedCount repos (use -IncludeParked to include)" -ForegroundColor DarkGray
} else {
    Write-Host "Cloned: $clonedCount | Skipped: $skippedCount | Parked: $parkedCount" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "To activate a parked repo, edit repos.json and change status to 'active'" -ForegroundColor DarkGray
