# 2026-09-21 16:40–16:47 — eighth zero: up −10.7 / right −9.5, and distance-follow reaches the glass

Home PC (RTX), Tefa in the headset. First run of the dossier §9ce build.

## What the log says

- **Distance-follow now reaches the picture.** All seven shot lines read
  `picture turned 1.60–1.62 deg for it` at `aim 13.0 m`. Before §9ce that figure could only have
  been 0.00. `[verified-live 2026-09-21, n=7 shots, one distance]`
- **The zero moved from −11.9 / −7.1 to −10.7 / −9.5**, by way of −9.9 / −11.1, −10.3 / −10.7,
  −10.3 / −9.9 and −10.7 / −9.9 (`zero-path-and-latch.txt`). Sideways change 2.4°, against the
  ~2° predicted in §9ce. `[verified-live 2026-09-21, n=1 wearer]`
- Tefa: *"ok i zeroed the scope, please bake the numbers in."* `[reported 2026-09-21]`

## Near/far, added 16:56 the same launch

**NEAR/FAR, 16:53–16:56, same launch, zero untouched at −10.7 / −9.5:** shot #8 at 5.3 m (picture turned 3.59°), #9 at 13.0 m (1.63°), #10 at 5.0 m (3.68°). Tefa: *"they really do seem to all go in the right place!"* `[reported 2026-09-21]` · turn figures `[verified-live 2026-09-21, n=3 shots, 2 distances]`.

The picture turns more for the near wall than the far one, as §9ce says it should, and the wearer
saw all three land. Three shots on one day is a good sign, not a settled result: confirm on a
second day before distance-follow becomes the shipped default.

## What it does NOT say

- **The 1920×1080 scope picture was not exercised.** The mirror source latched at 2560×1448 in
  this launch, so the tightened 1920 latch window is still `[compile-verified]` only.

## Where the zero was written

`re8_scope_harness.lua` (staging and the game folder), `re_scope_vr_settings.txt` (game folder),
`ZERO-B-SHIPPED.bat` and `READ-ME-ZEROING.txt` (`mod/helpers/` and the game folder).
