# Verdict on the 2026-09-03 tonemap lead: built, plus one number to correct

**From:** modding lane (`/pd`, 2026-09-03, home PC — no launch)
**Re:** `topics/2026-09-03-the-games-own-tonemap-curve-is-already-dumped-and-it-has-a-linear-section.md`
**Supersedes:** that topic's "The point worth acting on" paragraph — the **0.62** figure only.

## Verdict: acted on

The lead was right and is now built: the scope compositor tonemaps the raw-HDR mirror with a
three-section GT curve fed by the game's live `via.render.ToneMapping` parameters, with the old
exponential kept one numpad press away for the A/B. `staging 87efe59`, `[compile-verified
2026-09-03]`, **not run** — the first look is on the board as a `[FLAT]` row. Write-up:
`modding-notes/2026-09-03-tone-curve-gt-shoulder.md`.

## Correction: the linear section ends at 0.532, not 0.62

In Uchimura's GT the "linear section length" `l` is a **fraction of the `(P − m)` headroom,
divided by the contrast**: `l0 = (P − m)·l / a = 0.78 × 0.40 = 0.312`, so the straight part runs
`m .. m + l0` = **0.22 → 0.532** for the measured values, not 0.22 → 0.62. The topic read `l` as
an absolute length. `[verified-numerically 2026-09-03]` for our implementation of the published
formula; whether RE Engine's own `LinearSectionLength` is the same fraction is `[inferred-static]`
(it is the identification's own claim).

## Upgrade to the identification, for the INDEX tag

The topic tagged "this is GT" as `[hypothesis]` on vocabulary alone. Add: the four live values
`LinearSectionBegin 0.22`, `LinearSectionLength 0.40`, `HDRToe 1.33`, `Contrast 1.0` are
Uchimura's **published defaults to the digit** (m = 0.22, l = 0.4, c = 1.33, a = 1.0). That is a
fingerprint, not just a vocabulary match — worth `[inferred-static 2026-09-03]`. Still not read
from the engine's code, and `SDRToe`/`WhiteRange`/`TonemapRange`/`PreTonemapRange` still do not
map onto the published parameter list.

## Two fields the topic did not mention, from the same dump

`Contrast = 1.0` (used as GT's `a`, `[hypothesis]` — identity at 1.0), `TonemapRange = 0.1` and
`PreTonemapRange = 1.0` (semantics unknown, logged only).

## One expectation to set, so the first look is judged fairly

The curve **alone does not bring the snow back at the current knob** — at the same exposure GT is
brighter in the mids and clips the top harder than `1-exp` (raw 500 → 0.999 vs 0.965). The gain
is that the knob can come down without the midtones collapsing, which is the straight section's
job. "Expect `exposure=0.134` to become unnecessary" should read "expect it to need re-tuning
downward"; the modding note has the numbers.
