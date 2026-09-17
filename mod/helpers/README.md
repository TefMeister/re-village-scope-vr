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

The first two were written on 2026-09-14 for the tester package and lived only in the game
folder and that zip until 2026-09-17; the four `FLICKER-` ones were written on 2026-09-17
for the flicker session. Both `START-SCOPE.bat` and `FIX-SCOPE-GLASS.bat` are proven in
the game `[verified-live 2026-09-14, n=1 session]`; the four `FLICKER-` ones have never
been run `[compile-verified 2026-09-17]` — the batch syntax is checked, what they switch on
is not.

⚠️ Writing the command file is a way of **driving** the mod, so a `/ms` session never runs
these itself — it creates them and asks the wearer to click.

## The batch trap worth knowing

`echo hold 1> file` does not do what it looks like: `cmd` reads `1>` as "redirect stream 1",
so the file gets `hold` and the `1` is lost. Every file here puts the redirect first
instead — `>"file" ( echo hold 1 )` — which has no such ambiguity.
