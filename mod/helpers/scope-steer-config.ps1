# Writes (or removes) the scope-steering keys in REFramework's config.
# Kept in its own file on purpose: the first version of this lived inside the .bat as a
# one-liner, and cmd's "^" continuation ate the "^|" escapes, so the whole command was a
# parse error while the .bat cheerfully printed "STEERING IS ON". It had swapped the DLL
# and written nothing. 2026-09-19.
param(
    [Parameter(Mandatory = $true)][string]$ConfigPath,
    [Parameter(Mandatory = $true)][ValidateSet('on', 'off')][string]$Mode
)

if (-not (Test-Path $ConfigPath)) {
    Write-Error "Config not found: $ConfigPath"
    exit 1
}

$want = [ordered]@{
    'VR_SteerMirrorProjection' = $(if ($Mode -eq 'on') { 'true' } else { 'false' })
    'VR_MirrorSteerFromPlugin' = 'false'
    'VR_MirrorSteerYaw'        = '0.000000'
    'VR_MirrorSteerPitch'      = '0.000000'
    'VR_MirrorSteerInvert'     = 'false'
    'VR_SteerMirrorFromNative' = 'false'
}

$lines = Get-Content $ConfigPath
$before = $lines.Count

foreach ($k in $want.Keys) {
    $hit = $false
    $lines = $lines | ForEach-Object {
        if ($_ -like ($k + '=*')) { $hit = $true; $k + '=' + $want[$k] } else { $_ }
    }
    if (-not $hit) { $lines += ($k + '=' + $want[$k]) }
}

Set-Content -Path $ConfigPath -Value $lines -Encoding ASCII

# Read it back and prove the one key that matters really says what we asked for, so a
# silent failure can never again be reported as success.
$check = Get-Content $ConfigPath | Where-Object { $_ -like 'VR_SteerMirrorProjection=*' }
if ($check -ne ('VR_SteerMirrorProjection=' + $want['VR_SteerMirrorProjection'])) {
    Write-Error "Config write did not take: expected VR_SteerMirrorProjection=$($want['VR_SteerMirrorProjection']), found '$check'"
    exit 1
}

Write-Host "  Config OK: $check  ($before lines -> $($lines.Count))"
exit 0
