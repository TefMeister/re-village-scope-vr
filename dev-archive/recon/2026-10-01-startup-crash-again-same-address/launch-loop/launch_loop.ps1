# launch_loop.ps1 -- launch RE Village N times, say for each whether it crashed at VR start or stayed up.
# Usage: powershell -File launch_loop.ps1 -Label "async-off" -Count 3
param([string]$Label = "run", [int]$Count = 3, [int]$WaitSeconds = 45)
$G = 'C:\Steam\steamapps\common\Resident Evil Village BIOHAZARD VILLAGE'
$log = Join-Path $G 're2_framework_log.txt'
$dmp = Join-Path $G 'reframework_crash.dmp'
$out = Join-Path $PSScriptRoot ("launch-results-" + $Label + ".txt")
for ($i = 1; $i -le $Count; $i++) {
    $dmpBefore = if (Test-Path $dmp) { (Get-Item $dmp).LastWriteTime } else { Get-Date '2000-01-01' }
    $t0 = Get-Date
    Start-Process -FilePath (Join-Path $G 're8.exe') -WorkingDirectory $G | Out-Null
    $seen = $false; $result = 'unknown'; $alive = $null
    for ($s = 0; $s -lt $WaitSeconds; $s++) {
        Start-Sleep -Seconds 1
        $p = Get-Process re8 -ErrorAction SilentlyContinue
        if ($p) { $seen = $true; $alive = $p }
        if ($seen -and -not $p) {
            $dmpAfter = if (Test-Path $dmp) { (Get-Item $dmp).LastWriteTime } else { Get-Date '2000-01-01' }
            $result = if ($dmpAfter -gt $dmpBefore) { 'CRASH' } else { 'exited-no-dump' }
            break
        }
    }
    if ($result -eq 'unknown' -and $alive) { $result = 'STARTED'; Stop-Process -Name re8 -Force -ErrorAction SilentlyContinue; Start-Sleep -Seconds 4 }
    $ready = (Select-String -Path $log -Pattern 'XR_SESSION_STATE_READY' -Quiet)
    $second = (Select-String -Path $log -Pattern 'Parameters: buffer_count' | Select-Object -Last 1).Line -replace '.*Parameters: ', ''
    $probe = (Select-String -Path $log -Pattern 'GetDeviceRemovedReason=0x[0-9A-F]+' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Value -replace 'GetDeviceRemovedReason=', '' }) -join ','
    $line = '{0} launch {1}: {2} | VR ready={3} | last resize: {4} | probe: {5} | {6:HH:mm:ss}' -f $Label, $i, $result, $ready, $second, $probe, $t0
    Write-Output $line
    Add-Content -Path $out -Value $line
    Copy-Item $log (Join-Path $PSScriptRoot ('log-' + $Label + '-' + $i + '-' + $result + '.txt')) -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
}
