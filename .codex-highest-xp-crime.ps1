$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($env:CC_GAME_KEY)) {
    throw 'CC_GAME_KEY is not set.'
}

$headers = @{ Authorization = "Bearer $env:CC_GAME_KEY" }
$baseUrl = 'https://commoncriminals.ai/api/v1/game'
$logPath = Join-Path $PSScriptRoot '.codex-highest-xp-crime.log'

function Write-CrimeLog([string]$Message) {
    "$(Get-Date -Format o) $Message" | Add-Content -LiteralPath $logPath
}

function Get-Api([string]$Path) {
    Invoke-RestMethod -Method Get -Uri "$baseUrl/$Path" -Headers $headers -TimeoutSec 30
}

function Invoke-Crime([int]$CrimeId) {
    $body = @{ crimeId = $CrimeId } | ConvertTo-Json -Compress
    Invoke-RestMethod -Method Post -Uri "$baseUrl/crimes" -Headers $headers `
        -ContentType 'application/json' -Body $body -TimeoutSec 30
}

Write-CrimeLog 'Highest-XP crime worker started.'

while ($true) {
    try {
        $state = Get-Api 'state'
        if ($state.state.current -ne 'FREE') {
            Write-CrimeLog "Paused while state=$($state.state.current); checking again in 30 seconds."
            Start-Sleep -Seconds 30
            continue
        }

        $status = Get-Api 'crimes'
        $globalCooldown = [int]$status.globalCooldown
        if ($globalCooldown -gt 0) {
            Start-Sleep -Seconds ([Math]::Max(1, $globalCooldown + 1))
            continue
        }

        # Select the highest-XP crime the server currently marks available.
        # Re-evaluating every cycle automatically moves to better crimes after level-ups.
        $target = $status.crimes |
            Where-Object { $_.available -and [int]$_.cooldownRemaining -le 0 } |
            Sort-Object @{ Expression = { [int]$_.xpReward }; Descending = $true }, `
                        @{ Expression = { [int64]$_.cashRange[1] }; Descending = $true } |
            Select-Object -First 1

        if (-not $target) {
            $nextCooldown = $status.crimes |
                Where-Object { $_.available -and [int]$_.cooldownRemaining -gt 0 } |
                ForEach-Object { [int]$_.cooldownRemaining } |
                Measure-Object -Minimum
            $wait = if ($null -ne $nextCooldown.Minimum) {
                [Math]::Max(1, [int]$nextCooldown.Minimum + 1)
            } else {
                30
            }
            Start-Sleep -Seconds $wait
            continue
        }

        try {
            $result = Invoke-Crime -CrimeId ([int]$target.id)
            Write-CrimeLog "Attempted '$($target.name)' (+$($target.xpReward) XP target): $($result | ConvertTo-Json -Compress -Depth 6)"
        }
        catch {
            Write-CrimeLog "Attempt for '$($target.name)' refused: $($_.Exception.Message); checking again in 10 seconds."
            Start-Sleep -Seconds 10
            continue
        }

        # A fresh GET supplies the authoritative remaining cooldown on the next pass.
        Start-Sleep -Seconds 1
    }
    catch {
        Write-CrimeLog "Status error: $($_.Exception.Message); retrying in 30 seconds."
        Start-Sleep -Seconds 30
    }
}
