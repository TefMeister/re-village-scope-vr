# Model 2 is built and proved to vanish on-axis, the crop can follow the scope, and the eye-box hunt may not be needed (2026-09-05 afternoon, home PC, `/pd`)

**The game was not launched. Nothing here has been run.** Everything below is a build, a numerical
result, or a reading of code and logs already on disk.

All three `[PD]` rows the 15:50 headset session left on the board are closed. Source on
`staging/re-village-scope-vr` (`2a3ec1f`); the built plugin and both scripts are deployed with dated
backups.

⚠️ Housekeeping: `/pd` §2 still lists this project as permanently out of scope, on the grounds that
a REFramework Lua project has no static-only work. That premise died when the project grew a C++
native plugin. Tefa named the game, so the exclusion was overridden — but this is the second session
in a row to override it, and the exclusion should be rewritten rather than stepped around.

## 1. Model 2 — the correction that is the identity on-axis

The headset disproved both from-scratch imaging models `[disproved 2026-09-05, n=1 each]`, and the
reason is structural rather than a sign or an axis: on-axis the eye ray `v` and the bore `d` are
nearly equal, so `n = normalize(v − d)` is a **small-difference vector nearly perpendicular to the
bore** — a large plane rotation applied exactly where none is needed. Step 5 of that session showed
the baked pose with steering off is already right on-axis.

So model 2 starts **from** the baked pose and must vanish when the eye is on the bore:

```
arc  = shortest_arc(bore, eye→mirror ray)
corr = slerp(identity, arc, k)          -- k is the knob
q    = corr · baked
```

Two new helpers sit in the shipped file's *sliceable* pure-maths block, deliberately, so a test can
load the real text rather than a copy of it: `quat_scale_angle(q, k)` (slerp from identity, written
as an axis-angle scale so `k < 0`, `k > 1` and the identity case need no special-casing) and
`steer_corr_rotation(rot, d, v, k)`.

Harness: **`model 2`** selects it, **`steerk <k>`** sets the knob live. `model 0` and `model 1` stay
in the file as the disproved pair so the disproof stays reproducible.

### The numerical result

`scripts/tests/steer_corr_test.lua` — **71 checks, 0 failed**
`[verified-numerically 2026-09-05, 71 checks against the shipped text]`. It slices the helper block
out of `re8_scope_m6_mirror_producer.lua` and `load()`s it, following the precedent set by
`steer_axis_test.lua` and, before that, by Far Cry 2 — where a transcription passed its check and
compiling the real code was what found the bugs.

What it establishes:

- **On-axis the returned rotation is the baked rotation, component for component to 1e-9.** This is
  the entire reason model 2 exists, and it is now a property rather than an intention.
- **Continuous and NaN-free into that point** — 30°, 10°, 1°, 0.1°, 0.01°, 0.001°, 1e-5°, and
  exactly 0°, with the correction never exceeding half the offset.
- **The plane turns by exactly `k × angle(bore, eye-ray)`**, checked at 2/5/10/20/45/90° of offset
  against `k` = 0.5, −0.5, 0.25 and 1.0.
- **`+k` and `−k` are exact opposites** — applying both returns to the baked pose — so the sign knob
  is a real sign.
- **Where 0.5 comes from, checked independently of the shipped code:** a plain reflection formula
  written inside the test shows a mirror swings the reflected ray by **twice** the plane's rotation
  (1°, 2°, 5°, 10°, 20°, 30°, all to 1e-4). To swing the view by the eye's angular offset, turn the
  plane by half of it.
- **Degenerate inputs are refused, not propagated**, including the antiparallel case, which at
  `k = 0.5` turns the plane exactly 90°.

The existing `steer_axis_test.lua` still passes, **61 checks, 0 failed** — the edit did not disturb
the slice or the older maths.

### What the test explicitly does NOT establish

- **The sign.** Nothing in the file picks it, and it says so in its own header.
- **Whether swinging the view by the eye's angular offset is the right target at all.** The maths
  can only confirm the law is implemented as specified; the glass judges the law.

## 2. `crop_follow` — the second cause of the jacket

The compositor samples the mirror at a fixed point. In flat ADS that is right *by accident*: the
scope sits at the exact centre of the view (`aim=(960,541)` of 1920×1080, 15 samples). In the headset
the scope is wherever the rifle is — `aim` ranged (302..1400, 870..1190) in the same run — and the
crop never followed it, so the glass showed whatever sat at the view centre.

**`crop_follow=1`** (settings key, **default 0**) makes the crop centre the aim pixel, with
`mir_cx`/`mir_cy` re-read as a **delta from 0.5** so the value tuned to slide out of the clip-plane
half still applies. The sampled window is now clamped inside the source **unconditionally** — one
rule rather than two — so a wrong frame can mis-aim but can never sample out of bounds.

