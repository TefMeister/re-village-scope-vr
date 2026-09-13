# 2026-09-13b — The exact map: one formula from the glass to the mirror picture, instead of a roll knob (`/pd`, home PC `RTX`, NO LAUNCH, Fable)

**The game was not launched and nothing here has been run in the game.** Source: `staging/re-village-scope-vr/`
(`plugin/src/scope_geom_math.h`, `plugin/tools/geom_test.cpp`, `Plugin.cpp`, both Lua files). Dossier §9w.

The board row said: *redo the rotation maths from Tefa's description, not by tuning `mrollk`*. This is that.
Tefa's descriptions, in order: the picture rotates with head AND rifle; it is sideways; it stretches and warps
while it turns; head left/right is inverted; up/down snaps; the good picture is near where the rig was built.
Every one of those except the last has a cause below, and the last is step 3's walk test.

## What the mirror render actually is (the piece nobody had written down)

A planar mirror draws the scene from the eye reflected across its plane, with the eye's own projection, so the
mirror surface can be textured by the eye's screen coordinates. So the render target is **the eye's view of
the reflected world**: a world point X appears at the eye's pixel of reflect(X). Two things follow:

1. **Orientation at any pixel = the eye's screen orientation + the perspective skew of that pixel.** The old
   cancel (v3) measured "reflected camera up about the bore, from rifle up" — right only when the bore is on
   the gaze. `geom_test` case 6 puts the two side by side: with the gaze ON the lens they agree to the degree
   (opposite sign convention, which is why `mrollk` wanted −1); with the gaze 20–40° off the lens they differ
   by 9–18° and there is 5–23 % stretch and up to 12° skew that no rotation can remove — the warp.
2. **The render is stored mirrored left-right.** A horizontal mirror alone only turns the world upside down (a
   lake does not swap left and right), yet the verified flat state needs `flip_h` AND `flip_v`. So the engine
   stores the render mirrored in u, and **every horizontal position read from it is 1 − u — the crop centre
   included.** The crop-follow candidates never mirrored it. That is Tefa's *"moving my head is inverted left
   and right"*: the crop moved the wrong way as the head turned. `[inferred-static 2026-09-13]`, knob `crophm`
   / `geomhm` so one wear can disprove it.

## Four faults found by reading, not by wearing

| # | Fault | Where | Effect Tefa described |
| --- | --- | --- | --- |
| 1 | The plugin's per-tick recompute of the steered plane used the **muzzle** as the anchor; the Lua uses the **lens** (Body joint + mount). From an eye 15–25 cm behind the lens the two rays are tens of degrees apart. | `crop_follow_update`, `jpos` passed as the anchor | the 12–53° `n-vs-lua` in every log line; a cancel computed for a plane the mirror did not have — "−1 over-corrects, −0.5 under" |
| 2 | The crop centre's u was never mirrored (above). | `cf_crop_centre` users | head left/right inverted; picture not showing where the bore points |
| 3 | The bore axis was picked as "the muzzle-local axis most aligned with the **camera forward**". In the headset the bore is 5–42° off the gaze; past 45° a different axis wins. | world tick | `roll meas` jumping to 148–168° in the 2026-09-12 log |
| 4 | The shader rotates the sample in a 4:3 frame. The flat PiP IS 4:3, but the in-world glass shows the RT's UV square in some other shape — the 2026-09-12 headset frame's duplex reticle has its thick bars starting at 0.6 R on one arm and 0.82 R on the other, ratio 0.73 ≈ the 0.75 a **square** display predicts `[measured 2026-09-13, one frame, n=1]`. A rotation in the wrong frame is a shear. | `ps_main` | "stretching and warping while it rotates" |

## What was built

