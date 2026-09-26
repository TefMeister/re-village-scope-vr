# 2026-09-26 night (/lm, flat, Opus) — the rifle camera's outdoor blow-out: four levers, none fixes it

Tefa asked whether this is the same brightness problem as the black sky / golden veil (2026-08-29..09-03). Same family,
different route. `[verified-live 2026-09-26, n=1 each]` unless noted.

| lever | result |
| --- | --- |
| `clonegrep ToneMapping ev` | `get_EV` main 3.0 = clone 3.0, `get_SnappedRealEV` equal; the light meter already matches |
| `clonegrep ... expos` | `getAutoExposure` main 0, clone 2 (the only exposure difference) |
| `clonediff SoftBloom` | Algorithm main 2 / clone 0, StandardV3 true/false; setting them to main's: no visible change |
| `clonecomp ToneMapping 0`, `clonecomp LDRPostProcess 0`, `clonecomp SoftBloom 0` | no visible change on the glass |
| `setAutoExposure 0` on the clone | everything a little darker, outdoors still near-white |
| `clonehdr 1` (authored float .rtex, fmt 26) | latched as raw HDR, but **max = 1.00**: clamped like the 8-bit one; glass very dark at the mirror-era exposure |
| `clonehdr 2` (8-bit target + the mirror-era upgrade to the next fmt-26 allocation; must be set before the first clone of the process) | upgraded to a fmt-26 1920x1088 buffer, max 1.00, glass flat dark grey — not the clone's picture, or not usable |

The 8-bit source is 255 white outdoors (clipped). Switching the clone's ToneMapping off changes nothing, so the tone curve is
not applied on this output at all `[hypothesis]`: the RenderOutput target receives the scene before the game's grading,
clamped to 1.

**The lead for next time (static first):** praydog's CameraDuplicator never uses a render target; VR.cpp copies the clone's
picture out of the clone layer's **PrepareOutput** output state in `on_prepare_output_layer_draw` — the finished, graded
picture (the same one the main view's PrepareOutput produces). Our `set_RenderTarget` route evidently gets an earlier,
ungraded output. Reading the clone layer's PrepareOutput target instead is the likely fix `[hypothesis]`.

Installed after this run: plugin 334b388e (clonehdr 2 support; inert unless asked), `re8_scope_cam_fix.lua` with `clonegrep`
and `clonehdr`; the authored float .rtex was taken back out of `natives/` (kept in `staging/re-village-scope-vr/natives/`).