It ships off. Nothing that works today changes until the key is set.

### ⚠️ A correction to the headset note's reading

That note records: *"aim values above 1080 in the headset (`(302,1188)`) mean the projection space is
not the desktop 1920×1080"*. **That is not established, and there is a simpler explanation the code
itself supports.** `project()` accepts normalised coordinates out to ±2 before refusing a point:

```
if (nx < -2.0f || nx > 2.0f || ny < -2.0f || ny > 2.0f) return false;
outy = (0.5f - 0.5f * ny) * bh;
```

so its output legitimately ranges about −0.5·bh to 1.5·bh.

Run the observed VR values back through that same formula against a 1920×1080 frame
`[verified-numerically 2026-09-05, n=3 samples from the launch-2 log]`:

| logged aim | normalised | where it is |
| --- | --- | --- |
| `(302, 1188)` | `nx = −0.685`, `ny = −1.200` | horizontally well inside; **20 % below the bottom edge** |
| `(1400, 1007)` | `nx = +0.458`, `ny = −0.865` | **entirely inside the frame** |
| `(960, 541)` (flat ADS) | `nx = +0.000`, `ny = −0.002` | dead centre |

**Every one of them is consistent with the desktop projection space**, and only a single sample is
even outside the frame — by a fifth of a frame height, vertically, which is exactly what holding a
rifle low in front of you produces. Nothing here requires a second projection space to explain.

This matters because the note made the projection question a **prerequisite** for building
`crop_follow`. It is not one: the aim pixel is projected in the backbuffer frame, so the backbuffer
frame is what normalises it, and the open question is a different and narrower one — whether the aim
pixel's frame and the *mirror RT's* UV frame agree. They demonstrably do on the backbuffer path
(same normalisation, correct picture); for the mirror they may not, and that is precisely what the
key tests.

The world log line now carries **`proj=WxH`** and **`cropFollow=`**, which turns the whole question
from arguable into readable: if `aim` exceeds `proj`, that is a point outside the frustum, not
evidence of a second projection space.

## 3. The eye-box: the recorded blocker may not exist

The board's third row reads *"find who writes `EyeDistortionRange` every frame"* and queues a
Ghidra/type-dump hunt for the writer. That framing assumes the value is being **re-asserted**.

**The plugin's own comment, written when the parameter was added and never tested, says the
opposite:**

```cpp
{ "EyeDistortionRange", 0.0f },  // eye-position distortion off (min-clamps to 0.1, fine)
```

A min-clamp and a re-assertion are different worlds — one has no writer to find at all — and
**nobody has run the test that separates them.** Both readings are consistent with everything
observed so far, because everything observed so far is a single value: writing `0.000` reads back
`0.100`.

A three-value ladder at bind time separates them, free, on any launch. It is now built:

| what the log says | reading | what to do |
| --- | --- | --- |
| `0.500→0.500` and `0.050→0.100` | **min clamp at 0.1** | There is no writer. The residual eye-box is the game's floor. **Cancel the Ghidra hunt**; either live with 0.1 or move our picture to a slot the parallax does not touch. |
| `0.500→0.100` | **re-asserted every frame** | Exactly like `Reticle_Emissive`, whose fix is already in this file: a per-frame **hold**, not a bind-time set. Still no Ghidra. |
| `0.500→0.500` and `0.050→0.050` | the write works and something **later in the frame** overwrites it | *Only now* is finding the writer the right next step. |

The ladder restores `0.0` afterwards, so whatever the clamp does, the end state is the one that
shipped.

## 4. Build and deployment

Clean Release x64 build, **zero warnings and zero errors** `[compile-verified 2026-09-05]`.
`re_scope_vr.dll` **148,992 B**, `sha256` prefix `c997a0e6922ec9b5`. Both Lua scripts pass
`loadfile` and both test suites run green.

Deployed to the game folder and hash-verified against the source. Backups taken first, all suffixed
`.pre-model2-cropfollow-backup-2026-09-05d`: the plugin, `re8_scope_m6_mirror_producer.lua` and
`re8_scope_harness.lua`.

⚠️ Before overwriting, the deployed scripts were diffed against `staging` HEAD. They differed on
**every line** — which turned out to be CRLF versus LF and nothing else; content-identical once
normalised. Worth recording, because "every line differs" is exactly what a lost-work collision
would also look like, and the two are one `tr -d '\r'` apart.

## 5. What is NOT established

- **The sign of `k`.** Theory gives the magnitude and not the sign.
- **That the half-angle law is the right target.** It is the best available model, not a measured
  one.
- **That the aim pixel's frame and the mirror RT's UV frame agree.** `crop_follow` is the test, not
  the answer, which is why it defaults off.
- **Which of the three eye-box readings is true.** The ladder decides it; nothing here does.
- Anything at all in a headset. Three builds, zero launches.
