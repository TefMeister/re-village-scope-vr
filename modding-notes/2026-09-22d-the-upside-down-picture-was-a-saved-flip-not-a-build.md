# 2026-09-22 (d) — the upside-down picture was a SAVED FLIP, not any build (home PC, Fable, Tefa in the headset)

**Solved live at 15:43, confirmed by Tefa: *"nice! right way up again!"*** `[verified-live 2026-09-22]`

## What happened

- At **11:22:47–48**, in the middle of the morning's good run, four key codes arrived through the
  plugin's key channel (`polled key … (VR route)`: 0x60, 0x61, **0x67**, 0x66 — numpad 0, 1, 7, 6).
  Numpad 7 toggles `glass_flip_v`; it went **1 → 0**, and numpad 1/6 nudged the crop centre
  (0.58 → 0.57, 0.51 → 0.52). A numpad press saves the settings file, so
  `reframework/re_scope_vr_settings.txt` (11:22) carried the flip into every launch after it.
- Every good launch (2026-09-21 18:50–19:51, 2026-09-22 10:59) loaded `glassFlipV=1`; every bad one
  (11:42 onward) loaded `glassFlipV=0` `[verified-live, n=14 launches in the logs]`.
- Tefa's own read was right: *"the picture flipped … when you told me to run crosshair from lua plane"* —
  the first launch after the 11:22 save was 11:42, and the LUA-PLANE lever's rolling picture (expected)
  masked the constant flip until the lever was switched off again.
- The four presses most likely came from the in-headset panel being touched (it feeds the same key
  handler as the numpad, since 2026-09-18d). `[hypothesis]`

## What it was NOT (all A/B'd today, each one launch)

| Suspect | Test | Result |
| --- | --- | --- |
| the game's camera wandering 30–50° from the headset (plan C) | `PLAN-C-OFF.bat` (mirror drawn from the headset pose, gap 0.00°) | still upside down; the morning run had the same gap and was right |
| today's plugin builds (plane lever, spike dump, drawpose default, flicker ring) | `MORNING-PLUGIN.bat` = build `87b0f32c` (worn right at 11:00) | still upside down |
| the framework grip builds (`bce0cf0a`, `2150cdbc`) | one-handed (no grip code runs); the three live grip switches; `MORNING-FRAMEWORK.bat` (rebuilt with the morning grip patch, `5b6c7b42`) | still upside down |
| VR runtime, projection, render sizes, framework config, Lua scripts, save, seating | compared in the logs / asked | all identical to the morning |

**Method lesson:** my first two file-change listings missed both real changes (`reframework/re_scope_vr_settings.txt`
sits one folder up from `data/`, and `find -maxdepth` cut off the autorun scripts). The listing that found it
was "every file the framework wrote since the good run, recursively" — do that first next time, before any
build A/B. Also: the `settings loaded` line is printed at every launch and would have shown `glassFlipV=0`
vs `1` in one grep; I compared launches against each other, never against the last GOOD one.

## Fixed how

Sent numpad 7, 3, 4 through the same key channel (`re_scope_vr_keys.txt`) while the game ran:
`glassFlipV=1 cropY=0.58 cropX=0.51`, saved 15:43. No restart.

## Also today (see note 2026-09-22c and the board)

- The flicker ring (trigger dumps the last 90 scope pictures) is built and installed — not yet worn.
- Graphics-driver fault at 14:36:58 (Windows event, NVIDIA) 16 s before a START-SCOPE; the game died on
  a dead device. One-off as far as the record goes; wallpaper loss on the desktop was the same fault.
- Tefa's standing rules: keep every build (archive seeded: `D:\claude video game stuff\builds\`, 15 builds
  with manifests); make it a plugin option; delete only when Tefa says the project is done (spec filed in
  the lanes plugin, `docs/specs/keep-every-build.md`).

## Open, from this

- **`[PD]` protect the flip:** a panel or numpad press that changes picture orientation should be logged
  loudly and need a deliberate action (or be removed from the panel). Four presses in 1.1 s went unnoticed.
- **`[PD]` deployed Lua scripts differ from staging** (`pane.lua`, `pose.lua`, `ray.lua`, `spawn.lua`,
  `re8_scope_harness.lua`, `re8_scope_m6_mirror_producer.lua`) — not today's change (mtimes older), but
  the game folder and the repo have drifted; find out which way and reconcile.
- The morning-state helpers (`MORNING-PLUGIN/FRAMEWORK`, `CURRENT-*`, `PLAN-C-OFF/ON`) stay in the game
  folder; `PLAN-C-*` are committed to `mod/helpers/`.
