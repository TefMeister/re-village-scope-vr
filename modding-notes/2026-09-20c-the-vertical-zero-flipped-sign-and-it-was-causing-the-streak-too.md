# The vertical zero flipped sign — and it was causing the streak as well

**2026-09-20, home PC (RTX), live, wearer firing.** The measurement that ties the aim and the streak
together.

## What was measured

`ZERO-A-OFF` (zeroing 0 / 0), ~10 m from a wall, one shot at a marked point. Screenshot with the aim
point and the hit circled `[measured 2026-09-20, n=1 shot, one spot]`:

**The bullet landed RIGHT of and BELOW the aim point** — roughly 7° each way, from the offset as a
fraction of the frame (≈7.6 % of width, ≈8.7 % of height, against ~91° × ~81°).

Tefa also reported: **`ZERO-B-SHIPPED` is "way off"**, and ⭐ **`ZERO-A-OFF` does not produce the
streaking lines at all.**

## 1. ⭐⭐ The vertical correction has REVERSED since the shipped zero was made

`re8_scope_harness.lua:496` records the 2026-09-13 condition in one line:

> *"the crosshair sat down-left of where the bullets land"*

i.e. in September the bullets landed **up and right** of the crosshair, so the correction was
**+up +right** — the shipped `zeroup 14.4` / `zeroright 9.5`.

Today the bullets land **down and right**.

| axis | 2026-09-13 | 2026-09-20 | verdict |
| --- | --- | --- | --- |
| horizontal | bullets RIGHT of crosshair | bullets RIGHT of crosshair | **same sign** — `zeroright` was roughly right |
| vertical | bullets ABOVE crosshair | bullets **BELOW** crosshair | ⭐ **SIGN FLIPPED** |

**So the shipped zero pushes 14.4° up when a few degrees DOWN are now needed** — an error of around
18–21°, which is exactly what "way off" looks like. `[measured 2026-09-20, n=1]`

This is the predicted consequence of §9ar's pane change on 2026-09-18 (viewpoint from ~0.9 m below
the head to exactly at the eye), and the first direct evidence for it rather than inference.

## 2. ⭐⭐⭐ The zeroing was also a major cause of the STREAK

Tefa: *"ZERO-A-OFF.bat does not introduce the lines either!"*

§9ax measured what each term contributes to the crop's resting place:

| | contribution to `ndc_y` | resting `v` |
| --- | --- | --- |
| zero **+14.4° up** (shipped) | +0.3003 | **0.244** |
| zero **0** (`ZERO-A-OFF`) | 0 | **0.394** |
| zero **≈ −4° down** (what today's measurement wants) | −0.082 | **≈0.435** |

`v = 0.5` is the middle; `v = 0` is the top edge. **The shipped zero was shoving the crop half of
the remaining way to the top edge**, which is why so little head movement pushed it off — and why
turning the zeroing off stops the lines. `[verified-numerically 2026-09-20]`

⭐ **So the correct zero does not merely fix the aim: it moves the crop from 0.244 to about 0.435,
nearly centred, and buys back most of the headroom the streak was eating.** The two problems that
have been chased separately all week are **one problem**, and it is a stale calibration.

⚠️ **Not yet confirmed live** — the prediction is that a correctly re-zeroed scope will also streak
far less. That is a thing to check while zeroing, not to assume.

## 3. What this retires

- **§9aq's "the frame is too narrow"** was already disproved at the premise (§9av). This finishes it:
  the frame was never the problem, the crop's starting point was.
- **§9ax's proposed fix** (drop the eye-projection off-centre term) is not needed and was not
  supported live (§9ay). The zero term is three times larger and is the one that was wrong.
- **The "limitation" framing** may be partly premature. Tefa's call stands and the head-movement
  ceiling is real (§9ay) — but a good chunk of what was being written off as a limitation looks like
  it was a stale number. Re-judge the limitation after re-zeroing, not before.

## 4. The nudge handed back

From `ZERO-A-OFF`: **3 clicks RIGHT and 3 clicks DOWN** (≈6° each), then fire again and reassess.
The direction is certain; the size is an estimate off one screenshot and should be iterated, not
trusted.

Credit: **praydog** (REFramework), **gmankab** (the `pd-upscaler` fork).
