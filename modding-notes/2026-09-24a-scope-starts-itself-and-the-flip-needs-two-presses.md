# 2026-09-24 — the scope can start itself, the eye pose goes in with the rig, and the flip needs two presses

`/pd` on the home PC (`RTX`), no game launched. Everything below is **built and installed, not run**.

## 1. The eye pose now goes in at bring-up, not 45 s later

Tefa `[reported 2026-09-22]` asked for the good picture the moment the rifle is out. The reason it
was not: `VR-TRUE-SCOPE.bat` sent `bringup`, then waited 45 s, and only then sent the five words
that lay the mirror along the line of sight (`pitch 90 / yaw 90 / propf 0 / propu 0 / propr 0.20`).
Until then the viewpoint sat below the head and showed Ethan's clothes. On top of that, bringup's
own `propnear` set `propr` to 0, which under the 09-19 pose puts the scope's tube back in the picture.

Now bringup sends the five words itself, right after `fn drive_on` (~3 s after the rig exists), in
place of `propnear`. The .bat still sends them at the end, as a safety net that changes nothing if
the early write took. Checks: the harness parses
(`luac -p`), `bringup_sequence_test` 29/29 still passes, and `autostart_test` checks the words are
in the drive block. ⚠️ **The .bat's own note said "whether the pose can safely be written earlier is
untested"** — it still is. `[hypothesis]` that the re-binds at +5 s / +20 s do not care about the pose.

## 2. Auto-start on draw — `re8_scope_autostart.lua`, boots OFF

New file (the harness is past the 800-line soft limit, so it did not go in there). When the rifle
has been in hand for 1 s it sends the same three steps as the .bat, with the same 3 s gaps:
`fn rtex_1280`, numpad `.` through the plugin's own key queue, `bringup`. One attempt per draw; never
while a rig exists. The "rifle in hand" test is the plugin's own (world_tick.cpp): the equipped
weapon's GameObject name starts with `ri3042` `[inferred-static 2026-09-24]` — never run from Lua.
Switched with `SCOPE-AUTO-ON.bat` / `SCOPE-AUTO-OFF.bat` (`reframework\data\re_scope_autostart.txt`).
Every step logs `autostart:`, ending in `DONE` or `GAVE UP`, so one launch answers it.
`autostart_test` 15/15 `[verified-numerically 2026-09-24]` (stubbed game).

## 3. The picture flip needs two presses

On 09-22 a stray numpad 7 flipped and saved the picture. Now a 7 only arms; a second 7 within
1.5 s flips (`flip_confirm.h`). Both log a `!!!` line naming the route (keyboard or the Lua key
file). Changes to `geom_rot` / `geom_flip` / `geom_vflip` from the pane file now log `!!!` too.
`flip_confirm_test` 7/7; plugin built with no warnings; the new DLL's strings differ from the
installed 09-22 build by exactly the new log lines, so nothing from 09-22 was lost
`[compile-verified 2026-09-24]`. sha256 `69ab98a009410653…`; old DLL kept as
`re_scope_vr.dll.pre-flip-confirm-2026-09-24`.

## 4. Drift between the game and staging, closed

Six scripts looked different; four were only line endings. `pose.lua` and `spawn.lua` really
differed: the game still had the 2026-08-30 default pane pose (pitch 180), staging the 09-19 one
(pitch 90, propr 0.20). The launcher overrides it anyway, so the staging version was installed.
New `deploy_scripts.py` (`--check` lists drift, line endings ignored; a plain run backs up and
installs). After this session: 0 files differ `[measured 2026-09-24]`. Game copies replaced today
are in `reframework/_archive-2026-09-24-pre-deploy/`.

## 5. Release notes

`mod/README.md` has a "Known limitations" section: the edge streak (top and right only, when the head
is far off the scope line, not understood), and the small head movement still in the picture —
Tefa's decision to document rather than chase (2026-09-19, 2026-09-22).

## Side finding

Three Lua tests fail on untouched code too: `knob_chain_test` (counts 51 args for 54 keys), and
`producer_split_check` / `producer_globals_check` (the fn table has grown). The live
`re_scope_vr_pane.txt` is written in full through `aim_src`, so the writer is fine and the counting
test is stale `[measured 2026-09-24]`.
