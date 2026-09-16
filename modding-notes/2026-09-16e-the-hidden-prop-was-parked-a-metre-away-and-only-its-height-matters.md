# 2026-09-16e — the hidden prop was parked 1.24 m from the rifle, and only its height changes the picture (`/pd`, dev PC, Opus, NO LAUNCH)

**The game was not launched and nothing here has been run.**

## 1. The row

*Move the prop (the hidden hand host) as close to the rifle as possible.* Branches, clothing and
sometimes the ground show in the scope picture when nothing is in front of the real scope
`[reported 2026-09-14]`.

## 2. What the code says

- **The prop is not at the rifle.** Every frame the producer copies the rifle's pose onto the prop and
  then adds three offsets: **1.0 m forward, 0.2 m down, 0.715 m left**. Those are the "user's
  hand-tuned working set" from a flat screenshot on 2026-08-30, set again by `fn p10` on every rig. The
  prop sits **1.245 m** from the rifle root `[verified-numerically 2026-09-16]`.
- **The worn pane's plane faces along the rifle's up/down axis.** Pitch 180 and yaw 90 turn the rig's
  local up into the rifle's down.
- **So forward and left lie inside the mirror plane.** A flat mirror is fully described by its plane,
  and sliding it within that plane changes nothing. Only the **0.2 m drop** moves the plane.
  `plugin/tools/prop_offset_check.cpp` runs the shipped `cf_pane_from_rig` and checks this, including
  with a rotated rifle: 5/5 `[verified-numerically 2026-09-16]`.
- **The exact map never uses the prop's position.** `sg_compute_P` builds the picture from the plane's
  direction and the rifle's axes only `[inferred-static 2026-09-16]`. So pulling the prop in cannot
  change the zero or the map.

**Consequence.** Pulling the prop in along the plane should leave the picture unchanged; nobody has
checked that in the game yet. It still has two possible benefits:

- **The hand stops floating an arm's length to the left.** It is invisible, but it is a real object.
- **It stays in view whenever the scope is in view.** On 2026-09-13 a mirror was seen to stop
  producing when its host mesh was not drawn `[verified-live 2026-09-13, n=1]`. A host 72 cm to the
  side can leave the camera's view when the head turns, and the engine may then skip drawing it
  `[hypothesis]`. If so, that would freeze the picture for as long as the host is out of view.

**What actually decides near clutter is the drop (`off_u`).** Moving the plane moves the mirror's
virtual viewpoint by twice that distance, which changes what is close to it. Why branches and
clothing show at all is not worked out here. The mirror's clipping in RE Engine has not been studied.

## 3. What was built (Lua compiles, stubbed bring-up test 29/29, deployed on the dev PC, NOT run)

- **`propnear`**: forward and left set to 0, the drop kept. **`bringup` now does this** as its last
  setting step, after the zero.
- **`propoff`**: back to the 2026-08-30 parking.
- **`propf` / `propu` / `propr <m>`**: one axis each. The log line says whether that axis moves the
  plane.
- The stubbed bring-up test caught a crash in the first draft: the log line assumed the offsets always
  existed. Fixed before deploy.

## 4. What is NOT established

- That the engine's mirror really behaves as an infinite plane. If it clips or culls by its host's
  bounds, the in-plane offsets do matter and `propnear` changes the picture.
- Whether any `propu` value removes the clutter, or only trades one intrusion for another.
- Whether the picture ever froze because the host left view. This has not been observed. It would
  look like a stall when the head turns hard right.

**The diagnostic that would show the derivation is wrong:** after `bringup` (which now pulls the prop
in), the picture is different from before. Compare with `propoff`, then `propnear`. Different
pictures mean the plane model is incomplete. Same pictures confirm it.

## 5. NEXT (headset, home PC)

1. `bringup`, then `propoff`, then `propnear`: **does the scope picture change at all?** It should not.
2. With `propnear`, where branches or clothing show: `propu 0`, then `propu 0.1`, then `propu -0.4`.
   Which one has the least clutter? Check the zero on a post after changing it.
