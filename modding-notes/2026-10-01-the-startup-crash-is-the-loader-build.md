# 2026-10-01 (late): the VR start-up crash is the REFramework build, not us

*Home PC, Tefa in the chair until they handed the launching over ("take over and launch and test as you please").*

## What happened

Tefa launched the game to wear the two grip fixes and it crashed about two seconds in, before the menu, headset
on. It kept crashing: by hand 6 of 7 launches, then 9 of 9 under a launch loop. The 30th's fresh-install crash
was the same one (same address in the game, same timing, same conditions).

## What was ruled out, one launch each

The new grip scripts (crashed with this morning's files back), our plugin (crashed with the DLL out), the two
graphics settings the fresh install had raised (crashed with them lowered), the window size (crashed at
1920x1080 as in September), DLSS (crashed with it off), async rendering (crashed with it off, bar one start).
Nothing on the PC had changed since this morning except a reboot at 14:35.

## What the probe said

A one-line probe in our plugin asked the graphics card, at the moment of the failing resize, why it had dropped
the device: `INVALID_CALL`, a bad app-side call, not a driver fault. Then the DLSS-off launches showed there is
no graphics reset at all on that path and the game still dies in the same millisecond the headset session
reports READY. So the device loss was a side effect. The fault is praydog's `a24c3459` build calling into the
game the instant the headset is ready, before the game has its camera (`VR: Failed to get primary camera!` is
logged right there).

## The workaround, proven

The March build `76298bd` (the package the VR Hub installs, unmodified) started 3 of 3 under the same loop, with
DLSS on and async on. It handles READY by resizing the window to the eye size and carrying on.

| loader | starts / launches tonight |
| --- | --- |
| a24c3459 (what v1.0.0 and v1.0.1 tell players to install) | 1 / 16 |
| 76298bd (March, VR Hub package) | 3 / 3 |

`[verified-live 2026-10-01, n=19 launches, one PC]`. Why it comes and goes: a race between how fast the headset
answers READY and how far the game has booted. That is why it worked on the 27th and this morning and not tonight.

## What this means for the release

v1.0.0 and v1.0.1 tell players to install `a24c3459`. Any player whose headset answers quickly will hit this
crash and blame the scope mod. The install text should point at the `76298bd` package instead (or at least
name the crash and the swap). Tefa's call on the wording; the evidence is one PC.

## Left in the game folder

`76298bd` loader installed (`a24c3459` saved in `D:\RE Village REFramework builds\deploy-backups\_loader-a24c3459-set-aside-2026-10-01\`),
the plugin build with the device-reset probe (one log line per reset, harmless; source in staging), the two-fix
grip script and the split files, window 1920x1080, async on, DLSS on. The two grip fixes are still NOT WORN.

Evidence: `dev-archive/recon/2026-10-01-startup-crash-again-same-address/` (every log, the dumps, the launch
loop script and its results).
