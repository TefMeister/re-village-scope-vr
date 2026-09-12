# First worn win: the disc sits still, and the gun steers the picture (2026-09-12 afternoon, home PC `RTX`, Tefa in the headset, Claude at the files)

Two lanes in one afternoon. **15:12–15:50, hands-on** (`/ms` claim): Tefa launched, wore
and judged; Claude never touched the game beyond writing its two command files. **15:59
onward, `/pd`**: the roll cancel was built with nothing running. Evidence:
`dev-archive/recon/2026-09-12-first-worn-win-retdepth-model0/`.

---

## 1. The build was what the board said it was

Bind-time log, both lens materials, before anything was worn:

```
look: [2] Reticle_Depth_Min   authored 0.388   -> 0.000 reads back 0.000
look: [2] Reticle_Depth_Max   authored 500.000 -> 0.000 reads back 0.000
look: [2] EyeDistortionRange  shipped (0.100,0.300,0.000,0.000) -> ... reads back (0.100,0.300,0.000,0.000)
```

- The authored pair matches the material-file read of `2026-09-12c` exactly, and **the scalar
  writes land** `[verified-live 2026-09-12, n=2 materials]`.
- `EyeDistortionRange` reads as the float4 `(0.1, 0.3, 0, 0)` **through the live API** — the
  third independent confirmation of §9k, and the float4 path reaches it
  `[verified-live 2026-09-12, n=2 materials]`. §8d's "cannot be written" is now disproved in
  the game itself, not only on paper.

## 2. ⭐⭐⭐ `retdepth 0` STOPS THE DISC SLIDING — proved both ways

Blind A/B: Tefa was not told which setting was which.

| setting | Tefa, verbatim |
| --- | --- |
| `retdepth 0` (the pair zeroed) | *"it does not slide around the tube anymore, the scope glass is actually the scope glass, right where it has to be, the right way"* |
| `retdepth -1` (authored 0.388 / 500 restored) | *"yeah it slides around the tube again"* |
| `retdepth 0` again | left on |

`[verified-live 2026-09-12, n=1 wearer, A→B→A]`. **The ⭐⭐⭐ placement row is closed.** The
cause was the shipped lens shader's eye-position UV offset, exactly as `2026-09-12c` read it
off the disassembly; the fix is the two scalars that scale it. `retdepth 0` is the boot default.

## 3. Now the CONTENT was judgeable for the first time, and it read like a textbook

With the disc still, the remaining complaint — *"the picture still moves with my head"* — could
finally be tested against the right symptom. Everything below was hidden behind the sliding until
today, which is why every content result from 2026-09-05 onward has to be re-read as "aimed at
the wrong symptom" **in both directions**: the disproofs of the steering models are void too.

**`cropfollow 0`** (crop centre fixed, the mirror plane still the baked horizontal one):

> *"picture moves left and right with head movement, but not gun movement. up and down it moves
> with gun movement and head movement is like inverted — moving my head up moves the picture
> down"* `[verified-live 2026-09-12, n=1 wearer]`

That is the exact signature of a **horizontal planar mirror**: a flat mirror under the line of
sight preserves yaw (left/right follows the head) and inverts pitch (head up → picture down).
The wearer described the reflection law without knowing it. The mirror's viewpoint is welded to
the eye, not the rifle — a mirror can only ever show the eye's reflected view — so the plane has
to be *steered* to compensate, per frame.

**`model 2`, `steerk 0.5`, `steer 1`** (the "correction" model, identity on-axis):
> *"same as before"* — and the log agreed: the pane normal stayed within ~6° of −Y. Model 2 is
built to do nothing when the eye is on the bore, which is exactly where the eye is when aiming.
Wrong tool for this symptom `[verified-live 2026-09-12, n=1]`.

**`model 0`** (the exact reflection law, `n = normalize(eye→pane − bore)`; "DISPROVED" on
2026-09-05 — against the sliding, which was never real):

> *"better and worse at the same time, picture is upside down but now turning my head rotates the
> picture, aiming with gun also moves the picture left right up down and Ethan's clothes do
> rarely show on the scope, but the scope itself is not locked to upside down, but rotating as I
> look and aim"* `[verified-live 2026-09-12, n=1 wearer]`

⭐⭐ **The gun steers the picture.** That is the scope doing its job for the first time in this
project. Ethan's jacket — the 2026-09-05 "jacket" symptom — has mostly gone with it, because the
reflected ray now lands on the target instead of on the player.

**The one remaining defect is roll**, and its shape was pinned in one more question:

> *"both head and gun roll the picture, but head tilting does not seem to have an effect. does
> not seem, because it's hard to judge when the picture rolls with the slightest movement"*
> `[verified-live 2026-09-12, n=1 wearer, hedged on the tilt part]`

