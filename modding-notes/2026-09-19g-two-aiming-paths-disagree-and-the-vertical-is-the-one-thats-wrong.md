# Two aiming paths disagree, and the vertical is the one that's wrong

**2026-09-19 late, home PC (RTX). Static analysis of live log lines; the game had been closed by the
time the A/B was ready.** Follows §9aw, and narrows it considerably.

## The finding: the mod computes the crop centre TWICE, and the two disagree

Both are printed on the **same tick**, from the same inputs:

```
crop-follow: mode=2 refl/shared -> (0.576,0.361) | direct/shared=(0.581,0.361)
             direct/16:9=(0.543,0.361) refl/shared=(0.576,0.360) | bore 15.0 deg off the gaze
geom: ON     centre=(0.735,0.064) ... hm -1 proj 0 rot 180 P real | zero up 14.4 right 9.5
```

| | u | v |
| --- | --- | --- |
| dead centre | 0.500 | 0.500 |
| the **legacy** crop path | 0.576 | **0.361** |
| the **geom map** (what actually draws) | 0.735 | **0.064** |

`present.cpp:499` confirms which one reaches the screen: `geom_on = g_geom && use_mirror &&
h_ok` → the shader is handed the geom homography. **The legacy numbers are computed, logged, and
discarded.** `[inferred-static 2026-09-19]`

**The horizontal disagreement is modest; the vertical one is a quarter of the whole frame.**

## Decoding what those numbers mean in angles

From `sg_compute_P` (`scope_geom_math.h:229`), with `hm = -1`:

```
cu = 0.5 - 0.5 * ndc_x        cv = 0.5 - 0.5 * ndc_y
ndc_y = m11 * (y/|z|) + 0.2111        m11 = 1.1696
```

| | ndc_y | the bore, in camera terms |
| --- | --- | --- |
| legacy, v = 0.361 | +0.278 | **3.3° up** |
| geom, v = 0.064 | +0.872 | **29.5° up** |

**A 26° vertical disagreement, while the bore is only 15.0° off the gaze in total.**

## Where that 26° comes from — one part found, one part not

**Found: the zeroing is applied in the geom path only.** `crop_follow.cpp:178-189` tilts `bore_in`
by `zero_up 14.4°` / `zero_right 9.5°` before building the frame; the legacy path uses the raw bore.
That is deliberate — the zeroing is what makes the crosshair sit where the shot lands — and it
accounts for **14.4° of the 26°** `[inferred-static 2026-09-19]`.

⚠️ **NOT found: roughly 12° of extra upward throw.** 3.3° + 14.4° = 17.7°, which maps to cv ≈ 0.21.
Measured is **0.064**. Something in the geom path is adding around another dozen degrees of "up"
that the legacy path does not, and that the zeroing does not explain. `[hypothesis]`

## What is RULED OUT, which matters

- **The mirror reflection is not the culprit.** The legacy line prints both `direct/shared=(0.581,
  0.361)` and `refl/shared=(0.576,0.360)` — **the reflected and unreflected answers differ by 0.005
  in u and 0.001 in v.** The reflection is very nearly the identity for this direction, which is
  exactly what §9ar's pane fix (pitch 90 / yaw 90) was supposed to achieve. **It is working.**
  `[measured 2026-09-19, n=1]`
- **It is not horizontal.** Both paths agree u is a little right of centre. The fault is vertical.
- **It is not the projection we tried to steer.** §9av settled that.

## Two candidates for the missing 12°, neither tested

1. **The rifle frame's forward is not the zeroed bore.** `sg_rifle_frame_rh` returns `out_d = d`
   normalised, so it should be — but `frame_v` defaults to **1**, which takes the *other* branch,
   `sg_rifle_frame(bore_in, rup, rxx, ...)` followed by `sg_frame_adjust(..., rot 180, flip 0)`.
   **A 180° roll about the bore does not change the forward**, so this should be innocent — but it
   is the branch actually running and it has not been checked against the numbers.
2. **The per-eye aim.** `g_eyepar` defaults to **0**, so it should be off and the log agrees
   (no `eyepar:` lines). Probably innocent; listed so it is not silently assumed.

⚠️ Both are `[hypothesis]`. The honest state is that **one term is unaccounted for**, and guessing
which is how §9aq went wrong.

## The cheap experiment, ready to run

`geom 0` falls back to the legacy path live — no rebuild, no relaunch. If the aim is visibly better
on the simple path, the geom map is carrying the fault and the 12° is worth hunting properly. If it
is no better, the fault is upstream of both and the disagreement is a side issue.

Shipped as **`AIM-TEST-A-SIMPLE.bat`** and **`AIM-TEST-B-DETAILED.bat`** in the game folder.
⚠️ The simple path also drops the stretch/skew correction, so the picture may look slightly
distorted under A — **judge only where it POINTS**, not how it looks.

## ⚠️ What this does NOT establish

That (0.5, 0.5) is the right target. Under this pane pose and `rot 180`, with the eye projection's
own off-centre terms, even a perfectly aimed bore computes to about **(0.59, 0.39)**, not (0.5, 0.5).
So "it isn't 0.5" was never the finding — **the finding is that the two methods disagree by 26°
vertically and only 14.4° of that is explained.**

Credit: **praydog** (REFramework), **gmankab** (the `pd-upscaler` fork).
