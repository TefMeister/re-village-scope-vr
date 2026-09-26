# 2026-09-26 evening (/lm, flat, Opus) — 🏆 THE RIFLE CAMERA RENDERS THE WORLD

One launch, Claude driving, `re8_scope_cam_clone.lua` (staging `bc0e593`). `[verified-live 2026-09-26, n=1]` throughout.

**`clonetf` before:** the clone's transform has a **valid Scene\*** (the same as MainCamera's), `Parent*=0` (setParent did not take),
`UpdateFrame=4294967294` (never updated), dirty flags 0, `WorldTransform` = identity. MainCamera: UpdateFrame 94219, real world rows.

**`clonepose main`** (copy MainCamera's 16 world floats into the clone's transform +0x80 every LockScene): the clone's
`get_ViewMatrix` / `get_WorldMatrix` **became exactly MainCamera's** — the camera derives its view from the transform's cached
world matrix. **`clonepose rifle`**: View/World followed the rifle's pose (13 non-zero elements, row 3 at the rifle).

**The picture (numpad `+`, 8-bit resolve of our 2560 target):** before = the uniform bright vignette field (0.73–1.00); after
`clonepose main` = a structured scene (0.08–1.00, 74 % below 0.5), changing when walking; after `clonepose rifle` another scene.
**On the glass** (crop-follow off, `set_FOV 20`): a close fabric texture from the rifle's root (the camera sits inside the hand);
from MainCamera's pose the **magnified carved wall panel**, and a different stretch of wall after strafing. Dark — exposure is not
copied yet.

**So:** a camera of our own renders in RE8, flat, with no REFramework VR code — the only missing piece was the world matrix the scene
never computes for a runtime GameObject. `ResizeFrame`, the draw flag, output ids, components, LockScene timing were all red herrings
for THIS failure (praydog's recipe is still the right shape).

**Next (the glass, not the engine):** (1) pose = the rifle's bore, not its root — offset forward along the muzzle axis past the scope
tube, orientation along the bore (the 13° root-vs-muzzle offset is in the dossier); (2) exposure: copy MainCamera's ToneMapping /
auto-exposure properties each frame (praydog's `m_wanted_components` property copy), or the glass exposure knob; (3) FOV per
scope; (4) fold into `autostart` instead of the mirror rig, and test in VR (does the VR mod leave a third camera alone?).
