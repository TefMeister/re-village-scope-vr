# The flat control failed — and named the root cause all three steering models share (2026-09-05 evening, home PC, `/lm`)

One launch, flat, driven end to end from outside (`dev-archive/tools/re8drive.py`; Tefa started the
game after Steam swallowed the first handoff, then went back to work). Closed gracefully through
`WM_CLOSE`. Plugin **148,992 B** `c997a0e6922ec9b5` and the two scripts built by this afternoon's
`/pd` pass. Evidence: `dev-archive/recon/2026-09-05e-flat-control-and-eyebox-ladder/`.

## 1. ⭐ The control failed, and it cost one flat launch instead of a headset session

The `/pd` session queued this deliberately as a **control, not a feature**: flat ADS is on-axis, and
model 2 is provably the identity on-axis (71 numerical checks), so **turning it on flat must change
nothing.**

First, the premise checked out. In flat ADS the plugin's own anchor reads

```
local=(0.00, 0.00, -0.22)   px=(970,529)   aim=(966,539)   proj=1920x1080
```

— the scope sits **exactly on the camera's forward axis**, 22 cm ahead, dead centre of the frame.
So the eye→mirror ray really should be the bore. `[verified-live 2026-09-05, n=1]`

Then `model 2` + `steerk 0.5` + `steer 1`:

```
steer: model=corr k=0.500 bore=(0.99,0.00,0.10) eye->mirror=(0.76,-0.25,0.60)
       arc=35.3 deg -> applied 17.6 deg
```

**A 35.3° arc, on-axis.** The picture changed completely — upright reeds against a warm wall became
snow, a fallen log and ground from a different angle. `steer 0` brought the reeds straight back, so
the change was ours and fully reversible (A → B → A). `[verified-live 2026-09-05, n=1]`

### The root cause, and it is not the maths

The maths is right: the correction is the identity when `v == d`, proved to 1e-9. **The inputs are
wrong.** The pane's parked placement, echoed by the producer on every slider line, is

```
sliders: pitch=180.0 yaw=90.0 fwd=1.000 up=-0.200 right=-0.715
```

A point 1.0 m forward and 0.715 m to the right sits **`atan(0.715 / 1.0)` = 35.56°** off the forward
axis. The steering logged **35.3°**, and recomputing the angle between the two vectors it printed
gives **35.27°**. `[verified-numerically 2026-09-05]`

**The arc is the rig's own parked offset, in full.** `steer_rotation` takes `mirror_pos` to be where
the mirror is, but that position is a *rendering placement* chosen on 2026-08-30 to make the flat
picture look right — not the optical position of the scope glass. The eye→mirror ray therefore
points 35° off the bore no matter where the eye is, and a correction built on it can never vanish
on-axis.

**This is the failure all three models share.** Both models disproved in the headset on 2026-09-05
also derive their direction from `mirror_pos`; every one of them was fed a vector that is 35° wrong
before any imaging assumption is even reached. The headset session read that as "the imaging model
is wrong". It was upstream of the model.

**The fix is named, and it is small:** the plugin already tracks the thing the ray should point at —
the lens anchor, which reads `local=(0,0,-0.22)` in ADS, i.e. genuinely on the bore. Point `v` at the
scope glass rather than at the rig's parked transform (or subtract the parked offset). That is
static work; it is a `[PD]` row now, not a headset question.

## 2. ⭐ The eye-box ladder: the cheap explanation is dead

The ladder built this afternoon printed on **both** lens materials at bind time:

```
eye-box ladder [2]:  0.500->0.100  0.050->0.100  0.000->0.100
eye-box ladder [3]:  0.500->0.100  0.050->0.100  0.000->0.100
```

`[verified-live 2026-09-05, n=2 materials, 1 launch]`

Against the decision table the ladder was built with:

- **`0.500 → 0.500` with `0.050 → 0.100` = a min clamp.** **Not what happened.** A clamp at 0.1 would
  have let 0.5 through untouched. **The plugin's own long-standing comment — "min-clamps to 0.1,
  fine" — is `[disproved 2026-09-05]`.**
- **`0.500 → 0.100` = the value is not ours to set.** This is what happened, on both materials, for
  every input.

⚠️ **Two readings survive and the ladder does not separate them**, so neither should be written down
as settled:

1. The game **re-asserts** the value every frame, exactly like `Reticle_Emissive` — whose fix is
   already in this file, a per-frame **hold** rather than a bind-time set.
2. **The write never lands at all**, and `0.100` is simply what the material already held. This is
   the likelier of the two on the evidence: the write goes through
   `set_material_float_verified`, which tries multiple encodings and reports failure, and it does
   report failure (`<-- STILL FAILS UNDER EVERY ENCODING`).

