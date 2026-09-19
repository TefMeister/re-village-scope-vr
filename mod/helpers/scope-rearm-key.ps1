# Re-arms the mirror-source latch (the numpad . action).
#
# 2026-09-20, THIRD VERSION. It no longer sends a real keystroke at all.
#
# What went wrong, in order:
#   v1  sent the key AND called SetForegroundWindow first. The wearer reported the WEAPON
#       FIRED ITSELF during this step. Stealing focus while a VR runtime holds the window is
#       the only thing here that can produce a stray input.
#   v2  removed the focus call, on the evidence that the key still landed without it
#       ("polled key 0x6E (VR route)" on 2026-09-19 while the window lookup had failed).
#       ⚠ THAT EVIDENCE WAS FROM A VR SESSION. The clue was in the words "VR route": the
#       plugin polls that key through the VR input path, which is not running flat. So on a
#       FLAT run the key needed window focus after all, and v2 silently stopped working:
#       2026-09-20 02:01, re-arm pending=0, latch stuck on the game's own 1920x1080 buffer,
#       STRANDED LATCH, black scope. Works in VR, dead flat - exactly what was reported.
#   v3  (this) uses the plugin's OWN virtual-key channel instead of the keyboard.
#
# HOW v3 WORKS. pane_file.cpp:63 service_virtual_keys() reads
# reframework\data\re_scope_vr_keys.txt about four times a second, injects each decimal VK
# code it finds as a WM_KEYDOWN the plugin sends to itself, and deletes the file. So writing
# "110" (0x6E, VK_DECIMAL) does exactly what pressing numpad . does - with no keyboard, no
# focus, no VR runtime needed, and nothing the game can mistake for a trigger pull.
#
# ⚠ UNTESTED AS OF WRITING. The reasoning is from the plugin source, not from a run.
# If the scope is still black, press numpad . by hand when the script pauses, and say so.

$dir  = Join-Path $PSScriptRoot "reframework\data"
$keys = Join-Path $dir "re_scope_vr_keys.txt"

if (-not (Test-Path $dir)) {
    Write-Host "  reframework\data is missing - cannot re-arm."
    exit 1
}

# The plugin deletes the file once it has consumed it, so an existing one means a previous
# request is still pending. Give it a moment rather than overwriting someone else's keys.
for ($i = 0; $i -lt 10 -and (Test-Path $keys); $i++) { Start-Sleep -Milliseconds 300 }

Set-Content -Path $keys -Value "110" -Encoding ASCII    # 110 = 0x6E = VK_DECIMAL = numpad .
Write-Host "  re-arm requested through the plugin's own key channel (no keystroke sent)"

# Confirm it was taken, so a silent failure cannot look like success again.
$taken = $false
for ($i = 0; $i -lt 12; $i++) {
    Start-Sleep -Milliseconds 300
    if (-not (Test-Path $keys)) { $taken = $true; break }
}
if ($taken) {
    Write-Host "  the plugin took it."
} else {
    Write-Host "  !! the plugin did NOT take it within 3.6 s - it may not be running yet."
    Write-Host "     If the scope comes up black, press numpad . by hand and run START-SCOPE again."
}
