# The missing shoulder and the hand-fitted `exposure=0.134` are the same defect

**From:** `/gr` (2026-09-03, estate sweep)
**Topic:** [`external-research/topics/2026-09-03-the-games-own-tonemap-curve-is-already-dumped-and-it-has-a-linear-section.md`](../../external-research/topics/2026-09-03-the-games-own-tonemap-curve-is-already-dumped-and-it-has-a-linear-section.md)

## The board row

> **[PD]** give the compositor a highlight SHOULDER […] A Hable/ACES-style curve keeps the midtone
> calibration and rolls the highlights off.

The diagnosis is right. **Don't reach for Hable or ACES** — the game's own curve is fully
parameterised, and this project's own 2026-08-30 recon already dumped it with live values.

## What is already on disk

`dev-archive/recon/2026-08-30-grading-ev-recon/gr-recon-log-extract.txt`, `via.render.ToneMapping`:

`UseTripleSectionTonemap = true` · `LinearSectionBegin = 0.22` · `LinearSectionLength = 0.40` ·
`SDRToe = 1.0` · `HDRToe = 1.33` · `MinWhitePoint = 5.6` · `MaxWhitePoint = 15.0` ·
`WhiteRange = 0.9` — `[measured 2026-08-30]`, and **every one has a setter as well as a getter**
(two were written and read back in the same session).

## ⭐ The point worth acting on

**`1 - exp(-x·e)` has no linear section.** It bends from the first sample onward. The game's curve is
**dead straight from 0.22 to 0.62**. So `exposure=0.134` was fitted to push a permanently-bending
curve through a band the game keeps linear — and pushing it down is exactly what drives everything
above ~25 raw into the flat top.

That makes the clipped highlights and the hand-fitted constant **one defect, not two**. A
three-section curve fixes both simultaneously, and it preserves the midtone calibration *by
construction* rather than by tuning: the linear section **is** the midtones, so a straight segment
reproduces them exactly, while the shoulder is a separate parameter that never touches the middle.
A Hable/ACES swap would have reintroduced that trade-off — both are single continuous curves whose
midtone response moves when you change the shoulder.

Expect `exposure=0.134` to become unnecessary rather than to carry forward.

## Route, all still `[PD]`

1. Write `ps_main` against the three sections explicitly (toe < 0.22, linear 0.22→0.62, shoulder
   above), using the numbers above as constants.
2. **Then read them live per frame, exactly as the compositor already reads `get_EV`.** This is not
   polish: the log shows the game moving `MinWhitePoint` 5.6 → 8.0 and `WhiteRange` 0.9 → 0.8 and
   back inside one session. A hardcoded shoulder drifts out of agreement with the game view precisely
   when the grading changes — the hardest failure mode to spot in a screenshot.
3. **Decide `SDRToe` vs `HDRToe` (1.0 vs 1.33) deliberately**, and log which the game is using rather
   than assuming SDR.

Verification is the shot the board already names — sunlit snow, `Screenshot 2026-09-02 230446.png`,
where the game view keeps texture and the scope does not.

## Identification, and its honest limit

The vocabulary (triple section; linear section as *begin + length*; toe; shoulder to a white point)
matches the **GT tone curve** from Hajime Uchimura's CEDEC 2017 "HDR Theory and Practice". Tagged
`[hypothesis]`: the structure corresponds term for term, but I have not verified RE Engine implements
that exact algebra, and `SDRToe`/`HDRToe`/`WhiteRange` do not map one-to-one onto the published
parameter list. **The plan above does not depend on the identification being right** — it depends
only on the shape, which is measured.

## Nothing public exists on this class

No public documentation of RE Engine's `via.render.ToneMapping` internals, from Capcom or from the
REFramework/EMV community. Our own dump is the better source, which is the usual situation on this
project. Not worth another research session.
