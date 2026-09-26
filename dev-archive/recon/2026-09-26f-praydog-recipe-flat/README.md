# 2026-09-26 night (/lm, flat, Opus) — praydog's full clone recipe, flat: registered, still never drawn

One launch, Claude driving, staging `re8_scope_cam_clone.lua` (built at LockScene, parented to MainCamera, 21 of MainCamera's 42
components in its order, output id 3, priority -1, draw off->on). `[verified-live 2026-09-26, n=1]` unless noted.

| rung | result |
| --- | --- |
| `cloneorder` | MainCamera: 42 components, order logged (Camera 1, RenderOutput 2, LDRPostProcess 3, Fog 4 ...) |
| `clonemake` (id 3, no target) | built at LockScene, no takeover; **the whole SCREEN turned to junk** — the same cloudy blob + streak pattern the glass has shown all day, over-bright (mean 247,244,228). Output id 3 with no target sends the clone's (unwritten) output to the screen. Walking / a per-frame pose copy from MainCamera changed it by <1/255 |
| `clonemake rt` (our 2560 target) | screen normal; catcher latched our 2560 target; glass = the flat colour again |
| `clonehook` | installed, no change |
| `clonemake bare` (Camera + RenderOutput only) | screen pure white (255) — same takeover of the screen, nothing drawn |
| window resize 1936x1460 -> 1280x720 -> back, clone alive | no change |

**Reading:** even praydog's recipe step for step does not make the clone's layer draw in FLAT mode. The clone's output replacing
the screen proves the output id is honoured and the output path is live — the layer's own buffers simply never get written.
`ResizeFrame` is not an execution counter (MainCamera's never moves either) — `clonewatch` cannot tell running from not.

**The reader's plan B** (`engine-research/inbox/2026-09-26-reader-native-clone-plan-b.md`): praydog's own clone DOES render on this PC —
**in VR**: our 2026-09-05 VR logs show "Hooking getPrimaryCamera" / "Cloning MainCamera @" and the same 21 components
`[verified-live 2026-09-05, n=2 processes]`; the installed REFramework (76298bd9, pd-upscaler merge) has `VR_RenderingTechnique_V2=2`
(multipass), and the duplicator only runs with the headset active. So the engine CAN draw a second, non-primary camera; what differs
between his VR clone and our flat one is the open question. His multipass also rewrites window + scene-view size every frame.
