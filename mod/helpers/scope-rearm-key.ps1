# Presses numpad . (VK_DECIMAL, 0x6E) to re-arm the mirror-source latch.
#
# 2026-09-20: NO LONGER BRINGS THE GAME TO THE FOREGROUND.
#
# It used to call SetForegroundWindow first. On 2026-09-20 the wearer reported the
# WEAPON FIRED ITSELF during step 2 of START-SCOPE, which is this step and nothing
# else. Stealing focus while a VR runtime is holding the window is the only thing
# here capable of producing a stray input, so it is gone.
#
# Focus was never needed. On 2026-09-19 at 22:59 this script's predecessor failed to
# find the window at all (it searched for the title 'RESIDENT EVIL VILLAGE', which
# does not exist - the real one is 'Resident Evil Village'), logged a warning, sent
# the key anyway, and the plugin logged `polled key 0x6E (VR route)` followed by
# `mirror-source re-arm PENDING`. The plugin polls this key GLOBALLY rather than by
# window message, so it lands whatever has focus [verified-live 2026-09-19, n=1].
#
# So the focus call bought nothing and cost a fired round. If a future change makes
# the key window-routed, this is the file to revisit.

Add-Type -Name W -Namespace K -MemberDefinition @'
[DllImport("user32.dll")] public static extern void keybd_event(byte b, byte s, uint f, int e);
'@

$proc = Get-Process re8 -ErrorAction SilentlyContinue | Select-Object -First 1
if ($null -eq $proc) {
    Write-Host "  WARNING: the game does not appear to be running - sending the key anyway."
} else {
    Write-Host ("  game found (pid " + $proc.Id + ") - not stealing focus, the key is polled globally")
}

[K.W]::keybd_event(0x6E, 0, 0, 0)
Start-Sleep -Milliseconds 80
[K.W]::keybd_event(0x6E, 0, 2, 0)
Write-Host "  numpad . sent"
