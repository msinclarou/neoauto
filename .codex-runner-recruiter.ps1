$ErrorActionPreference = 'Stop'
$headers = @{ Authorization = "Bearer $env:CC_GAME_KEY" }
$endpoint = 'https://commoncriminals.ai/api/v1/game/runners'
$stateEndpoint = 'https://commoncriminals.ai/api/v1/game/state'
$logPath = Join-Path $PSScriptRoot '.codex-runner-recruiter.log'

function Write-RecruitLog([string]$Message) {
    "$(Get-Date -Format o) $Message" | Add-Content -LiteralPath $logPath
}

function Get-RunnerStatus {
    Invoke-RestMethod -Method Get -Uri $endpoint -Headers $headers -TimeoutSec 30
}

function Recruit-Runner {
    Invoke-RestMethod -Method Post -Uri $endpoint -Headers $headers -ContentType 'application/json' `
        -Body '{"action":"recruit"}' -TimeoutSec 30
}

Write-RecruitLog 'Automatic runner recruiter started.'

while ($true) {
    try {
        $status = Get-RunnerStatus

        $playerState = Invoke-RestMethod -Method Get -Uri $stateEndpoint -Headers $headers -TimeoutSec 30
        if ($playerState.state.current -ne 'FREE') {
            Write-RecruitLog "Recruiting paused while state=$($playerState.state.current); retrying in 60 seconds."
            Start-Sleep -Seconds 60
            continue
        }

        if ([int]$status.recruitedToday -ge [int]$status.dailyRecruitCap) {
            $nowUtc = [DateTime]::UtcNow
            $nextUtcDay = $nowUtc.Date.AddDays(1)
            $sleepSeconds = [Math]::Max(60, [int][Math]::Ceiling(($nextUtcDay - $nowUtc).TotalSeconds) + 5)
            Write-RecruitLog "Daily cap reached ($($status.recruitedToday)/$($status.dailyRecruitCap)); sleeping until the next UTC day."
            Start-Sleep -Seconds $sleepSeconds
            continue
        }

        $cooldown = [int]$status.cooldownRemaining
        if ($cooldown -gt 0) {
            Start-Sleep -Seconds ([Math]::Max(1, $cooldown + 1))
            continue
        }

        try {
            $result = Recruit-Runner
            $newTotal = if ($null -ne $result.runners) { $result.runners } else { 'unknown' }
            Write-RecruitLog "Recruit attempt completed; runners=$newTotal; response=$($result | ConvertTo-Json -Compress)"
        }
        catch {
            Write-RecruitLog "Recruit attempt refused: $($_.Exception.Message)"
            Start-Sleep -Seconds 60
            continue
        }

        # The documented cooldown is five minutes. The next status check confirms it.
        Start-Sleep -Seconds 301
    }
    catch {
        Write-RecruitLog "Status error: $($_.Exception.Message); retrying in 60 seconds."
        Start-Sleep -Seconds 60
    }
}
