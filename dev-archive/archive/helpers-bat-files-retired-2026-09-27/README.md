# The double-click helpers

Copy any of these into the game folder, beside `re8.exe`. Each one writes a single
command into `reframework\data\re_scope_cmd.txt`, which the harness reads about twice a
second and then deletes. They exist because a keyboard does not reach the game window
from inside the headset (the same reason the VR tuning panel exists), so a mouse click
on the desktop through Virtual Desktop is the practical way to change a knob mid-play.

| File | What it sends | What it is for |
| --- | --- | --- |
| `START-SCOPE.bat` | `bringup` | the whole set-up in one go, about 35 seconds. Have the sniper rifle in hand first |
| `FIX-SCOPE-GLASS.bat` | `bind` | puts the live picture back on the glass when the stock crosshair shows, e.g. after a weapon switch |
| `FLICKER-1-COUNT.bat` | `hold 1` | counts the one-frame flickers into the log. The picture does not change |
| `FLICKER-2-HIDE.bat` | `hold 2` | hides the flicker by re-showing the last good frame, whatever its cause |
| `FLICKER-3-EIGHTBIT.bat` | `hold 1` + `src8 1` | takes the picture from the path-bound 8-bit copy. If the flicker stops here, a pooled buffer is the cause. Sunlight clips to white on this path — it is the test, not the fix |
| `FLICKER-OFF.bat` | `hold 0` + `src8 0` | back to the shipped behaviour |
| `FLICKER-1B-SENSITIVE.bat` | `hold 1` + `holdt 0.005` | the counter at its most sensitive. ✔ run |
| `TEST-1-RERIG.bat` | `rerig` | after loading a save: rebuild the scope picture. ✘ never run |
| `TEST-2-SWITCH-DELAY-ON.bat` | `swdelay 1500` | the weapon-switch glass flash fix. ✔ run; it works, and is now the boot value |
| `TEST-2-SWITCH-DELAY-OFF.bat` | `swdelay 0` | back to the instant glass restore. ✘ never run |
| `TEST-3-PROP-NEAR.bat` / `TEST-3-PROP-OFF.bat` | `propnear` / `propoff` | the hidden mirror host pulled in to the rifle, or parked where it used to be. ✘ never run |
| `TEST-3B-DROP-NORMAL.bat` / `-LEVEL` / `-UP` / `-DOWN` | `propu -0.2` / `0` / `0.1` / `-0.4` | the host's height against the rifle. ✔ all four run; none is clean |
| `TEST-4-SPREAD-PROBE.bat` | `spreadprobe` | lists the weapon's spread-like values in the log. Read-only. ✔ run |
| `TEST-5-EYE-AIM-ON.bat` / `-OFF.bat` | `eyepar 1` / `eyepar 0` | the per-eye aim. ✔ ON run, no visible effect; ✘ OFF never run |
| `TEST-6-FRAME-NEW.bat` / `-OLD.bat` | `framev 2` / `framev 1` | the scope frame built directly, or the worn one. ✔ both run; NEW is upside down |
| `TEST-7-HAND-DOWN.bat` / `-NORMAL.bat` | `handhigher L 0.05` / `handhigher L 0` | the left hand's drawn height. ✔ both run; the hand does not move |
| `TEST-8-HDR-BACK.bat` | `rbfb 0` | switches the save-reload fallback off. ✔ run. It does not bring the good source back mid-session; `rb_fb=0` in the settings file and a relaunch does |

The first two were written on 2026-09-14 for the tester package and lived only in the game
folder and that zip until 2026-09-17; the four `FLICKER-` ones were written on 2026-09-17
for the flicker session. Both `START-SCOPE.bat` and `FIX-SCOPE-GLASS.bat` are proven in
the game `[verified-live 2026-09-14, n=1 session]`; the four `FLICKER-` ones have never
been run `[compile-verified 2026-09-17]` — the batch syntax is checked, what they switch on
is not. **Corrected the same evening:** `FLICKER-1-COUNT.bat` was run and delivered `hold 1`
`[verified-live 2026-09-17, n=1]`; the other three `FLICKER-` files are still unrun.

The `TEST-` files and `FLICKER-1B-SENSITIVE.bat` were written during the 2026-09-17 evening
session that checked the nine 2026-09-16 builds. "✔ run" in the table means the click produced
its `harness:` echo line in the log `[verified-live 2026-09-17, n=1 each]`. It says the command
arrived. It says nothing about whether the feature behind it works; for that, see
`modding-notes/2026-09-17c-the-nine-builds-checked-in-the-headset-two-work-and-one-broke-the-sky.md`.

⚠️ **A click that leaves no `harness:` line did not happen.** One did not register through
Virtual Desktop that evening, and the wearer reported a change that the mod had never made.

⚠️ Writing the command file is a way of **driving** the mod, so a `/ms` session never runs
these itself — it creates them and asks the wearer to click.

## The batch trap worth knowing

When generating these from a shell script, keep the path out of any `printf` format string:
`e_scope_cmd.txt` starts with ``, which `printf` turns into a carriage return and the file
quietly becomes `datae_scope_cmd.txt`. Pass the path as a `%s` argument. This has now bitten
twice (2026-09-17 morning and evening); both times reading the written file back caught it.

`echo hold 1> file` does not do what it looks like: `cmd` reads `1>` as "redirect stream 1",
so the file gets `hold` and the `1` is lost. Every file here puts the redirect first
instead — `>"file" ( echo hold 1 )` — which has no such ambiguity.

## Keeping the log (2026-09-18)

REFramework **empties** `re2_framework_log.txt` every time the game starts. On 2026-09-17 a session
made three launches and the two that mattered were gone by the end — their lines survive only as
something typed out by hand.

| file | what it does |
| --- | --- |
| `KEEP-LOG.bat` | copies the log to `reframework\logs\re2_framework_log-<date>_<time>.txt`. Nothing is ever deleted; the copies are small. |
| `LAUNCH-VILLAGE.bat` | runs `KEEP-LOG.bat`, then starts the game through Steam. Use this shortcut instead of the Steam one and nobody has to remember. |

Click `KEEP-LOG.bat` **after closing the game and before starting it again**. Clicking it while the
game runs saves the log so far, which is also fine.

Both live in the game folder, beside `re2_framework_log.txt`. Tested on a fake log in a scratch
folder `[verified-numerically 2026-09-18, n=1]`; `LAUNCH-VILLAGE.bat` itself has never been run,
because the session that wrote it does not launch games.

## Most of these have buttons now (2026-09-18)

The VR tuning panel can send harness words directly — `bringup`, `rerig`, `bind`, `hold 0|1|2`,
`holddiag 120`, `holdt`, `src8`, `rbfb`, `framev`, `bodyprobe`, `bodyhide`, `spreadprobe`, `status`.
So a test no longer needs a trip out to the desktop per knob. These files stay useful for anything
the panel does not carry, and for a hand that is already on the mouse.

⚠️ **A harness word is a SESSION experiment.** Since 2026-09-18 a numpad press or a panel click no
longer writes one into `re_scope_vr_settings.txt` as the next launch's default — it used to, and on
2026-09-17 that turned `framev 2` into a boot value nobody had chosen. To make a word permanent, put
the line in the settings file yourself.
