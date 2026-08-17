$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($env:CC_GAME_KEY)) {
    throw 'CC_GAME_KEY is not set.'
}

$headers = @{ Authorization = "Bearer $env:CC_GAME_KEY" }
$baseUrl = 'https://commoncriminals.ai/api/v1/game'
$logPath = Join-Path $PSScriptRoot '.codex-car-thief.log'

function Write-CarLog([string]$Message) {
    "$(Get-Date -Format o) $Message" | Add-Content -LiteralPath $logPath
}

function Get-GameState {
    Invoke-RestMethod -Method Get -Uri "$baseUrl/state" -Headers $headers -TimeoutSec 30
}

function Get-CarStatus {
    Invoke-RestMethod -Method Get -Uri "$baseUrl/cars" -Headers $headers -TimeoutSec 30
}

function Invoke-CarTheft {
    $body = @{ action = 'steal'; location = 'collectors' } | ConvertTo-Json -Compress
    Invoke-RestMethod -Method Post -Uri "$baseUrl/cars" -Headers $headers `
        -ContentType 'application/json' -Body $body -TimeoutSec 30
}

Write-CarLog "Automatic car thief started (location=Collector's District)."

while ($true) {
    try {
        $state = Get-GameState
        if ($state.state.current -ne 'FREE') {
            Write-CarLog "Paused while state=$($state.state.current); checking again in 30 seconds."
            Start-Sleep -Seconds 30
            continue
        }

        $status = Get-CarStatus
        $cooldown = [int]$status.stealInfo.cooldownRemaining

        if ($cooldown -gt 0) {
            # Wake one second after the server-reported cooldown expires.
            Start-Sleep -Seconds ([Math]::Max(1, $cooldown + 1))
            continue
        }

        try {
            $result = Invoke-CarTheft
            Write-CarLog "Theft attempted: $($result | ConvertTo-Json -Compress -Depth 6)"
        }
        catch {
            Write-CarLog "Theft refused: $($_.Exception.Message); retrying status in 15 seconds."
            Start-Sleep -Seconds 15
            continue
        }

        # The cooldown is five minutes. GET /cars will confirm the exact remainder.
        Start-Sleep -Seconds 301
    }
    catch {
        Write-CarLog "Status error: $($_.Exception.Message); retrying in 30 seconds."
        Start-Sleep -Seconds 30
    }
}
