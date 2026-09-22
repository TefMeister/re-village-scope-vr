# 2026-09-22 (b) — the morning builds worn, what the log says, and the afternoon builds

Home PC. Tefa wore the three morning builds (`2026-09-22a-…`) around 11:00–11:25 and reported; this is
the reading and what was built from it. ⚠️ The game was still running when the afternoon builds finished,
so **neither new DLL is installed yet** — close the game, then `UPDATE-VR-FRAMEWORK.bat` and
`UPDATE-RIFLE-PLUGIN.bat`.

## What Tefa saw `[reported 2026-09-22]`

- Hand docked the normal way (from below, no button): *"aims like it always has, and the zero worked like
  this, shots landed exactly where they have to … from both far and near"* — but it occludes the left
  controller.
- Stacked (left grip held, hand lowered onto the rifle from above): the stacked mode engaged, the rifle
  was straight, *"but the bullets landed lower than where i was aiming"*.
- Flicker: unchanged, ~20 in a short play, *"some in a quick succession of 3 to 4 flickers in 2 second
  window"*.
- Asked for: (1) no docking without the left grip button, and no steering from a docked hand without it;
  (2) the rifle to take the straight pose when the hand docks, like the stacked pose; (3) the 25° steering
  guard removed — *"it doesn't feel natural to hold a gun this way"*.

## What the log says

- **The drawn-pose hand-off was IN USE for those shots** (`draw-pose: … IN USE`), with the old zero
  (−10.7 / −9.5, view frame — `CROSSHAIR-FROM-DRAWN-POSE.bat` was not run). While aiming, the drawn pose
  was only **4.7–6.1° from the joint pose, of which ~1–2° up and ~0.1° right**, the rest roll, and 8.7 cm
  away `[verified-live 2026-09-22, n=4 lines in the shot window]`. So the two-cameras mismatch is real
  but small in the aiming direction, and **it is not the 10° zero.** (With the scope down the game camera
  wanders 47–53° from the joint — irrelevant while aiming, worth remembering if the picture ever goes
  wild with the rifle lowered.)
- **The plane, not the pose.** With steering off and the rifle held still, the plugin's own recompute of
  the mirror plane's normal is **4.0–4.6° from the normal the Lua publishes from the pose it actually
  applies** (`11:01:55`, `11:02:03`) `[verified-live 2026-09-22, n=2]`. A mirror plane 4.5° off reflects
  the bore **9° off** — the size of the zero, and rigid to the rifle, so it changes with how the rifle is
  held (stacked = bullets low). This is the DERIVATION-error row of §9ap, never fixed. `[hypothesis]` until
  a shot test says so.
- **The stacked take happened while the hand was still travelling.** `grip-watch` 11:05:08–11:05:09:
  steering 0 → 8.9 → 16.6 → **25.0° (26.8 asked)** in three quarters of a second as the hand came up —
  the socket take (10 cm) fires before the hand is on the rifle, and the rest of the travel becomes
  steering, capped at the guard `[verified-live 2026-09-22]`. That is what the 25° guard was hiding, and
  why Tefa asks for both the button and the guard's removal.
- **Flicker:** during play the map did not move at the spikes (`centre moved (+0.0003,-0.0003)`, five of
  seven), and the map-hold stood in on **0 ticks per second** while playing (its 689 holds were bring-up
  and the rifle going down) `[verified-live 2026-09-22]`. So the map-less-tick suspect is **out** for the
  play-time flicker; the change is in the picture content the mirror hands us. Nobody has ever looked at a
  flicker frame.

## Built this afternoon (installed: NO — game was running)

1. **Grip, all three asks** (`RE8VR.cpp`, `grip-no-throw.patch`): the left grip button is the only way to
   dock (`grip_needs_button`, default true) — held near the socket or in the stacked zone it takes,
   released it lets go, and the steering reference is the hand where it was at the press, so the rifle
   keeps the right hand's aim at the take (ask 2 falls out of ask 1). The 25° limit is off
   (`grip_max_steer_deg` = 180, `GRIP-LIMIT-25.bat` restores it). `GRIP-AUTO-DOCK.bat` / `GRIP-BUTTON-ONLY.bat`.
   `dinput8.dll` build `bce0cf0a…`, 0 errors `[compile-verified 2026-09-22]`; plugin build `2cc90ba3…`.
2. **The plane test** (`crop_follow.cpp`): `re_scope_panesrc.txt` = 1 builds the map on the Lua's published
   plane (point and normal), i.e. the one the mirror really has; and a once-a-second `plane-check:` line
   says how far the two planes are apart and what that does to the aim, as seen (right / up), beside the
   zero in use. `CROSSHAIR-FROM-LUA-PLANE.bat` = plane 1 + zero 0/0. ⚠️ The Lua publishes at 2 Hz, so
   hold still a second before each shot; if it lands, the shipped fix is to read the pane's transform every
   tick.
3. **The flicker frame dump** (`spike_dump.cpp`): at each of the first six spikes, the mirror source, our
   picture and the previous shown picture are written to `reframework/data/flicker-spike-N-{src,now,prev}.ppm`.
   One wear with `PICTURE-TEST-1-ON`, then I look at the frames.

## NOT established

- Whether the plane is the zero (one shot test decides). Whether the button-gated grip feels right.
- What a flicker frame looks like — that is what the dump is for.
