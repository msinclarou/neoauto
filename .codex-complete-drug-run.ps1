$ErrorActionPreference = 'Stop'
$headers = @{ Authorization = "Bearer $env:CC_GAME_KEY" }
$base = 'https://commoncriminals.ai/api/v1/game'
$resultPath = Join-Path $PSScriptRoot '.codex-drug-run-result.json'

try {
    do {
        $travel = Invoke-RestMethod -Method Get -Uri "$base/travel" -Headers $headers
        if ([int]$travel.cooldownRemaining -gt 0) {
            Start-Sleep -Seconds ([Math]::Min(30, [int]$travel.cooldownRemaining))
        }
    } while ([int]$travel.cooldownRemaining -gt 0)

    $returnTrip = Invoke-RestMethod -Method Post -Uri "$base/travel" -Headers $headers -ContentType 'application/json' -Body '{"citySlug":"sterling_city"}'
    $weedSale = Invoke-RestMethod -Method Post -Uri "$base/drugs" -Headers $headers -ContentType 'application/json' -Body '{"action":"sell","drugId":1,"quantity":49}'
    $lsdSale = Invoke-RestMethod -Method Post -Uri "$base/drugs" -Headers $headers -ContentType 'application/json' -Body '{"action":"sell","drugId":3,"quantity":29}'
    $state = Invoke-RestMethod -Method Get -Uri "$base/state" -Headers $headers
    [ordered]@{ success = $true; returnTrip = $returnTrip; weedSale = $weedSale; lsdSale = $lsdSale; finalState = $state } |
        ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $resultPath
}
catch {
    [ordered]@{ success = $false; error = $_.Exception.Message; at = (Get-Date).ToString('o') } |
        ConvertTo-Json | Set-Content -LiteralPath $resultPath
}
finally {
    Remove-Item -LiteralPath $PSCommandPath -Force
}
