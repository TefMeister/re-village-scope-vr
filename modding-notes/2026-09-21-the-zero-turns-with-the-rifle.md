# 2026-09-21 — the zero turns with the rifle, and every shot now says by how much

`/pd`, home PC (RTX), no launch. **The game was not launched, and nothing here has been run.**

## Where this starts

Dossier §9bz: ten two-handed shots all left along the scope's own axis (game ray vs scope
axis 0.00°, n=10), and Tefa still saw every hit **left of the crosshair, at the same spot
each time**. So the fault sits between the scope's axis and the crosshair. The leading
guess was that the zero (−14.9 up / −11.8 right, about a 19° correction) is applied in a
frame that rolls with the rifle.

## What the code actually does `[inferred-static 2026-09-21]`

`crop_follow.cpp` builds the zero's **up** from the rifle root's own Y axis and its
**right** from the root's own X axis. It then flips their signs so that up faces world-up
and right faces the eye's right. **A sign flip removes nothing of the roll**, so the whole
correction turns with the rifle whenever the rifle rolls about its bore.

## Proven on the shipped function `[verified-numerically 2026-09-21, 59/59]`

`plugin/tools/shot_frame_test.cpp` calls the shipped `sg_zero_bore()` through the new
`shot_frame_math.h`, which rebuilds the zero's axes with the same flips crop_follow uses:

- Level rifle: the wearer sees exactly the stored zero (−14.90 / −11.80).
- A roll of R turns the correction, as the wearer sees it, **by R, in the same direction**,
  within 1° over ±85° (the 1° is tan-per-axis composition, not a second effect; its size
  stays 18.6–19.3°).
- **A −22° roll from level (the two-handed median in §9bz) moves the crosshair 7.1°: 6.4°
  right and 3.1° down.** The crosshair moving right puts the hit to its **left** — the
  direction Tefa reported.
- Aiming the whole rig elsewhere with no roll changes nothing. Bore straight up is refused.

⚠️ **What this does NOT establish.** That the roll is what moves Tefa's hits. The one-handed
roll was never logged (the launch overwrote it), so the −22° is compared with *level*, not
with the roll the zero was set at. The direction agreeing is suggestive, `n=1` report.
**Status: `[hypothesis]`, now with its mechanism proven present in the code.**

## What was built — `[compile-verified 2026-09-21]`, installed on RTX, NOT RUN

1. **Every `STRAIGHTENED` shot line now ends with the roll and the zero as the wearer sees
   it**, for example:
   `roll -22.0 | zero -14.9/-11.8, as seen -18.0 up -5.4 right (points -163 deg)`
   plus `UP-FLIPPED` / `RIGHT-FLIPPED` when crop_follow's sign flips fired. Roll is against
   **world up** (positive = the rifle's top turned to the wearer's right), not the old
   baseline-relative `g_roll_meas`, whose baseline is taken at an unknown moment.
2. **The plugin keeps its own log.** Every `LOGI`/`LOGE` line also goes to
   `reframework/data/re_scope_vr_session.log`, appended, a banner per launch, rotated to
   `.old` past 8 MB only at the start of a launch. A launch no longer destroys the evidence.
   Only the plugin's own lines are in it, not REFramework's or the game's.

Installed DLL hash `b86edec6…`; the previous one kept as
`re_scope_vr.dll.pre-shot-roll-2026-09-21`. Source: `staging/re-village-scope-vr/plugin/`.

## The one test that decides it (needs Tefa's hands: `VR USER`)

Five shots one-handed, then five two-handed, at the reference-zero spot. Read the ends of
the shot lines in `re_scope_shots.log`:

| what the lines show | what it means |
| --- | --- |
| roll differs between the two groups, and the "as seen" difference matches the size and direction of the miss | **confirmed** — move the zero to a roll-free frame (the eye's, or world-up about the bore) |
| roll differs, "as seen" differs, but the miss does not follow it | the zero turns, but something else is bigger — look at the picture's own map next |
| roll is the same in both groups | the roll cannot be the cause — look elsewhere between the axis and the crosshair |
| a `FLIPPED` word appears on the missing shots only | the sign flip is the culprit, a jump of about 24° sideways |

Credit: **praydog** (REFramework, RE8VR). The shots and the screenshot behind §9bz by Tefa.
