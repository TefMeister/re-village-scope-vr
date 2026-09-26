# NEXT RUN 2 (/lm, flat, one launch): the mid-frame copy, the sliding picture, brightness

Built + deployed 2026-09-26 night by `/pd` (Opus): plugin `43f315bf`, `re8_scope_cam_fix.lua` (`clonepo [N]`, `clonestage`),
`re8_scope_cam_clone.lua` (`_bore_write`). `[compile-verified 2026-09-26]`, script tests pass. **Not run.**

## 1. The finished picture, copied mid-frame
The plugin now hooks `ID3D12GraphicsCommandList::ResourceBarrier` (vtable slot 26). When the shared PrepareOutput texture leaves
RENDER_TARGET for the Nth time in a frame (N from `clonepo N`, default 1), it copies it into a texture of our own, on the game's
own command list, and the glass shows that copy.
- `RIFLE-CAMERA-ON.bat`, `re8drive.py boot`, then `cmd "clonepo"`. Read `po: ResourceBarrier hooked`, `po #1: ... OUR COPY ...`,
  and every ~150 frames `po copy: X copies in Y frames; the shared texture left RENDER_TARGET Z times (max M in one frame)`.
- Glass shows the magnified rifle view, GRADED (outdoors grey fog, not white) → **fixed**.
- Glass shows the MAIN view → the main layer writes first: `cmd "clonepo 2"`.
- `copies 0` → the texture never leaves RENDER_TARGET through a plain transition (split barriers, or enhanced barriers):
  read the `left RENDER_TARGET` count; 0 means we need another trigger.
- Any crash/device removal → put the previous DLL back (deploy-backups, MANIFEST) and write it down.

## 2. Tefa: "the scope picture is sliding around on the end of the scope, not stuck to the scope glass"
`[reported 2026-09-26]`. Suspect `[hypothesis]`: the rifle pose is read in LockScene but the rifle is drawn from a later pose.
Try `cmd "clonestage BeginRendering"`, then `UnlockScene`, then `LateUpdateBehavior`; sway the rifle (mouse) and compare.
`clonestage LockScene` restores. If none helps, the sliding is elsewhere (the glass texture binding), not the camera timing.

## 3. Tefa: contrast and brightness need tuning `[reported 2026-09-26]`
In clone mode the 8-bit picture is shown at unit gain with no contrast control. Judge again AFTER step 1 (the graded picture
may already fix it); only then add a clone-mode exposure/contrast knob.

Put the autostart back to `1` (SCOPE-AUTO-ON.bat) at the end.
