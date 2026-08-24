# 2026-08-24 — Real-gameplay glass-material test: timing bug found and fixed

**Goal:** finish step 2 of the post-breakthrough plan — bind the continuous-blit real scope
content to the glass's actual material slots, in real gameplay with the scoped rifle equipped,
instead of the brute-force every-mesh proof on the title screen.

**Gameplay access worked immediately.** `app.SaveLoadFlowManager:call("requestContinue")`
reached real gameplay both times tried — the gamepad-only confirmation screen from the prior
session didn't appear this run. Two one-time DLC popups needed a single click each to dismiss.
Once in, the existing weapon-detection logic auto-locked the scope lens onto the equipped rifle
as designed.

**Found and fixed a real bug.** The auto-bind attempt first failed with `committed=0000...0000` —
`ensure_created()` was disarming the D3D12 resource-capture hook *before* the actual
`CreateCommittedResource` call happened (it's async, lands a frame or more later). Fixed by
leaving the hook armed permanently after first use, and by gating the auto-bind trigger on the
resource actually being ready rather than firing the moment a scoped weapon is detected.

**Result:** confirmed working immediately after the fix — `bind_holder_to_mesh()` fired
correctly in real gameplay (5615 meshes, 44920 calls), binding the real continuous scope content
(not a static test pattern) for the first time outside the title screen.

**Honest gap:** the screenshot taken right after didn't land a clean shot of the scope's ocular
lens itself (dark scene, low-angle ADS) — the mechanism is confirmed firing correctly, but a
clean "yes the glass itself shows it" screenshot is still the next step, along with narrowing the
bind from all 5615 meshes down to just the glass's own material slots (mats 2/3, slot 1) for a
real implementation.

Full detail, code, and the screenshot: dev-archive
`recon/2026-08-24-glass-material-in-real-gameplay/`. Plugin fix: staging `9c259b4`.

**Next:** get a bright, close, front-on shot of the lens for final visual confirmation, then
narrow the bind to the glass's real material slots instead of brute-forcing every mesh.
