# 2026-09-16h — the worn half-turn explained: a left-pointing rifle X and a v-flipped glass; the frame built directly, with meaningful diagnostics (`/pd`, dev PC, Fable, NO LAUNCH)

**The game was not launched and nothing here has been run.**

## 1. The row

*Make the worn frame the code's baseline.* The picture Tefa called "this is the one" is `geomrot 180`,
`geomflip 0` on top of the map's own frame, and the map's `IMPROPER` flag fires on it, so its roll
read-out means nothing. The row asked for the frame to come out of the code directly, with the knobs
reading 0 and the flag meaningful again.

## 2. Why the worn frame is what it is (from the code and the 2026-09-13 log)

Two facts, each on record, add up to exactly the worn knobs:

1. **The rifle root's +X points to the player's LEFT** with +Z the bore and +Y up (`geomdbg`,
   2026-09-13d). The frame builder makes its glass-right axis follow the rifle's X, so the raw frame
   is a mirror of what the map treats as upright. The log said just that: raw = `IMPROPER`;
   `geomflip 1` = proper, roll ≈ 0 `[verified-live 2026-09-13, n=1 log]`.
2. **The in-world glass shows the composite upside down**: the lens material samples v reversed
   (the 2026-08-28 `glass_flip_v` finding; that knob compensates and is off). The map never
   modelled it.

A u-flip plus a v-flip is a half-turn. So the frame the map calls right (flip 1) plus the flip the
glass adds (v) is `rot 180`, which is what the wearer picked. The model and the eyes agreed all
along; the model was missing the glass.

`tools/frame_v2_test.cpp` reproduces the log's readings on the shipped code with a left-pointing
rifle X: raw `IMPROPER`; flip 1 proper, roll 0; rot 180 `IMPROPER` `[verified-numerically 2026-09-16]`.

## 3. What was built (compile-verified, tested numerically, deployed on the dev PC, NOT run)

- **`sg_rifle_frame_rh`**: the worn frame built directly. Glass-right = bore × up, glass-up = the
  rifle's up, negated when the glass path v-flips (`glass_flip_v` off). It does not look at which
  way the rifle's X points.
- **`sg_rebase`**: re-measures roll, `IMPROPER`, stretch and skew against that frame as the identity.
  With the v flip off it reproduces the old measure exactly.
- **`framev 1|2`** (harness; settings `frame_v`; live). 1 = as worn today (boot). 2 = the new frame,
  with `geomrot` / `geomflip` ignored, and the diagnostics rebased. **The picture must look identical
  on 1 and 2** — the test proves the two frames and the resulting maps are the same to 1e-6 — and the
  `geom:` line should then read proper with roll ≈ 0 on the worn picture.
- 25/25 in the new suite; all nine suites pass; plugin 0 errors, 0 warnings; Lua compiles; stubbed
  bring-up 29/29. Dev-PC install re-stamped 14/14.

## 4. What is NOT established

- That the live raw frame is the one the test constructs. The test takes "X points left" from the
  2026-09-13 note; if the live axes differ, `framev 2` will show a mirrored or half-turned picture,
  and that is the tell.
- Whether `glass_flip_v` is on in the home PC's saved settings. If it is, the v2 frame will come out
  upside down there; `glass_flip_v=0` in the settings file fixes it.
- This closes a diagnostics row. It does not change the picture by design.

**The diagnostic that would show the derivation is wrong:** `framev 2` and the picture is not
identical to `framev 1`. A u-mirror means the rifle's X does not point left after all; an upside-down
picture means the glass path does not v-flip. Either way, `framev 1` puts the worn picture back.

## 5. NEXT (headset, home PC, ten seconds)

1. `bringup`, look. `framev 2`, look: **identical?** The `geom:` line: proper, roll ≈ 0?
2. If both: the next `/pd` makes 2 the boot, drops the 180 from `bringup` and the settings, and the
   `IMPROPER` flag is trustworthy from then on.