Head tilt not rolling it rules out the rifle's own roll (`roll_k`, still 0) and the head's own
roll. Head *movement* and gun movement both rolling it is the mirror plane swinging to track the
eye: a planar reflection maps the camera's up to `reflect(up, n)`, and as `n` turns by α about
the bore the picture turns by 2α (the mirror law). One flat mirror cannot be direction-correct
and roll-free at the same time. But the roll is computable from the pane in use, so it can be
cancelled in the compositor, which already owns a source-sampling rotation.

## 4. Built with nothing running: the steered-mirror roll cancel (`/pd`, 15:59–)

- **`src/mirror_roll_math.h`** — `mirror_roll_rad(cam_fwd, cam_up, n, use_world_up)`: reflect the
  camera forward and up across the pane, measure the signed angle from world-up to the reflected
  up about the reflected forward, and return its deviation from 180°. Why 180°: the baked pane is
  a horizontal mirror, which always turns the picture exactly upside down, and the shipped look
  already pays for that with `flip_h + flip_v` (together a 180° turn). So the baked pane returns
  **0** — today's picture unchanged — and a swung pane returns the excess.
- **`tools/mirror_roll_test.cpp`** — against the shipped header: horizontal mirror → 0 at 35
  yaw/pitch poses, both camera-up modes; normal turned by α about the forward → **2α**, α = −40…40°,
  checked against a first-principles reflection AND against the mirror law; degenerate pose
  (reflected forward parallel to world-up) reports `ok = 0`. **89 / 89**
  `[verified-numerically 2026-09-12]`. The first run failed 8 of the mirror-law lines: the
  expectation had been written with a hand-waved sign (−2α); the first-principles line passed, so
  the header was right and the guess was wrong. Fixed in the test, not the code.
- **Plugin:** computed every tick in `crop_follow_update` from the pane **actually driving the
  mirror** (the Lua's steered normal when `steer` is on and published, else the baked one) and the
  camera; applied at the compositor as `roll_k·rifle_roll + mroll_k·mirror_roll`, so either term
  at 0 removes only itself. Once-a-second log line now ends `| mroll X deg mode M k K`.
- **Two live knobs** (harness → pane file → plugin, persisted): `mrollk <k>` — **signed**, because
  `flip_h`/`flip_v` mirror the picture and a mirrored picture reverses the sense of a rotation, so
  +1 / −1 is a headset question; 0 = off. Default **1**. `mrollmode 0|1` — 1 = camera up is world
  +Y (a camera that never rolls; matches the hedged "head tilt does nothing"), 0 = the real camera
  up. Default **1**. Both `-9`/absent = not commanded.

Build clean, `/Brepro`; both Lua files pass `luac -p`; both `string.format` calls arity-checked
(24-line pane file, 16-argument harness line). Deployed and stamped (4 files). **Not run.**

## 5. The next wear — exact sequence, since nothing steering-side persists

The settings file was never written this session (no numpad key was pressed), so boot gives the
compiled defaults: `retdepth 0`, `eyedist -1`, `mrollk 1`, `mrollmode 1`, `crop_follow 1`
(settings). Steering and the model live in the Lua and reset at launch. From the files, in order:

```
keys:  110            (numpad .  — latch re-arm, BEFORE the first p10)
cmd:   fn p10
cmd:   fn drive_on
keys:  106            (numpad *  — bind the glass; read the look: lines)
cmd:   cropfollow 0
cmd:   model 0
cmd:   steer 1
```

Then the A/B that decides the roll cancel, judging **only whether the picture spins as the head
and gun move**:

| step | expect |
| --- | --- |
| `mrollk 1` (boot) | spin gone or clearly reduced ⇒ sign right |
| `mrollk -1` | if `1` made it *worse*, this is the one |
| `mrollmode 0` (with the winning sign) | only if head *tilt* now visibly rolls it — mode 0 tracks the real camera up |
| `mrollk 0` | the control: the spin comes back |

Log line to read: `crop-follow: … | mroll X deg mode M k K` — `X` should swing tens of degrees as
the head moves with `model 0`, and sit near 0 with steering off.

## 6. What is NOT established

- That the computed roll matches the *seen* roll. The maths is checked; the mapping from the pane
  the Lua publishes to the pane the engine's mirror actually uses is `lua-pane agrees` in the log,
  not measured against the picture. One wear decides it.
- The sign, and which camera-up. Both are live knobs for that reason.
- Whether `cropfollow` should go back ON once the pane is steered (with the reflected ray on the
  bore the crop centre should sit near the image centre). Untested; left OFF for the wear so one
  thing changes at a time.
- Head tilt: *"does not seem"*. `mrollmode` covers both readings.
