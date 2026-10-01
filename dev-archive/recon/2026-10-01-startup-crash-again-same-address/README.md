# 2026-10-01 22:39: the start-up crash again, same address as 2026-09-30

Tefa launched the game with the headset on to wear the two grip fixes. It crashed about 1.6 s after the scripts
loaded, before the menu. Access violation, RIP re8.exe+0x4BCD803 (module base 7ff7a3a80000), the same address as
the 2026-09-30 fresh-install start-up crashes.

What the log adds tonight: right before the crash, D3D12 resize buffers was called with width 0 height 0, failed with
0x887A0005 (DXGI device removed), and REFramework ran its device-reset path (Reset, VR on_device_reset, re-hook D3D12);
the null read follows at once. Windows logged no display-driver reset in that minute, so the device was lost by the
app, not by a driver timeout.

Not caused by the grip scripts: they only act once the rifle camera exists, and the 09-30 crashes happened without
the scope mod installed.

Files: the REFramework log and crash dump of that launch.

## 23:15 update: cause found, workaround proven (the launch loop, launch-loop/)

Every launch tonight was driven by `launch-loop/launch_loop.ps1` (start the exe, wait, read the log) once Tefa handed over.

| setup | starts | crashes |
| --- | --- | --- |
| a24c3459 loader, async off | 0 | 3 |
| a24c3459 loader, async on | 0 | 3 |
| a24c3459 loader, async on, DLSS off | 0 | 3 |
| **76298bd loader (March, the VR Hub package), async on, DLSS on** | **3** | **0** |

Plus the hand launches earlier: a24c3459 crashed 6 of 7 by hand (one start at 23:02 with async off). Nothing else
mattered: the grip scripts, our plugin, the two graphics settings, the window size and DLSS were each ruled out
by a launch with them changed.

What the logs say: with DLSS off there is no graphics reset at all and the game still dies in the same
millisecond the OpenXR session reports READY, at the same address (`re8.exe+0x4BCD803`, a null read reached from
`DINPUT8.dll+0x5F0598`). `VR: Failed to get primary camera!` is logged at that moment in the DLSS-on runs: the
headset is ready before the game has a camera, and the a24c3459 build calls into the game anyway. With DLSS on,
the reset path runs first and the device is removed with INVALID_CALL (our plugin's probe) 50 ms later; that is
a side effect, not the cause. The 76298bd build at the same moment resizes the window to the eye size
(2688x2880) and carries on.

Why it comes and goes: it is a race between how fast the headset answers READY and how far the game has booted.
Fresh boot, warm caches, Virtual Desktop state all move it. Tonight READY came ~1 s after the scripts loaded,
every time.

Left in the game folder: the 76298bd `dinput8.dll` (the a24c3459 one is in
`D:\RE Village REFramework builds\deploy-backups\_loader-a24c3459-set-aside-2026-10-01\`), the plugin build with
the device-reset probe (harmless, one log line per reset), window 1920x1080, async on, DLSS on.
