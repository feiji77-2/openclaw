[CmdletBinding()]
param(
  [string]$RepoPath = "",
  [string]$Branch = "main",
  [string]$UpstreamRemote = "upstream",
  [string]$UpstreamBranch = "main",
  [string[]]$PushRemotes = @("origin", "gitee"),
  [switch]$NoPush,
  [switch]$SkipFetch,
  [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($RepoPath)) {
  $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
  $RepoPath = (Resolve-Path (Join-Path $scriptDir "..")).Path
}

function Invoke-Git {
  param(
    [Parameter(Mandatory = $true)][string[]]$Args,
    [switch]$AllowFail
  )

  $full = @("-C", $RepoPath) + $Args
  if ($DryRun) {
    Write-Host ("[dry-run] git " + ($full -join " "))
    return @{ Code = 0; Output = @() }
  }

  $output = & git @full 2>&1
  $code = $LASTEXITCODE
  if ($output) {
    $output | ForEach-Object { Write-Host $_ }
  }

  if (-not $AllowFail -and $code -ne 0) {
    throw ("git failed ({0}): git {1}" -f $code, ($full -join " "))
  }

  return @{ Code = $code; Output = $output }
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  throw "git is not available in PATH."
}

if (-not (Test-Path $RepoPath)) {
  throw ("RepoPath not found: {0}" -f $RepoPath)
}

$gitDirCheck = Invoke-Git -Args @("rev-parse", "--git-dir") -AllowFail
if ($gitDirCheck.Code -ne 0) {
  throw ("Not a git repository: {0}" -f $RepoPath)
}

$dirtyTracked = & git -C $RepoPath status --porcelain --untracked-files=no
if ($dirtyTracked) {
  throw "Tracked file changes detected. Commit or stash tracked changes before syncing."
}

$currentBranch = (& git -C $RepoPath rev-parse --abbrev-ref HEAD).Trim()
if ($currentBranch -ne $Branch) {
  Invoke-Git -Args @("switch", $Branch)
}

if ($SkipFetch) {
  Write-Host "Skip fetch requested."
}
else {
  Write-Host ("Fetching {0}..." -f $UpstreamRemote)
  $fetchResult = Invoke-Git -Args @("fetch", $UpstreamRemote, "--prune") -AllowFail
  if ($fetchResult.Code -ne 0) {
    throw @"
Failed to fetch upstream.
If this is a certificate issue on your machine, verify your corporate/root CA setup first.
As a temporary workaround only, you can run:
  git config --global http.https://github.com.sslVerify false
and re-run this script.
"@
  }
}

$verifyRef = Invoke-Git -Args @("rev-parse", "--verify", ("{0}/{1}" -f $UpstreamRemote, $UpstreamBranch)) -AllowFail
if ($verifyRef.Code -ne 0) {
  throw ("Upstream ref not found: {0}/{1}" -f $UpstreamRemote, $UpstreamBranch)
}

Write-Host ("Merging {0}/{1} -> {2}..." -f $UpstreamRemote, $UpstreamBranch, $Branch)
$ffMerge = Invoke-Git -Args @("merge", "--ff-only", ("{0}/{1}" -f $UpstreamRemote, $UpstreamBranch)) -AllowFail
if ($ffMerge.Code -ne 0) {
  Write-Host "Fast-forward not possible. Trying regular merge..."
  $regularMerge = Invoke-Git -Args @("merge", "--no-edit", ("{0}/{1}" -f $UpstreamRemote, $UpstreamBranch)) -AllowFail
  if ($regularMerge.Code -ne 0) {
    throw @"
Merge failed (likely conflicts).
Resolve conflicts manually, then run:
  git add <resolved files>
  git merge --continue
"@
  }
}

if ($NoPush) {
  Write-Host "NoPush set. Skip pushing remotes."
  exit 0
}

$pushFailures = New-Object System.Collections.Generic.List[string]
foreach ($remote in $PushRemotes) {
  $exists = Invoke-Git -Args @("remote", "get-url", $remote) -AllowFail
  if ($exists.Code -ne 0) {
    Write-Warning ("Remote not found, skip: {0}" -f $remote)
    continue
  }

  Write-Host ("Pushing {0}/{1}..." -f $remote, $Branch)
  $push = Invoke-Git -Args @("push", $remote, $Branch) -AllowFail
  if ($push.Code -ne 0) {
    $pushFailures.Add($remote) | Out-Null
  }
}

if ($pushFailures.Count -gt 0) {
  throw ("Push failed for remotes: {0}" -f ($pushFailures -join ", "))
}

Write-Host "Sync completed."
