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

## Second wear (evening) and what followed `[reported 2026-09-22]`

- *"hand docking feels good now"* — the button-only grip stays. But docking from below and from above
  leaves the rifle at **different angles**, and Tefa wants one thing first: **the rifle must snap so the
  forestock sits in the left hand at every take** ("always the same position in the player's left hand"),
  whether the button is held on the way in or pressed once the hand is already there.
  → **Built and installed:** praydog's absolute steering is the default again (`grip_relative = false`),
  now taken at the button press instead of at 10 cm, so it does not throw; the frozen socket (§9cg) is
  applied in both modes so the first-shot jump does not return. `GRIP-KEEP.bat` = the relative mode.
  `dinput8.dll` `2150cdbc…`.
- `CROSSHAIR-FROM-LUA-PLANE.bat`: *"made the picture turn and rotate in all sorts of ways"* — expected
  and worse than warned: the Lua's plane arrives at 2 Hz and the `plane-check` line read **53.5°** while
  moving. And at rest with steering ON it read **0.0°** — the morning's 4.0–4.6° lines were taken with
  steering OFF, where the map uses the baked pane. So with steering on the plane is **not** the zero.
  Lever left in, default off. `[disproved 2026-09-22]` as the zero while steering is on.
- The DRAWN-POSE / JOINT-POSE helpers *"made the picture flip backwards"* — the drawn pose IN USE turns
  the picture over whenever the game camera wanders from the joint (47–53° with the scope down). Default
  now **logged only** (`re_scope_drawpose.txt` = 0).
- ⚠️ **Tefa believes "this morning the 0/0 worked".** It did not run: the morning's shots landed with the
  old −10.7 / −9.5 (the log shows it), because `CROSSHAIR-FROM-DRAWN-POSE.bat` was never run. Said so in
  the reply; the 0/0 zero has not yet been shown to work anywhere.
- Flicker test run (`PICTURE-TEST-1-ON`, `-3-OFF` not pressed): summary `frames=1800 spikes=0 avg=0.0386
  max=0.192` — **no spikes at all** although flickers were seen, because a busier scene lifted the
  running average past the 4× rule, so **no frames were saved**. The dump now also fires on an absolute
  change (d ≥ 0.10, at most once a second, numbered 1001+), so it cannot come back empty again.

## Third wear (12:28–12:35) `[reported 2026-09-22]`

- **The grip is settled.** Tefa: *"yes! a major thing you have done, the actual snapping of two handed
  weapons needs to be like this! no occlusion can occur unless pointing down by quite a lot … this is one
  biiiig thing sorted!"* → a universal rule now (`claude-memory/PREFERENCES.md`, memory file
  `feedback-two-handed-grip-snap-on-button`): dock only while the grip button is held, snap the forestock
  into the support hand at the press, no angle cap, frozen socket kept. Visceral gets the same change.
- **"Picture in scope is still backwards" — my evening switch-off caused it, and it is undone.** The
  session's map centres read (1.04, 0.15), (0.74, −0.62) — off the render — against ~(0.5, 0.6) in the
  morning, with the drawn pose *logged only*. The game camera (which the mirror is drawn from, plan C)
  sat **15–37° from the joint while aiming** this session (`+14.9 … +34.6 up`), against 2–6° at 11:03.
  So the gap is not constant, and the joint pose is the wrong pose for the map whenever they drift apart.
  The picture was right all morning WITH the drawn pose in use and went backwards at 11:49 the moment the
  JOINT-POSE helper switched it off `[verified-live 2026-09-22]`. **Drawn pose IN USE is the default again**
  (`re_scope_drawpose.txt` = 1, code default 1). ⚠️ Lesson: I blamed the lever for what its removal did.
- **Flicker frames: the capture works, the session does not count.** Five captures (`flicker-spike-1,
  1001, 2, 1002, 1003`), 15 files. Every composed frame is the wrong-pose picture (rotated, warped,
  cropped at the edge), so nothing can be read about the flicker from them; the mirror SOURCE frame is a
  clean, upright first-person view with the rifle in it, which at least shows the source is sane. Re-run
  with the drawn pose on. PNG copies kept out of git (size); the PPMs stay in `reframework/data/`.

## NOT established

- What a flicker frame looks like — next `PICTURE-TEST-1-ON` with the picture right.
- What a flicker frame looks like — the dump now has two triggers.
- The zero: both of today's leads are out or small; it is unexplained again. `MODEL: FABLE` when it is
  next taken up, and start from a measurement, not a derivation.
