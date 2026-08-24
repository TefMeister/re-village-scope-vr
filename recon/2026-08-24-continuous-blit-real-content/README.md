# 2026-08-24 — continuous scope-image blit into the proven engine target

Follow-up to the same day's RT-backing breakthrough (`2026-08-24-candidate2-d3d12-hook-WIN`).
That session proved the mechanism with a static checkerboard test pattern; this session builds
the real thing: the finished per-frame scope image, written continuously instead of once.

## What changed

`g.rt` (480x360) already holds the FINISHED scope image every frame — `ps_main` bakes the
magnified crop, vignette, and reticle into it, all in the existing M2a pipeline. It was
previously only ever consumed by the flat swapchain overlay (`ps_comp`, alpha-blended circle
onto the backbuffer). This session adds a second consumer: `blit_rt_into_target()`, a new
function that draws `g.rt`'s content into the D3D12-hook-captured engine resource
(`hook::last_committed`, the same one the WIN session proved gets real GPU backing) every
frame, via a real rasterized draw rather than `CopyTextureRegion` — the two textures are
different sizes (480x360 vs the engine target's own dimensions, ~728x1280 in the WIN
session's log), and a straight byte copy can't scale; a full-screen triangle through a
viewport sized to the destination does, for free.

New pieces:
- `ps_blit` — a third HLSL pixel shader, plain 1:1 sample, no crop math, no vignette/reticle
  (g.rt already has those baked in — reapplying them here would double them up).
- `pso_blit` — built lazily on first use, once the target resource's real `DXGI_FORMAT` is
  known (a D3D12 PSO bakes its target format in; the target doesn't exist yet at `init_gpu()`
  time), then cached and only rebuilt if the format ever changes.
- `hook::ensure_created()` — auto-creates the target resource + holder via the same
  `create_resource`/`create_holder` call the WIN session's F6 used manually, so this doesn't
  need a keypress every session. Idempotent, safe to call every frame.
- `g.target_rtv_heap` — a dedicated one-slot RTV heap for whatever resource
  `hook::last_committed` currently points at (kept separate from the existing `g.rtv_heap`,
  which is already spoken for: slot 0 = `g.rt`, slot 1 = the current backbuffer).

## The VR-guard restructure (the less obvious part)

`composite_allowed()` (false in VR — FOV heuristic) used to gate the ENTIRE `on_present()`
body, including `g.rt`'s own drawing — correct back when the only consumer was the flat
overlay, since there was nothing else to feed. Left as-is, it would have silently starved
the new material-bound blit in VR too, even though that output has nothing to do with the
swapchain-mirror problem the guard exists for (an in-world mesh material gets rendered
normally, per-eye, by the game's own pipeline — no accumulation risk).

Restructured: the guard now only wraps the flat-overlay draw at the bottom of the function
(renamed `draw_flat_overlay` for clarity). `g.rt`'s drawing and the new blit run in both flat
and VR. Backbuffer resource-state bookkeeping (`bb`'s barrier chain) was split into two
branches to stay balanced either way — see the diff for the exact states.

**Caveat surfaced by this restructure, not solved by it**: `g.rt`'s own CONTENT is still
sourced from a backbuffer capture (`g.capture`, step 1). In VR that's the same
mirror-window content the original M3 recon already flagged as unreliable (accumulation risk
was specifically about *drawing back onto* the mirror, which no longer happens — but the
mirror is still a low-res/possibly-frozen mono capture, not a real per-eye scene). So: the
DISPLAY mechanism (material-bound texture on an in-world mesh) is now VR-correct. The
CONTENT SOURCE feeding it is not yet — that's a distinct, deeper problem for a future
session (a real per-eye scene tap, not a mirror-window capture).

## Verification

- **Build**: clean, VS2022 Release via the CMake config in `plugin/CMakeLists.txt`, zero
  errors or warnings, first try.
- **Load test**: deployed to the dev PC's RE Village install (previous build backed up as
  `re_scope_vr.dll.pre-blit-backup`). Launched, confirmed via `re2_framework_log.txt`:
  `[hook] D3D12 device hooks installed: OK`, `M2a GPU init OK (bb 1920x1080 fmt=28, RT
  480x360...)`, stable through repeated `world_tick` logs at the title screen, no crash, no
  error lines. Killed cleanly after ~25s.
- **NOT verified**: the actual `ensure_created()`/`blit_rt_into_target()` code path itself,
  since both only run once `g_lens_target.valid` is true (a scoped weapon equipped —
  unchanged gate from the original design). This dev PC's fresh save hasn't reached real
  gameplay yet (same blocker the prior WIN session flagged: "blocked on this fresh dev-PC
  save reaching real gameplay" — pre-existing, not introduced here).

## Next step

Reach real gameplay with the F2 scoped rifle equipped (manual play, or find/build a
gameplay-access shortcut the way other projects in this account have — none exists yet for
this one), then press **F4** (unchanged, still the brute-force `setMaterialTexture` bind
proven in the WIN session) while looking at the glass. It should now show the LIVE scope
image — magnification, reticle, the works — instead of the static checkerboard. If that
works, the remaining engineering is: bind specifically to the glass's own material slots
(mats 2/3, slot 1, `Reticle_BaseAlphaMap` — per the M3 recon) instead of brute-forcing every
mesh, and separately tackle the per-eye content-source problem noted above for true VR
correctness.