**The discriminator is one line of code, not a Ghidra hunt:** hold the value at 60 Hz for a second
and read it back. Still `0.100` ⇒ the write is not landing and the variable index or encoding is
wrong; changes ⇒ it was re-assertion. **Either way the "find who writes it" hunt stays cancelled** —
nothing in this session supports it, and the cheap test comes first.

## 3. ✅ The projection correction, confirmed live

This afternoon's `/pd` pass argued statically that an aim pixel outside the frame is a point outside
the frustum, not evidence of a second projection space. The first gameplay line settled it:

```
world[ok-body]: ... px=(1983,1481) axis=2 aim=(51,372) proj=1920x1080
```

**`px` is outside a 1920×1080 frame on both axes — in FLAT, where there is unambiguously only one
projection space.** `[verified-live 2026-09-05, n=1]` The reading recorded on 2026-09-05 morning is
`[disproved]`, and it is no longer a prerequisite for anything.

## 4. ⚠️ My own instrument failed twice, in the same way, and I nearly published it

The 0.5° sweep captured cleanly — pitch 180.0 → 180.5 → 181.0 → 181.5 → 182.0 → 182.5 → 180.0, every
command echoed by the harness and every one reflected in the producer's `sliders:` line. The
**measurement** is what failed.

- **Attempt 1** built its mask from "high variance across the sweep". Animated grass and birds
  *outside* the scope are high-variance and cover far more of the frame than the scope picture, and
  they do not move when the plane pitches. Every pair correlated to exactly `(0,0)` with a peak/rms
  near 500 — a confident, precise, meaningless zero.
- **Attempt 2** tried "changes with pitch, not with time" and drifted onto the whole frame again.
  Its own guard caught it (mask fill 0.10 of its bounding circle, i.e. not a disc), which is the
  only reason it was not believed.
- **Whole-frame mean-abs is useless here** and nearly produced a third wrong answer: the model-2
  test, whose two pictures are *unmistakably different by eye*, scores meanAbs 14.6 against a
  same-state noise floor of 10.0. A 20° pitch step scores 10.7 against 9.3.

What settled it was the `/lm` rule about preferring a cheap decisive observation to a statistic that
has to out-run scene noise: **a 40° step, and look at it.** The picture was completely different, and
the heartbeat confirmed the rig quaternion moved (`rq=(-0.05,0.34,0.94,0.02)` at pitch 220 versus
`(-0.05,0.00,1.00,0.00)` at 180). So the plane *is* posed by the slider, and by eye the +2.5° frame
is the same view shifted slightly — a small, real motion.

**No px/deg number is claimed.** The captures are good and on disk; fitting them needs a mask built
on the actual disc geometry and **needs no game at all**. That is a `[PD]` row.

Third time this project has been bitten by an instrument reporting a confident wrong answer (the
reticle lock this morning, and these two). The pattern is now explicit in the dossier.

## 5. Also confirmed this session

- **1920×1080 `.rtex` in use, no fallback** — `mirror RT: using movie/rtex/movie_1920_1080.rtex
  (1920x1080)` `[verified-live 2026-09-05, n=3 launches now]`.
- **The bind-order guard is still disabled**, as designed, for want of a stable texture identity.
- The harness echo now carries `model=` and `k=`, so a sweep log can be read back without guessing
  which model produced it.

## 6. Automation, scored (§5a)

- **Menu → gameplay: PROVEN in VR-runtime-present flat mode**, driven end to end — Insert to close
  the overlay, F on Continue, Up to move off the default **No**, F, F on the load splash. Every step
  captured and verified before committing, per the destructive-menu rule.
- **Commands: PROVEN** — the command file, plus numpad-by-virtual-key. `re8drive.py num` only covers
  the digits, so `VK_DECIMAL` (re-arm mirror latch) and `VK_MULTIPLY` (bind glass) needed a small
  helper, now in the recon folder as `vk.py`.
- **Character + camera: NOT exercised** this session.
- **Self-close: PROVEN** — `WM_CLOSE`, window gone within seconds.
- ⚠️ **Launch itself failed once**: `start steam://rungameid/1196590` sent while Steam was still
  starting produced no process and no log growth at all. Steam must be up first; the profile's
  "~40 s to title" assumes a warm Steam.

## 7. What is NOT established

- Which of the two surviving eye-box readings is true.
- The px/deg gain, and whether the picture also rolls with pitch.
- Anything about the fix in §1 — it is named and argued, not built or run.
- Anything in a headset. This was flat throughout.
