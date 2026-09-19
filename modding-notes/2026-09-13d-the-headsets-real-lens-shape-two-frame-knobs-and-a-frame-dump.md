# 2026-09-13d — The headset's real lens shape goes into the map; two frame knobs; the frame dump that settles the half-turn (`/pd`, home PC `RTX`, NO LAUNCH, Fable)

**The game was not launched and nothing here has been run.** Source: `staging/re-village-scope-vr/`. Dossier §9y.
Follows the first wear (2026-09-13c): the exact map with steering off was "the closest to what it should be
like", but the picture sat a half-turn out and its centre at the render's edge, and `geomhm 1` made it worse.

## What the log of the wear says, read again at the desk

- **The picture was probably not rotated — it was MIRRORED against the flat baseline.** The map's own roll
  read-out swung between 174–180°, −100°, −113°, −61°, 11°, 135° while the rifle was level. A rotation is
  steady; an *undefined* angle jumps. The polar angle is undefined exactly when the 2×2 map is improper —
  a mirror of the baseline, det < 0 — and `atan2(≈0, ≈0)` then prints whatever the noise says. So the map
  the plugin built had glass-right → screen-right (fine) and glass-up → screen-UP, where the flat-verified
  state has glass-up → screen-down (the horizontal pane's flip). One axis wrong = "upside down" — exactly
  Tefa's word. `[inferred-static 2026-09-13]` — from the log; the new build prints IMPROPER explicitly
- **Which input is reversed is not decidable from the log** — it never printed the frames. Candidates: the
  rifle root's `get_AxisY` pointing down while the quaternion's Y points up (never compared); the lens
  material flipping u as well as v (never asked; `glass_flip_v` exists because it flips v); the camera
  transform in VR. Any of these is one look away now (below).
- **The centre at u ≈ 1.02 (14:25) was the rifle pointed away; while aiming (14:27) it was (0.60, 0.50)** —
  the same as the crop-follow far point. So the edge/trail is not a constant offset. But the map assumed a
  symmetric eye projection with aspect = pixels, and the headset's own matrix (vrlens probe, 2026-09-12)
  is asymmetric: `m00 0.985 m11 1.170 m20 0.174 m21 −0.211` → ~91° × 81°, tan-aspect 1.19 against a pixel
  aspect of 0.93, offset a fifth of a half-width. The symmetric guess is ~25 % too narrow horizontally and
  misplaced by the offset. `[verified-numerically 2026-09-13, from the probe's numbers]`

## Built

- **The camera's real projection matrix in the map.** `get_ProjectionMatrix` read every world tick (a
  `via.mat4`, 64 bytes by value), normalised to row-vector form (column-vector input detected by where the
  ±1 sits and transposed), used by `sg_compute_P`; the fov path stays as the fallback and the A/B
  (`geomusep 0`). Logged in full the first time it reads and whenever its diagonal changes, with the
  tan half-extents it implies next to what `get_FOV` says.
- **Two frame knobs:** `geomrot <deg>` (turn the sampled picture on the glass; try 180) and `geomflip 0|1`
  (mirror it left-right). Applied to the rifle frame before the map, so head/rifle motion stays exact.
- **`IMPROPER` flag** on the `geom:` line when the map mirrors the flat baseline, so the roll number is never
  read as a roll again.
- **`geomdbg:` every ~5 s:** the rifle root's accessor axes beside its quaternion axes, the camera's
  right/up/forward, and the map's frame `rx ry d n` — all world-space. One line answers which input is
  reversed.
- **`bringup` staggered:** drive 3 s after the spawn, shrink + silence 5 s after that, then
  `fn goat_pend_dump`. Both floating goats tonight had drive and shrink in the spawn frame; the rig that rode
  last night had +4 s and +23 s `[hypothesis]`. Test 26/26.

## Verified

`geom_test` **116/116** (new: symmetric matrix ≡ fov path to 1e-5; the headset's asymmetric matrix against a
by-hand projection of reflected points to 2e-3; transposed input restored; `geomrot 180` ≡ the half-turned
glass, `geomflip` ≡ the mirrored glass; a reversed rifle up is flagged improper, the normal case is not).
Older suites unchanged (176 / 40 / 20), bringup 26/26, `fxc` all four entry points OK, both Lua files parse,
four format strings counted (18/18, 39/39, 21/21, 36/36). Deployed and stamped 4/4 (backups
`*.pre-geom2-backup-2026-09-13`).

## The look back through the old attempts (Tefa's suggestion)

Read again with tonight's knowledge: 2026-08-24 (the raw mirror render on the glass: *"mirrored (upside
down) and clipped at the mirror plane"*), 2026-08-28 (`glass_flip_v`: the lens material flips v, the PiP
does not), 2026-08-30 ("Mirror H-flip defaults ON" with the pitch 180 / yaw 90 pose), 2026-09-01/02 (both
flips = the proven state), 2026-09-05c (steering off, on-axis, in-world glass, VR: right way up). None of
them ever asked whether the glass material flips **u** — only v was ever fixed — and "upside down" was the
only word ever written, which fits a half-turn and a vertical mirror equally. That is the gap the frame
dump closes.

## Next wear, in order

`bringup` → look → `geomflip 1` → look → (if a half-turn) `geomrot 180` → look. Read `geomdbg` and
`projection:` afterwards; the goat should now ride.
