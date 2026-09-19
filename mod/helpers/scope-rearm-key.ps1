# Presses numpad . (VK_DECIMAL, 0x6E) to re-arm the mirror-source latch.
#
# Finds the game by PROCESS, not by window title. The previous inline version looked for
# 'RESIDENT EVIL VILLAGE'; the real title is 'Resident Evil Village', so FindWindow returned
# zero and the focus step was skipped without saying so. The key still landed, but only
# because the plugin polls this key globally ("polled key 0x6E (VR route)") rather than by
# window message -- so a silent failure looked like a success. 2026-09-19.

Add-Type -Name W -Namespace K -MemberDefinition @'
[DllImport("user32.dll")] public static extern void keybd_event(byte b, byte s, uint f, int e);
[DllImport("user32.dll")] public static extern bool SetForegroundWindow(System.IntPtr h);
'@

$proc = Get-Process re8 -ErrorAction SilentlyContinue | Select-Object -First 1

if ($null -eq $proc) {
    Write-Host "  WARNING: the game does not appear to be running - sending the key anyway."
} elseif ($proc.MainWindowHandle -eq [System.IntPtr]::Zero) {
    Write-Host "  WARNING: no game window handle yet - sending the key anyway."
} else {
    [void][K.W]::SetForegroundWindow($proc.MainWindowHandle)
    Start-Sleep -Milliseconds 900
    Write-Host ("  focused: " + $proc.MainWindowTitle)
}

[K.W]::keybd_event(0x6E, 0, 0, 0)
Start-Sleep -Milliseconds 80
[K.W]::keybd_event(0x6E, 0, 2, 0)
Write-Host "  numpad . sent"
