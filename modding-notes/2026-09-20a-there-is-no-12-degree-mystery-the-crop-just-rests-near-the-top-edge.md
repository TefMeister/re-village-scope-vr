# There is no 12° mystery — the crop simply rests near the top edge

**Supersedes: `modding-notes/2026-09-19g-two-aiming-paths-disagree-and-the-vertical-is-the-one-thats-wrong.md`
(its "~12° unexplained" claim), and ENGINE-DOSSIER.md §9aw's repetition of it.**

**2026-09-20, home PC (RTX). Static; nothing launched.** Tool:
`plugin/tools/crop_centre_decompose.cpp`, **9 checks, 0 failed** `[verified-numerically 2026-09-20]`.

## The retraction

Last night I wrote that the two crop-centre paths disagree by 26° vertically, that the zeroing
explains 14.4° of it, and that **~12° was unexplained**. The 12° was my own arithmetic error.

I compared the two paths assuming they build `v` the same way. They use the same *formula*
(`v = 0.5 − 0.5·ndc_y`, in both files) but from **different projections**:

- the **geom** path uses the real projection matrix (`P real` in the log) — an HMD eye projection,
  which carries an **off-centre term `m21 = −0.2111`**;
- the **legacy** path builds NDC from `fov` + aspect, which is **symmetric** and has no such term.

So a constant **+0.2111** of `ndc_y` exists in one and not the other before anything else differs.
I left it out, and it reappeared as a mystery.

| | ndc_y |
| --- | --- |
| observed gap | **+0.5940** |
| the off-centre term the legacy path cannot have | +0.2111 |
| the zeroing, 14.4° up, geom path only | +0.3003 |
| **the two together** | **+0.5114** |
| **residual** | **+0.0826 = 4.0°** |

**4.0°, against a bore whose vertical share is not even logged** — the 15.0° is the total angle off
the gaze, direction unknown. So the residual is an *upper bound* on anything remaining, not a
measurement of it. There is nothing here worth chasing.

⚠️ **Note what the error looked like.** Forgetting one term turned 4° into 14.1° — and 14° feels
like a real fault, so it got written up as one, with a plan attached. Exactly the §9aq failure again,
eighteen hours later: correct arithmetic, wrong about what it was arithmetic *about*.

## ⭐⭐⭐ The finding that replaces it, and it is a better one

**The crop does not start in the middle of the frame. It starts halfway to the top edge.**

With the bore **exactly on the gaze** — the best case, perfectly aimed — the two terms above still
put the crop centre at:

```
ndc_y +0.5114  ->  v = 0.244
```

`v = 0.5` is the middle; `v = 0` is the top edge. **0.244 is 51% of the way from the middle to the
top.** That is where it *rests*, before the rifle moves at all.

From there it takes very little to run out:

| bore moves up by | crop centre v |
| --- | --- |
| 0° | 0.244 |
| 5° | 0.193 |
| 10° | 0.141 |
| 15° | 0.088 |
| 20° | 0.031 |

**It leaves the top edge at about 21° of upward bore movement** — and 21° is ordinary handling, not
a stunt. **Without the zeroing it would be 32.7°.** `[verified-numerically 2026-09-20]`

## What this explains, and what it costs

- **Why the streak arrives so easily**, and at angles normal play reaches. Not because the frame is
  too narrow (§9aq's story, premise disproved in §9av) but because the crop **begins most of the way
  to an edge**.
- **Why it is one-sided.** A resting place 51% of the way to the *top* is nowhere near the bottom.
  Tefa: *"it barely shows up on the left side"* — an off-centre rest is by construction close to one
  edge and far from the other.
- **Why the picture reads as aimed low.** With `rot 180` in the path, taking from high in the
  texture shows as low in the scope.

⚠️ **The zeroing is NOT a fault and must not be "fixed" by deleting it.** `zero up 14.4` is what puts
the shot where the crosshair is; it was measured and confirmed accurate by the wearer. It costs
**11.6° of the headroom** (32.7 → 21.1) and that is a real trade, but the answer is to find the
headroom elsewhere, not to un-zero the scope.

## Where this points next — all static

The two contributions to the resting offset are different in kind:

1. **The zeroing (+0.3003)** is wanted. It has to be paid somewhere.
2. **The off-centre term (+0.2111)** is *inherited from the HMD eye projection* and has nothing to
   do with the rifle. ⭐ **It is the one to question.** §9av proved the mirror does not render with
   the projection we can write — but the plugin still *reads* that projection to decide where to
   crop. If the mirror's true projection is symmetric, then this term should not be in the crop
   maths at all, and removing it alone moves the resting place from **0.244 to 0.350** and buys back
   roughly **9° of headroom**, for free, with no effect on the zeroing. `[hypothesis]`

That is a one-line change to test (`geom_usep 0` switches the geom path off the real P and onto the
symmetric fov build) and it is **live-settable, no rebuild** — the same channel as the A/B scripts
already in the game folder.

⚠️ Not asserted: that the mirror's real projection is symmetric. Nobody has measured it. §9av only
established that it is *not the one we write*.

Credit: **praydog** (REFramework), **gmankab** (the `pd-upscaler` fork).
