# 2026-09-27 evening (Opus, Tefa in the headset) — the golden VR glass: most of the way

## What it turned out to be

Two things stacked on the rifle camera's own picture, not on the glass and not in our grading:

1. **The clone's SoftBloom** lays a warm glow over everything outdoors at the evening light. Off → the mid-tones (sign,
   statue, fence, wood) match the world (Tefa: *"many things like the sign post and the statue seem to be the right
   colour"*) `[reported 2026-09-27]`.
2. **The clone's picture clips at 1.0**, and warm-lit snow/sky clip in red and green first → yellow-white. The clone
   3 EV darker than MainCamera (GT knob raised ~4x to 3.81 to match): *"it's getting better"*, then *"the world is
   getting there"*; the sky is still too bright and colours do not always match `[reported 2026-09-27]`.

Made automatic in VR (staging `cd3fd46`): bloom off + clone EV = MainCamera EV + 3, every 10 LockScenes.
Knob `exposure_gt=3.808506` saved in `re_scope_vr_settings.txt` (also `wb_amount=0.5` from the afternoon test).

## Ruled out today (each worn or measured)

| lever | result |
| --- | --- |
| our blue shift / gain / GT curve | not the cause; our output measured neutral (RT dump) |
| clone EV alone (with bloom on) | darker, still golden (the bloom glow survives any exposure) |
| PreTonemapRange | capped at 1 by the game |
| copying MainCamera's colour grade (`clonecc`) | no change (the clone's grade already matched via clonelook) |
| contrast/gamma/per-channel knobs (`re_scope_look.txt`) | ratios matched the world, still a golden veil |
| lens material: TransparentColor, Roughness, Translucency, AlphaValue (`re_scope_lensvars.txt`) | no change |
| the game's colour cube (`Area01_outside_evening.tex`, 32³ sRGB LUT) applied offline to the clone dumps | brighter, still golden |
| ToneMapping settings main vs clone | identical (TonemapRange 0.1, PTR 1, WR 0.9, WP 5.6/15) |

## A bug found and fixed on the way (staging `66bdda5`)

The PrepareOutput copy texture was created without ALLOW_RENDER_TARGET, so present.cpp's validation refused it and the
scope silently fell back to the BACKBUFFER crop. Every "finished picture" look before today showed that fallback: the main
view magnified in flat, the frozen desktop in VR `[inferred-static 2026-09-27]`. With the flag set, the copy in VR is the
MAIN camera's eye image (dumps 18:33/18:35 show the rifle in hand) — graded colours, but pointing wrong and flickering, so
the clone's own finished picture is not in that texture `[verified-live 2026-09-27, n=2]`. `clonepo 0` now puts the previous
source back instead of leaving the glass frozen.

## New test tools (staging)

`re_scope_look.txt` (gamma/lift/gain/r/g/b on the clone source, `on=0` = off), `re_scope_lensvars.txt` (any lens material
variable by name, held each tick; `census=1` lists all 25). Both default off.

## Next

The sky: white in the scope, dark slate in the world. Candidates: the GT knob a step lower, a stronger shoulder for the
clone, or the clone's own sky still clipping at EV+3 (probe outdoors with the scope on open sky).

## 🏆 19:06-19:15 — BEATEN

Tefa's clip (`D:\vid\re village scope vid for Claude.mp4`, 19:06, not committed) read frame by frame: in every ~9 frames ONE
frame showed the darker, correctly exposed picture (mountains, sky) and the rest the flat clipped grey. Cause: OURS —
`clonelook` (re8_scope_cam_clone.lua) copied MainCamera's `set_EV` and SoftBloom `set_Enabled` onto the clone every 10
LockScenes, undoing the VR look every cycle. So every "darker" test today mostly showed the reset picture
`[verified-live 2026-09-27, n=1 clip]`. Live fix `clonelook 0`; Tefa: *"i think it's the boss fight, that took us a month
and 5 days, i think it's finished.......... i can't really belive it"* `[reported 2026-09-27 19:15]`.

Shipped (staging, installed for the next start): clonelook skips the setters another script owns (`st.clone_look_skip`);
the VR look (bloom off + clone EV = main EV + 3) runs every LockScene.

**The whole fix, in one line:** in VR the rifle camera's own bloom glow and its highlight clip made the gold; switch its
bloom off, run it 3 EV darker than the main view (our GT knob ~4x up to match), and stop our own copy loop from undoing it.

Built but NOT needed (kept, unrun): the Scene-layer `HDRTarget` grab (`scene=`/`ts=` in re_scope_po.txt, staging `512348e`).
