# NEXT RUN (/lm, flat, one launch): the rifle camera's FINISHED picture via PrepareOutput

Built and deployed 2026-09-26 night by `/pd` (Opus). **Not run.** Plugin `f68d2618` (po_source.cpp), `re8_scope_cam_fix.lua`
word `clonepo`, harness wiring. `[compile-verified 2026-09-26]`; script tests pass (cam_fix incl. clonepo safety, cam_clone,
knob_chain 52/52, autostart 36/36).

## Why
The RenderOutput target gets the scene before grading, clamped at 1.0 (dossier 9da). praydog's VR mod reads its second view's
picture from that view's **PrepareOutput** layer: output state → RTV 0 → texture (VR.cpp `on_prepare_output_layer_draw`,
`on_end_rendering`, pd-upscaler 76298bd9) `[inferred-static]`.

## The chain the plugin walks (po_source.cpp)
PrepareOutput **+0xF8** → TargetState `[verified-live: REFramework log "Found output state offset: f8", 4/4 launches today]`;
TargetState +0x10 rtvs, +0x20 num_rtv; rtvs[0] → RTV; RTV + (0x80..0xE0, every slot tried) → Texture; Texture +0x98 → container;
container +0x10 → ID3D12Resource `[inferred-static, TDB 69 branches of Renderer.hpp/.cpp]`. Accepted only if the resource's
vtable equals the currently latched source's. Every read is SEH-guarded.

## Steps
1. `RIFLE-CAMERA-ON.bat` (autostart `1 1920 clone`), then `python re8drive.py boot`.
2. After `autostart: DONE`: `python re8drive.py cmd "clonepo"`, wait 2 s.
3. Read: `clonepo: the clone's Scene layer ... child layer(s): ...`, then `po: FOUND ...` and `po #1: the glass now shows ...`.
4. Screenshot the glass indoors and at the doorway (`hold d 0.8`, `hold a 1.6` from the save spot); `num +` to dump.
5. Put the autostart back: `SCOPE-AUTO-ON.bat` (Tefa: build stays installed, switched off).

## What each outcome means
| log / glass | meaning | next |
| --- | --- | --- |
| FOUND, glass graded (outdoors grey fog, not white) | **fixed** | make `clonepo` part of `clonescope` / the autostart |
| FOUND, glass shows the MAIN view, or flickers | the engine reuses that texture later in the frame (why praydog copies DURING the layer draw) | copy at the right moment: hook the command list, or read it in LockScene of the next frame [design needed] |
| FOUND, glass black/garbage | right resource, wrong state/format handling | dump + HDR probe; check fmt in the FOUND line |
| `no slot ... led to an ID3D12Resource` | an offset in the chain is off for this build | the line prints TargetState and RTV addresses: widen the window or read the RTV type size |
| `TargetState ... layout not as expected` | +0x10/+0x20 wrong on TDB 69 | print the first 0x40 bytes of the TargetState |
| `no scene layer captured` / `no PrepareOutput child` | layer discovery, not the picture | list the clone layer's children (the line prints them) |