- **`scope_geom_math.h`** — `sg_compute`: K = R_camᵀ · Refl_n · [rx ry d]; H = the homography from glass tangent
  coordinates (α along rifle right, β along rifle up, from the bore) to render UV, including the u-mirror and
  the projection. Also `sg_lua_eye_normal` (the Lua's plane law, verbatim) and `sg_rifle_frame`. Diagnostics:
  the 2×2 linearisation at the centre, decomposed into rotation (the roll a rotate-only sampler would need),
  stretch, skew, scale.
- **`ps_main`**: `geomMode` path evaluates H per pixel (`suv = (H·(α,β,1)).xy / .z`). Roll, warp, off-axis
  magnification, the crop centre and both flips are all inside H; **there is no roll knob on this path.**
  `glassAspect` replaces the literal 4/3 in the mask and the legacy rotation. Root constants 20 → 32.
- **Plugin**: the recompute uses the lens anchor and the root's +Z (fault 1); legacy crop centres mirror u
  (fault 2, `crop_hm`); the muzzle axis is picked against the root's +Z (fault 3); H computed every tick from
  the plane the mirror really has; a `geom:` log line once a second beside the `crop-follow:` line — exact roll
  next to v3's, stretch, skew, the root-Z-vs-muzzle angle (3–4° expected), and **`eye moved`** (the camera
  position's change per tick: ~0.06 m alternating would mean the transform read is a different eye each tick —
  a known limit, not yet measured).
- **Knobs** (settings file + harness, live): `geom 0|1` (boot **1**), `glassaspect` (boot 1.333 = unchanged),
  `geomhm -1|1` (boot −1), `geomproj 0|1` (boot 0 = shared projection), `crophm 0|1` (boot **1** = corrected).
  The Lua publishes `flip_d` so the recompute cannot disagree with the plane it steers.

## Verified

- `geom_test` **103/103** `[verified-numerically 2026-09-13]`: H reproduces point-reflection + eye projection
  (the crop-follow functions the 2026-09-06 test pinned to the Lua) at every glass point, eyes all round the
  rifle, four planes, to 1.5e-4 UV; flat baked pane → identity with both flips reproduced by hmirror = −1;
  mirror law (normal +γ about the bore → picture 2γ, odd, monotone); whole rifle rolled ρ → the sampler would
  need ρ and glass-up follows the rolled up (the real-scope behaviour: the world stays put, the reticle rolls);
  pane pitched toward the eye → no roll; the Lua's steered plane for 12 eyes → glass centre = the anchor's
  pixel = crop-follow refl/shared with u → 1−u.
- Existing suites unchanged: mirror_roll 176/176, crop_follow 40/40, roll_math 20/20; bringup 23/23; steer
  61/61 + 71/71. `fxc` over the assembled shader: all four entry points OK. Both Lua files parse; the pane
  `string.format` 33/33 and the new `LOGI` 14/14 counted by script. Plugin builds with zero warnings.
- Deployed (backups `*.pre-geom-backup-2026-09-13`), stamped 4/4.

## Two boot defaults changed, deliberately

`geom=1` and `crop_hm=1` boot ON. The old picture is known wrong and the new one is untested; `geom 0` /
`crophm 0` put the old behaviour back within a quarter second, no relaunch. `glassaspect` boots unchanged
(1.333) because the photo evidence is one frame — **the wear judges it**: the duplex's thick bars should
start at the same distance from the centre on both arms; if not, `glassaspect 1.0`.

## Known limits, stated

- **Which eye rendered the render?** In VR the mirror renders per eye; the plugin and the Lua read one camera
  transform. 3 cm of eye offset moves the eye→lens ray by up to ~8°, the plane by ~4°, the picture by ~8° of
  roll. `eye moved` in the log is the first measurement of whether that is happening. `[hypothesis]`
- **Far field only.** The mirror's viewpoint is the reflected eye, not the scope: near objects have parallax a
  scope would not. ~1° at 50 m, nothing at the horizon.
- **The eye projection is assumed symmetric.** VR eye projections are not; the offsets would shift the
  centre by a few degrees. Reading `get_ProjectionMatrix` is the fix if the picture is consistently off-centre.
- **Nothing here is about the spawn-point anchor** — step 3.
