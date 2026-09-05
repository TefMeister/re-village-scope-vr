# The mask was the bug — and even fixed, the sweep cannot give a gain (2026-09-05 evening, home PC, `/pd`)

**The game was not launched. Nothing here has been run.** This is a re-analysis of captures already
on disk, plus two small builds.

Three things happened: the steering ray was pointed at the scope instead of the parked rig, the
eye-box hold test was built, and the 0.5° sweep was fitted properly — which produced an honest
negative and, more valuably, found the bug that had been poisoning every image measurement today.

## 1. ⭐ The measurement bug: a hard mask locks the correlator onto its own rim

Three attempts to fit px/deg from the sweep all returned **exactly `(0,0)` with a huge peak/rms**
(around 500). I read the first two as "the picture did not move" and the third refused to report at
all. The third was right to refuse, and the reason is worth more than the measurement:

**A binary mask has enormous energy at its own edge.** After high-passing, that rim is the strongest
feature in *both* images — and it is in exactly the same place in both, because the mask does not
move. So phase correlation locks onto the mask and pins the peak at zero, with the confidence of a
perfect match. `[verified-numerically 2026-09-05]`

The fix is a **smooth raised-cosine taper in radius** instead of a hard annulus: no edge, nothing to
lock onto.

**What caught it was a positive control, and nothing else could have.** Roll the baseline by a known
`(dx = −23, dy = +17)` and ask the pipeline to recover it:

| mask | recovered | verdict |
| --- | --- | --- |
| hard binary annulus | `(0, 0)`, peak/rms 233 | **confidently wrong** |
| smooth radial taper | `(−23, +17)`, peak/rms 686 | correct, and it pinned the sign convention too |

Every image measurement on this glass from now on should carry that control. It costs two lines and
it is the difference between a number and a fiction.

## 2. The honest negative: the gain is not in these captures

With the instrument validated, the sweep still cannot answer the question — but now for a reason we
can *state* rather than guess at.

**The noise floor is ±26 px.** Two frames captured at the *same* pitch, seconds apart:

```
+0.0  dx  +6 dy  +2      +1.5  dx -11 dy -17
+0.5  dx  -7 dy +19      +2.0  dx  +6 dy -26
+1.0  dx -16 dy  +8      +2.5  dx +24 dy -15
```

**The signal is smaller than that.** Baseline against each step: `dx` runs +12, +17, +10, +2, −5 and
`dy` runs −3, 0, +14, +16, +3 — every one inside the noise, with no trend. The least-squares fits
come out at `dx` −3.5 px/deg and `dy` +4.9 px/deg with **residual rms of 7.0 and 6.0 px** — residuals
larger than the fitted change across the whole sweep. Those are not measurements.
`[measured 2026-09-05]`

Repeatability is fine (`back-p180` returns to `(+4, −4)`), so nothing drifted. The dominant noise is
the weapon's idle sway, which moves the whole scope on screen independently of any commanded angle,
and no amount of analysis removes it.

**Conclusion: 2.5° of plane pitch produces less motion than the weapon's own idle.** To get a number
you need either a much larger step with landmark tracking, or the idle suppressed.

## 3. ⚠️ A claim of my own that has to come down

This morning's write-up recorded, from the 5° sweep, that *"each 5° step replaces the picture
outright, i.e. more than ~60 px/deg"*. That rested on phase correlation finding 0–3 % patch
agreement — **a correlation failure.** We now know a correlation failure on this glass can be a
masking artefact rather than a real absence of overlap.

So **the `> ~60 px/deg` lower bound is withdrawn** and downgraded to `[hypothesis]`. What survives
from that session is what was read *by eye*: the sign (the view swings down as the plane pitches up)
rests on the monotonic ordering of six frames and a flat yaw null control, not on the correlator, and
it stands. `[measured 2026-09-05]`

The two readings are also in tension — >60 px/deg at 5° against nothing measurable at 2.5° — and that
tension is itself a reason to trust neither number until one is measured with a validated
instrument.

## 4. Also built this evening (both deployed, neither run)

- **The steering ray points at the scope, not the parked rig.** `rig_pose_once` keeps the rifle
  transform position *before* the parked offsets and passes it as `anchor_pos`. The parked position
  sat `atan(0.715/1.0) = 35.56°` off the bore, which is exactly the arc the steering computed while
  on-axis. Lua only; both numerical suites still green (61 and 71 checks).
- **`eyebox_hold_tick`** writes 0.5 every frame for ~1.5 s after a bind and reads back on the last
  frame, then restores 0.0 — the discriminator the bind-time ladder could not give. Clean build,
  149,504 B, deployed with a dated backup.

## 5. What is NOT established

- The px/deg gain, at any angle. Bounded only by "less than the idle sway over 2.5°".
- Whether the picture rolls with pitch — the same captures would have answered it, and cannot.
- Either of this evening's fixes, live. Both are built, deployed and unrun.
