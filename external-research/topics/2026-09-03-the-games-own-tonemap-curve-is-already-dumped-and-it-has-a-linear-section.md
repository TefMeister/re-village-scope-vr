# The game's own tonemap curve is already dumped — and the reason the shoulder is missing is that `1-exp` has no linear section

**Date:** 2026-09-03 · **Status:** ✅ incorporated — built 2026-09-03 (`staging 87efe59`, compile-verified, not yet run); see "Outcome" at the end · **Answers:** the board's `[PD]` row *"give the compositor
a highlight SHOULDER"*

## The row this addresses

> **[PD]** give the compositor a highlight SHOULDER: `ps_main` tonemaps with a bare
> `1-exp(-x*exposure)`, so at the chosen `exposure=0.134` anything above ~25 raw lands ≥0.96 = flat
> white. Sunlit snow (raw 50–200+) loses all texture in the scope while the game view keeps it. A
> Hable/ACES-style curve keeps the midtone calibration and rolls the highlights off.

The diagnosis is right and the prescription is nearly right. **But there is no need to reach for
Hable or ACES — the game's own curve is fully parameterised, and its live parameters were already
captured on 2026-08-30.** Copying the game beats approximating it, and this project is already
copying the game's exposure, so this closes the same loop one step further.

## What our own recon already holds

`dev-archive/recon/2026-08-30-grading-ev-recon/gr-recon-log-extract.txt` dumps
`via.render.ToneMapping`'s full property set **with live values**:

| Property | Live value |
|---|---|
| `UseTripleSectionTonemap` | **`true`** |
| `LinearSectionBegin` | `0.22` |
| `LinearSectionLength` | `0.40` |
| `SDRToe` | `1.0` |
| `HDRToe` | `1.33` |
| `MinWhitePoint` | `5.6` |
| `MaxWhitePoint` | `15.0` |
| `WhiteRange` | `0.9` |

`[measured 2026-08-30]` — read off the live object, and two of them (`MinWhitePoint`, `WhiteRange`)
were subsequently written and read back in the same session, so the setters work too.

Every one of these has a `set_` as well as a `get_`, so this is a curve the scope can *read* rather
than guess at.

## ⭐ The insight the row is missing: the game's curve has a **linear** middle, and `1-exp` does not

This is the actual reason the current compositor both clips highlights *and* needed a calibration
constant in the first place.

`1 - exp(-x·e)` is curving **everywhere**. It has no straight portion at all: its slope falls
continuously from the first sample onward. So when `exposure=0.134` was fitted to make midtones look
right, it was fitting a permanently-bending curve through a region the game keeps **dead straight** —
`LinearSectionBegin = 0.22`, `LinearSectionLength = 0.40`, i.e. **linear from 0.22 to 0.62** in
normalised terms. That is exactly the midtone band the calibration cared about.

> ⚠️ **Corrected 2026-09-03 by the modding lane:** the linear section ends at **0.532**, not 0.62. In
> Uchimura's GT the length `l` is a fraction of the `(P − m)` headroom divided by the contrast:
> `l0 = (P − m)·l / a = 0.78 × 0.40 = 0.312`, so the straight part runs `0.22 → 0.532`. This file
> originally read `l` as an absolute length. `[verified-numerically 2026-09-03]` for our implementation
> of the published formula; whether RE Engine's own `LinearSectionLength` is the same fraction is
> `[inferred-static]`. The 0.62 figures below are left as written; read them as 0.532.

Two consequences follow, and they are the whole finding:

1. **The midtone calibration and the highlight clipping are the same defect**, not two. Both come
   from using a curve with the wrong *shape*. The exponential has to be pushed down (small `exposure`)
   to keep midtones from blowing out, and pushing it down is what drives everything above ~25 raw
   into the flat top.
2. **A triple-section curve fixes both at once, and it preserves the calibration by construction.**
   The linear section *is* the midtones — a straight segment reproduces them exactly rather than
   approximating them — and the shoulder is a separate parameter that handles raw 50–200 without
   touching the middle. There is no trade-off to tune between the two, which is what a Hable/ACES
   swap would have reintroduced.

So the right move is not "pick a filmic curve and re-calibrate", it is **"reproduce the three-section
curve the game already runs, with the numbers already in the log"**. The `exposure=0.134` constant
should then fall out rather than being carried forward — it was compensating for the missing shape.

## What that curve most likely is

The parameter vocabulary — a **triple-section** curve with a toe, an explicit linear section given as
**begin + length**, and a shoulder bounded by a white point — matches the **GT tone curve** presented
by **Hajime Uchimura** at CEDEC 2017 ("HDR Theory and Practice", the Gran Turismo Sport HDR work).
That curve is defined by exactly this shape: maximum brightness, contrast, linear section start,
linear section length, toe/black tightness and pedestal, with separate control of toe, linear region
and shoulder. `[hypothesis]`

**Tagged `[hypothesis]` deliberately.** The naming correspondence is strong and the structure matches
term for term, but I have not verified that RE Engine implements Uchimura's exact algebra rather than
its own curve with similar controls — and the RE Engine names (`SDRToe`/`HDRToe`, `MinWhitePoint`/
`MaxWhitePoint`/`WhiteRange`) do not map one-to-one onto the published parameter list. Treat the
identification as a **starting point for the shape**, not as a formula to transcribe.

