# 2026-09-16g — the jitter: the eye behind the mirror hops left/right every frame, and the map aimed a fixed direction from it (`/pd`, dev PC, Fable, NO LAUNCH)

**The game was not launched and nothing here has been run.**

## 1. The row

*The jitter is in the live render, not the map.* A frozen picture moved "soooo smoothly" under the
exact map; the live picture shakes slightly. Tefa on 2026-09-14: "noticeable but not bad". The board
suspected the eye alternating each tick (the projection's off-axis term flips sign every tick) and
asked for the map to be built per eye.

## 2. What the code says, and the reading it leads to

- **The exact map is built from directions only.** `sg_compute` takes the rifle frame (right, up,
  bore) and the plane normal, reflects each direction across the plane, and turns it into render
  coordinates. The glass centre shows *whatever lies along the bore direction, as seen in the mirror*.
  No position enters anywhere except through the plane.
- **The mirror's viewpoint is not the scope. It is the eye, reflected across the plane.** The
  dossier already lists this as "far field only: near objects have parallax a scope would not".
- **In the headset that eye hops sideways every frame.** The `geom:` line logs `eye moved`, the
  camera position's change per tick, and it alternates by about the eye spacing (2026-09-13c:
  "the per-eye projection alternating, `eye moved`") `[verified-live 2026-09-13, n=1 log]`. So the
  reflected viewpoint hops by the IPD, left, right, left.
- **A fixed direction from a hopping viewpoint lands on a different world point each frame.** Two
  eyes 64 mm apart, a target 10 m away: 0.37° between the two frames. The disc at 2.4× spans about
  11°, so the world slides back and forth by roughly 3% of the disc at the frame rate. That is a
  slight shake, not a spin, and a frozen picture cannot have it. It appeared with the exact map
  (2026-09-13), which replaced the earlier far-point-based crop centring `[hypothesis, fits n=1 wear]`.

**The board's own reading — H for one eye applied to a render from the other — would be a jump of
about a fifth of the render width** (the projection's off-axis term is 0.17 in normalised units),
i.e. most of the disc. That is not "noticeable but not bad", and both the pose and the projection
are read from the same camera in the same tick, so they cannot disagree with each other. The
parallax reading is the one that fits the size.

## 3. What was built (compile-verified, tested numerically, deployed on the dev PC, NOT run)

A real scope shows the point the bore hits, wherever the eye sits. So aim the frame at that point:

- **`sg_eye_bore`** (`scope_geom_math.h`): reflect this tick's eye across the plane, take the
  direction from there to the bore's far point F, and hand that to the frame builder in place of the
  bore direction. The far point is the raycast hit the plugin already uses for the aim pixel.
- **`eyepar 0|1`** (harness; settings `eye_par`; live through the pane file). Off by default. On, and
  with a far point available, the map is aimed this way every tick; the log prints the angle between
  the bore and the aim, with `eye moved`, once every 300 ticks.
- `tools/eye_parallax_test.cpp`, 14/14 `[verified-numerically 2026-09-16]`:
  - reflecting the per-eye aim gives exactly the direction the eye sees F's mirror image in, built
    independently as R(F) − E from a plain point reflection, for four eye positions;
  - the two eyes' aims differ by 0.363° at 10 m; the plain bore differs by 0°, which is the defect;
  - the centre-eye correction is 0.33° (the re-zero to expect, about 8 px at the measured 25 px/°);
  - at 2 km the aim is the bore; an eye reflected onto F returns 0, not NaN; a rotated set-up gives
    the same hop.

All eight suites pass; plugin 0 errors, 0 warnings; fxc OK; three Lua files compile; stubbed bring-up
29/29. Dev-PC install re-stamped 14/14.

## 4. What is NOT established

- **That the hop is the whole jitter.** Residual parallax remains for objects at other depths than
  F (a tree 3 m in front of a target at 20 m still shifts). The frozen-picture test only says the
  shake is in the live content.
- That `eye moved` really alternates by the IPD every tick under the current REFramework build; it
  was read on one launch.
- The zero moves by the eye-to-bore parallax at F, a fraction of a degree. It needs a re-check with
  `eyepar 1`, not a re-tune from scratch.

**The diagnostic that would show the derivation is wrong:** `eyepar 1` and the shake is unchanged
while the log shows the aim differing from the bore by ~0.3° and `eye moved` ~0.06 m. Then the
alternating viewpoint is compensated and the shake is something else — the render itself
(anti-aliasing jitter or temporal reprojection on the mirror pass), which `hold 1`'s summary line
would show as a small steady `avg`.

## 5. NEXT (headset, home PC)

1. `bringup`, aim at something 10 to 20 m away, hold still: note the shake.
2. `eyepar 1`: shake gone? The crosshair may sit a hair off; `dzeroup` / `dzeroright` by a degree or
   less brings it back. Read the `eyepar:` log line once.
3. If gone: write `eye_par=1` into the settings file, and re-zero on a post.
