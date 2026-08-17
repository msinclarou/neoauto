$ErrorActionPreference = 'SilentlyContinue'
$workspace = Split-Path -Parent $MyInvocation.MyCommand.Path
$trainerLog = Join-Path $workspace '.codex-dex-trainer.log'
$recruiterLog = Join-Path $workspace '.codex-runner-recruiter.log'
$trainerPidFile = Join-Path $workspace '.codex-dex-trainer.pid'
$recruiterPidFile = Join-Path $workspace '.codex-runner-recruiter.pid'

function Get-WorkerState([string]$pidFile) {
    if (-not (Test-Path -LiteralPath $pidFile)) { return 'STOPPED' }
    $workerPid = Get-Content -LiteralPath $pidFile -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($workerPid -and (Get-Process -Id ([int]$workerPid) -ErrorAction SilentlyContinue)) {
        return "RUNNING (PID $workerPid)"
    }
    return 'STOPPED'
}

function Get-CleanLines([string]$path, [int]$count) {
    if (-not (Test-Path -LiteralPath $path)) { return @('No log found.') }
    return @(Get-Content -LiteralPath $path -Tail ($count * 3) | ForEach-Object {
        $_ -replace [char]0, ''
    } | Where-Object { $_.Trim() } | Select-Object -Last $count)
}

while ($true) {
    $trainerLines = Get-CleanLines $trainerLog 10
    $recruiterLines = Get-CleanLines $recruiterLog 10
    $allTrainer = if (Test-Path $trainerLog) { (Get-Content $trainerLog -Raw) -replace [char]0, '' } else { '' }
    $allRecruiter = if (Test-Path $recruiterLog) { (Get-Content $recruiterLog -Raw) -replace [char]0, '' } else { '' }

    $dex = [regex]::Matches($allTrainer, '(?:now|DEX[^0-9]*)\s*(\d+)') | Select-Object -Last 1
    $recruited = [regex]::Matches($allRecruiter, '"recruitedToday":(\d+)') | Select-Object -Last 1
    $dexValue = if ($dex) { $dex.Groups[1].Value } else { 'unknown' }
    $recruitedValue = if ($recruited) { $recruited.Groups[1].Value } else { 'unknown' }

    Clear-Host
    Write-Host 'COMMON CRIMINALS - LIVE AUTOMATION DASHBOARD' -ForegroundColor Cyan
    Write-Host ('Updated: {0}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -ForegroundColor DarkGray
    Write-Host ''
    Write-Host ('DEX trainer : {0}' -f (Get-WorkerState $trainerPidFile)) -ForegroundColor Green
    Write-Host ('Recruiter   : {0}' -f (Get-WorkerState $recruiterPidFile)) -ForegroundColor Green
    Write-Host ('Current DEX : {0}' -f $dexValue) -ForegroundColor Yellow
    Write-Host ('Recruited today: {0}' -f $recruitedValue) -ForegroundColor Yellow
    Write-Host ''
    Write-Host 'DEX TRAINER - RECENT ACTIVITY' -ForegroundColor Cyan
    $trainerLines | ForEach-Object { Write-Host $_ }
    Write-Host ''
    Write-Host 'RECRUITER - RECENT ACTIVITY' -ForegroundColor Cyan
    $recruiterLines | ForEach-Object { Write-Host $_ }
    Write-Host ''
    Write-Host 'Refreshes every 3 seconds. Close this window to stop monitoring.' -ForegroundColor DarkGray
    Start-Sleep -Seconds 3
}
