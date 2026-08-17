$ErrorActionPreference = 'Stop'
$headers = @{ Authorization = "Bearer $env:CC_GAME_KEY" }
$base = 'https://commoncriminals.ai/api/v1/game'
$logPath = Join-Path $PSScriptRoot '.codex-dex-trainer.log'

function Write-RunnerLog([string]$Message) {
    "$(Get-Date -Format o) $Message" | Add-Content -LiteralPath $logPath
}

function Get-Api([string]$Path) {
    Invoke-RestMethod -Method Get -Uri "$base/$Path" -Headers $headers -TimeoutSec 30
}

function Post-Api([string]$Path, [hashtable]$Body) {
    $json = $Body | ConvertTo-Json -Compress
    Invoke-RestMethod -Method Post -Uri "$base/$Path" -Headers $headers -ContentType 'application/json' -Body $json -TimeoutSec 30
}

Write-RunnerLog 'Daily-task and Dexterity runner started.'

# Finish today's repeatable action requirements.
while ($true) {
    try {
        $daily = (Get-Api 'daily-tasks').data
        $crimeTask = $daily.tasks | Where-Object { $_.requirement.type -eq 'crimes_completed' }
        $gymTask = $daily.tasks | Where-Object { $_.requirement.type -eq 'gym_sessions' }

        if ($gymTask -and -not $gymTask.completed) {
            $gym = Get-Api 'gym'
            if ([int]$gym.energy -ge [int]$gym.costPerSession) {
                try {
                    $trained = Post-Api 'gym' @{}
                    Write-RunnerLog "Gym: +$($trained.gained) DEX; now $($trained.newValue)."
                } catch { Write-RunnerLog "Gym retry: $($_.Exception.Message)" }
            }
        }

        if ($crimeTask -and -not $crimeTask.completed) {
            $crimes = Get-Api 'crimes'
            $pickpocket = $crimes.crimes | Where-Object { $_.id -eq 1 }
            if ($pickpocket.available -and [int]$crimes.globalCooldown -le 0) {
                try {
                    $crime = Post-Api 'crimes' @{ crimeId = 1 }
                    Write-RunnerLog "Crime attempted: $($crime.message)"
                } catch { Write-RunnerLog "Crime retry: $($_.Exception.Message)" }
            }
        }

        if ((-not $crimeTask -or $crimeTask.completed) -and (-not $gymTask -or $gymTask.completed)) { break }
    } catch { Write-RunnerLog "Daily loop error: $($_.Exception.Message)" }
    Start-Sleep -Seconds 11
}

# Claim every completed daily reward. Refused/already-claimed requests are harmless.
try {
    $daily = (Get-Api 'daily-tasks').data
    foreach ($task in ($daily.tasks | Where-Object { $_.completed })) {
        try {
            $claim = Post-Api 'daily-tasks' @{ taskId = $task.id }
            Write-RunnerLog "Claimed daily task $($task.name): $($claim | ConvertTo-Json -Compress)"
        } catch { Write-RunnerLog "Claim for $($task.name): $($_.Exception.Message)" }
    }
} catch { Write-RunnerLog "Daily claim pass error: $($_.Exception.Message)" }

Write-RunnerLog 'Daily action requirements complete; continuous Dexterity mode active.'

# Continuously spend naturally regenerated energy on Dexterity training.
while ($true) {
    try {
        $state = Get-Api 'state'
        $gym = Get-Api 'gym'
        if ($state.state.current -eq 'FREE' -and [int]$gym.energy -ge [int]$gym.costPerSession) {
            try {
                $trained = Post-Api 'gym' @{}
                Write-RunnerLog "Auto-gym: +$($trained.gained) DEX; now $($trained.newValue)."
                Start-Sleep -Seconds 11
                continue
            } catch { Write-RunnerLog "Auto-gym retry: $($_.Exception.Message)" }
        }
    } catch { Write-RunnerLog "Auto-gym status error: $($_.Exception.Message)" }
    Start-Sleep -Seconds 60
}
