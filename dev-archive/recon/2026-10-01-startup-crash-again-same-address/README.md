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