**And the good news is that the plan does not depend on it being right.** Even if the algebra
differs, building any toe/linear/shoulder curve with `LinearSectionBegin=0.22`,
`LinearSectionLength=0.40` and a shoulder reaching the white point range 5.6–15 is far closer to the
game than a bare exponential, and it is closer for a reason that is verifiable in the picture: the
linear band is where the calibration lives.

## The route, cheapest first — all of it still `[PD]`

1. **Write the compositor's `ps_main` against the three sections explicitly** (toe below 0.22, linear
   0.22→0.62, shoulder above), taking the numbers from the table above as constants for now.
2. **Then make them live.** `via.render.ToneMapping` has getters for all eight, so the scope can read
   the game's current values each frame exactly as it already reads `get_EV`. That matters because
   `MinWhitePoint`/`WhiteRange` are demonstrably *changed at runtime* — the log shows the game moving
   `MinWhitePoint` 5.6 → 8.0 and `WhiteRange` 0.9 → 0.8 and back within one session. A hardcoded
   shoulder would drift out of agreement with the game view exactly when the grading changes, which
   is the failure mode hardest to diagnose from a screenshot.
3. **`HDRToe` vs `SDRToe` (1.33 vs 1.0) is a real fork** — the scope pane is composited into a view
   the headset presents; which of the two the game itself is using at the time decides which toe the
   scope should match. Worth reading both and logging which path is active before assuming SDR.

The verification is the one the board already names: the sunlit-snow shot (`Screenshot 2026-09-02
230436/230446.png`), where the game view keeps texture and the scope does not. If the scope keeps
texture in the same frame, the curve is right.

## What I did NOT find, stated honestly

No public documentation of RE Engine's `via.render.ToneMapping` internals — no write-up of what
`UseTripleSectionTonemap` computes, no parameter reference, nothing from Capcom. The identification
above is inference from naming and structure against a published curve, which is why it is
`[hypothesis]`. Nothing in the public REFramework/EMV ecosystem documents this class either; our own
2026-08-30 dump appears to be the better source, which is the usual situation on this project.

## Sources

- Our own `dev-archive/recon/2026-08-30-grading-ev-recon/gr-recon-log-extract.txt` — the property
  list and live values (the primary source here).
- [Hajime Uchimura, "HDR Theory and Practice" (CEDEC 2017)](https://www.slideshare.net/nikuque/hdr-theory-and-practicce-jp)
  — the GT tone curve, its three-section structure and its parameter set.
- [tizian/tonemapper](https://github.com/tizian/tonemapper) — an open catalogue of tone-mapping
  operators, useful for comparing curve shapes; nothing taken from it.

## Cross-project note

Not filed anywhere else. The mechanism is RE-Engine-specific, and the general lesson — *read the
engine's own grading parameters instead of approximating them* — is only actionable on engines that
expose them, which in this estate is RE Engine via REFramework. The sibling project
`visceral-re2-vr` runs on the same engine and the same `via.render.ToneMapping` class will be
present there, so if a scope-like or overlay-like surface ever needs grading in that project, this
table is where to start.

## Outcome — modding lane verdict, 2026-09-03 (`/pd`, home PC, no launch)

**Acted on, and built.** The scope compositor now tonemaps the raw-HDR mirror with a three-section
GT curve fed by the game's live `via.render.ToneMapping` parameters, with the old exponential kept
one numpad press away for the A/B. `staging 87efe59`, `[compile-verified 2026-09-03]`, **not run** —
the first look is on the board as a `[FLAT]` row. Write-up:
`modding-notes/2026-09-03-tone-curve-gt-shoulder.md`.

Three things the verdict adds to this topic:

1. **The linear section ends at 0.532, not 0.62** — see the correction banner above. The topic read
   `LinearSectionLength` as an absolute length; in GT it is a fraction of the headroom over the
   contrast.
2. **The GT identification is upgraded from `[hypothesis]` to `[inferred-static 2026-09-03]`.** The
   four live values `LinearSectionBegin 0.22`, `LinearSectionLength 0.40`, `HDRToe 1.33`,
   `Contrast 1.0` are Uchimura's **published defaults to the digit** (m = 0.22, l = 0.4, c = 1.33,
   a = 1.0) — a fingerprint, not a vocabulary match. Still not read from the engine's code, and
   `SDRToe` / `WhiteRange` / `TonemapRange` / `PreTonemapRange` still do not map onto the published
   parameter list.
3. **Two fields this topic did not list, from the same 2026-08-30 dump:** `Contrast = 1.0` (used as
   GT's `a`, `[hypothesis]` — identity at 1.0), `TonemapRange = 0.1` and `PreTonemapRange = 1.0`
   (semantics unknown, logged only).

**Expectation reset for the first look:** the curve alone does not bring the snow back at the current
knob. At the same exposure GT is brighter in the mids and clips the top *harder* than `1-exp`
(raw 500 → 0.999 vs 0.965). The gain is that the knob can come down without the midtones
collapsing, which is the straight section's job. So "expect `exposure=0.134` to become
unnecessary" should read "expect it to need re-tuning downward"; the modding note has the numbers.
