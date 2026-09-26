# NEXT RUN (VR, Tefa in the headset, Claude sending words): where does the rifle camera's picture go in VR?

Built + deployed 2026-09-26 23:0x by `/pd` (Opus), not run: plugin `ec4ac6cc` (po watch), `re8_scope_cam_fix.lua` (`clonedist`).

Tefa: `RIFLE-CAMERA-ON.bat`, start with **LAUNCH-VILLAGE.bat** (keeps the log), VR, draw the rifle. Claude, one word at a time:
1. Wait for `clonepo: automatic` → the plugin logs `po watch (...): ... NOT rotating | ROTATING` after 300 presents.
   - ROTATING → the clone's PrepareOutput output changes per frame in VR: copy against the whole set (next build).
2. `clonedist` → prints DistortionType on MainCamera's RenderOutput, the clone's RenderOutput, the clone's Scene layer.
   - The clone carries 1 or 2 (an eye) → `clonedist 0`, then `clonekill` + `clonescope 20` (auto clonepo follows) → ask Tefa.
   - All 0 already → the eye setting is not it; next: compare which textures leave RENDER_TARGET in VR (a size census).
3. Tefa says what the glass shows after each step. `SCOPE-AUTO-ON.bat` at the end.

Background `[inferred-static 2026-09-26]`: REFramework VR sets `DistortionType` on the PRIMARY camera's RenderOutput each frame
(VR.cpp fix_temporal_effects: 1 left / 2 right) and on a scene layer around its PostEffect pass; our clone copied MainCamera's
components at build time. The VR glass showed a 1559x1670 (eye-size) texture holding the frozen desktop picture.
