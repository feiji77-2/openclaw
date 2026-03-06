param(
    [string]$RepoPath = "C:\Users\32480\openclaw-cn",
    [string]$Remote = "gitee",
    [switch]$NoWatch,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Assert-Command([string]$name) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
        throw "Required command not found: $name"
    }
}

function Get-LockHash([string]$repo) {
    $lock = Join-Path $repo "pnpm-lock.yaml"
    if (-not (Test-Path $lock)) {
        return ""
    }
    return (Get-FileHash -Algorithm SHA256 -Path $lock).Hash
}

function Run-Git([string]$repo, [string[]]$gitArgs) {
    & git -C $repo @gitArgs
    if ($LASTEXITCODE -ne 0) {
        throw "git command failed: git -C `"$repo`" $($gitArgs -join ' ')"
    }
}

Assert-Command git
Assert-Command pnpm

$userContent = "C:\Users\32480\.openclaw"
$workspaceContent = "C:\Users\32480\clawd"
$statePath = Join-Path $userContent "source-update-state.json"
$lastInstalledLockHash = ""

if (Test-Path $statePath) {
    try {
        $stateRaw = Get-Content -Path $statePath -Raw
        if (-not [string]::IsNullOrWhiteSpace($stateRaw)) {
            $stateObj = $stateRaw | ConvertFrom-Json
            if ($stateObj.lastInstalledLockHash) {
                $lastInstalledLockHash = [string]$stateObj.lastInstalledLockHash
            }
        }
    }
    catch {
        Write-Host "Warning: failed to parse $statePath, continuing without state."
    }
}

if (-not (Test-Path $RepoPath)) {
    throw "Repo not found: $RepoPath"
}

$repoResolved = (Resolve-Path $RepoPath).Path.TrimEnd('\')
foreach ($path in @($userContent, $workspaceContent)) {
    $resolved = (Resolve-Path $path).Path.TrimEnd('\')
    if ($resolved.StartsWith($repoResolved, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Content path should not live inside source repo: $resolved"
    }
}

Write-Host "Policy confirmed:"
Write-Host "  - content: $workspaceContent"
Write-Host "  - config/state: $userContent"
Write-Host "  - source code only: $RepoPath"

$branch = (& git -C $RepoPath rev-parse --abbrev-ref HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($branch)) {
    throw "Failed to detect current git branch."
}

$remoteExists = (& git -C $RepoPath remote) -contains $Remote
if (-not $remoteExists) {
    if ((& git -C $RepoPath remote) -contains "origin") {
        $Remote = "origin"
    }
    else {
        throw "Neither remote '$Remote' nor 'origin' exists."
    }
}

$lockBefore = Get-LockHash $RepoPath
$stashCreated = $false
$stashMarker = "auto-stash-openclaw-update-$(Get-Date -Format yyyyMMdd-HHmmss)"

$status = (& git -C $RepoPath status --porcelain)
if ($status) {
    Write-Host "Local changes detected, creating temporary stash..."
    if (-not $DryRun) {
        Run-Git $RepoPath @("stash", "push", "-u", "-m", $stashMarker)
    }
    $stashCreated = $true
}

Write-Host "Updating source: git pull --ff-only $Remote $branch"
if (-not $DryRun) {
    try {
        Run-Git $RepoPath @("pull", "--ff-only", $Remote, $branch)
    }
    catch {
        if ($stashCreated) {
            Write-Host "Pull failed, restoring stashed changes..."
            & git -C $RepoPath stash pop | Out-Host
        }
        throw
    }
}

$lockAfter = if ($DryRun) { $lockBefore } else { Get-LockHash $RepoPath }

if ($stashCreated) {
    Write-Host "Restoring stashed changes..."
    if (-not $DryRun) {
        & git -C $RepoPath stash pop | Out-Host
        if ($LASTEXITCODE -ne 0) {
            throw "stash pop failed. Resolve conflicts in $RepoPath before continuing."
        }
    }
}

$nodeModulesExists = Test-Path (Join-Path $RepoPath "node_modules")
$hasKnownLockHash = -not [string]::IsNullOrWhiteSpace($lastInstalledLockHash)
$needsInstall = (-not $nodeModulesExists) -or ($hasKnownLockHash -and [string]::IsNullOrWhiteSpace($lockAfter) -eq $false -and $lockAfter -ne $lastInstalledLockHash)
if ($needsInstall) {
    Write-Host "Lockfile changed (or node_modules missing): pnpm install"
    if (-not $DryRun) {
        & pnpm --config.manage-package-manager-versions=false --dir $RepoPath install
        if ($LASTEXITCODE -ne 0) {
            throw "pnpm install failed."
        }

        $state = [ordered]@{
            repoPath = $RepoPath
            lastInstalledLockHash = $lockAfter
            updatedAt = (Get-Date).ToString("o")
        }
        $stateJson = $state | ConvertTo-Json -Depth 5
        [System.IO.File]::WriteAllText($statePath, $stateJson, [System.Text.Encoding]::UTF8)
        Write-Host "Recorded install state: $statePath"
    }
}
else {
    Write-Host "Lockfile unchanged: skip pnpm install"
    if (-not $DryRun -and $nodeModulesExists -and -not [string]::IsNullOrWhiteSpace($lockAfter) -and -not $hasKnownLockHash) {
        $state = [ordered]@{
            repoPath = $RepoPath
            lastInstalledLockHash = $lockAfter
            updatedAt = (Get-Date).ToString("o")
        }
        $stateJson = $state | ConvertTo-Json -Depth 5
        [System.IO.File]::WriteAllText($statePath, $stateJson, [System.Text.Encoding]::UTF8)
        Write-Host "Recorded initial lock hash state: $statePath"
    }
}

if (-not $NoWatch) {
        Write-Host "Starting gateway with pnpm gateway:watch ..."
    if (-not $DryRun) {
        Start-Process -FilePath "cmd.exe" -ArgumentList "/k","cd /d $RepoPath && pnpm --config.manage-package-manager-versions=false gateway:watch" | Out-Null
    }
}

if ($DryRun) {
    Write-Host "Dry run complete."
}
else {
    Write-Host "Update complete."
}
