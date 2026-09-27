# 2026-09-27 afternoon (Opus, no game running) — the golden VR glass outdoors: what the code says

Tefa's report (13:21, in the headset): outdoors the picture INSIDE the scope is bright, washed out and golden; the rest of
the world looks right `[reported 2026-09-27]`. Fable is not available until Wednesday, so this is a static read with Opus.

## What the VR picture goes through `[inferred-static]`

In VR the rifle camera renders into the authored float target, so `mirror_is_hdr` is true (`d3d12_hooks.cpp:357`) and
`present.cpp` takes the raw-HDR branch:

1. `exposure = exposure_gt (1.95 saved) * 0.4 * 2^-EV`
2. white balance `wb_amount (1.0) * clamp((EV - 2.2) / 0.8)` — a BLUE shift (R x0.82, G x0.96, B x1.14)
3. sky fill: off (`atmo_on=0`)
4. the GT curve, per channel

None of these ADDS gold. The blue shift works against it.

## Two findings

- **The source in VR is NOT clamped at 1.0.** With EV 3 the gain is 1.95 x 0.4 x 2^-3 = 0.0975; a source capped at 1.0 would
  come out near black, and Tefa saw *"the correct picture with correct colours"* on 09-26. So the flat finding "max = 1.00"
  (9da, recon `2026-09-26o`) does not carry over to VR, and the `clonetm ev` lever (staging `d2fb794`, built 13:48 and never
  run) is aimed at a clamp the VR picture probably does not have `[inferred-static]`.
- **The clone is made WITHOUT `app.ColorCorrectController`** (09-27 13:19 log, `clonemake: 22 skipped`), and the flat
  tests showed its target is taken before the game's LDR stage (`clonecomp LDRPostProcess 0` changed nothing). So the
  rifle camera never gets the game's outdoor colour grade: Village's cold, desaturated snow look is added after the point
  we copy from. Raw sunlit scene through a per-channel curve = warm and washed out: the August veil's cause, second road
  `[hypothesis]`.
- Also: every `EV=` in the 09-27 log reads 3.00 (the lines are logged at zone changes, so the glide to 2.0 indoors may not
  show). If EV really sits at 3 in VR, our exposure never follows the game's eye adaptation `[hypothesis]`.

## The headset test that separates them (no build; every key already works in VR)

Outdoors in sunlight, scope raised, the golden look showing:

1. **Numpad +** once: the HDR probe logs the source's real brightness (max > 1 confirms "not clamped").
2. **Numpad 2**, three or four presses: darker. Golden goes away => too bright only (fix: steeper outdoor exposure).
   Still golden, just darker => missing colour grade.
3. **Numpad 0**, up to three presses: the blue shift steps 1.5, 2.0, then 0 (off). Which one looks right?
4. Walk indoors and back out with the scope up: every key press logs the live `EV=`, which answers the EV question.

Each press saves to `re_scope_vr_settings.txt`; the values to restore are `exposure_gt=1.949955` and `wb_amount=1.000000`.

Model for the test: Opus (a guided test, reading the log against these predictions).
