[CmdletBinding()]
param(
  [string]$TaskName = "OpenClaw-UpstreamSync",
  [int]$IntervalMinutes = 60,
  [string]$RepoPath = "",
  [string]$Branch = "main",
  [string]$UpstreamRemote = "upstream",
  [string]$UpstreamBranch = "main",
  [string[]]$PushRemotes = @("gitee"),
  [switch]$RunNow
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($RepoPath)) {
  $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
  $RepoPath = (Resolve-Path (Join-Path $scriptDir "..")).Path
}

if ($IntervalMinutes -lt 5) {
  throw "IntervalMinutes must be >= 5."
}

$syncScript = Join-Path $PSScriptRoot "sync-upstream.ps1"
if (-not (Test-Path $syncScript)) {
  throw ("sync script not found: {0}" -f $syncScript)
}

$powershellExe = (Get-Command powershell.exe -ErrorAction SilentlyContinue).Source
if (-not $powershellExe) {
  throw "powershell.exe not found in PATH."
}

$arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$syncScript`" -RepoPath `"$RepoPath`" -Branch `"$Branch`" -UpstreamRemote `"$UpstreamRemote`" -UpstreamBranch `"$UpstreamBranch`""
foreach ($remote in $PushRemotes) {
  $arguments += " -PushRemotes `"$remote`""
}
$action = New-ScheduledTaskAction -Execute $powershellExe -Argument $arguments

$startAt = (Get-Date).AddMinutes(1)
$trigger = New-ScheduledTaskTrigger -Once -At $startAt `
  -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes) `
  -RepetitionDuration (New-TimeSpan -Days 3650)

$settings = New-ScheduledTaskSettingsSet `
  -AllowStartIfOnBatteries `
  -DontStopIfGoingOnBatteries `
  -MultipleInstances IgnoreNew

Register-ScheduledTask `
  -TaskName $TaskName `
  -Action $action `
  -Trigger $trigger `
  -Settings $settings `
  -Description "Sync from upstream and push to origin/gitee" `
  -Force | Out-Null

Write-Host ("Task installed: {0}, interval={1}m" -f $TaskName, $IntervalMinutes)
Write-Host ("Task command: {0} {1}" -f $powershellExe, $arguments)

if ($RunNow) {
  Start-ScheduledTask -TaskName $TaskName
  Write-Host "Task started."
}
