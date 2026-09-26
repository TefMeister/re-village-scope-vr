# Reader: where an RE8 via.Camera gets its view/world matrix (2026-09-26, static, REFramework pd-upscaler)

For §9cu / `dev-archive/recon/2026-09-26h-write-the-world-matrix/NEXT-RUN.md`, the case where the clone camera's
View/World stay identity after `clonepose` writes the transform's WorldTransform (+0x80).

## What the source says

- **via.Camera has no matrix field.** REFramework's `RECamera` (`shared/sdk/types/REComponent.hpp`, shared by all games, size
  0x198): near 0x30, far 0x34, fov 0x38, lookAtDistance 0x3C, verticalEnable 0x40, aspect 0x44, cameraType 0x50, name 0x60,
  rest unknown pads. No regenny via.Camera layout for re8 (re4/re9 `Camera.hpp` are empty 0x10 stubs). Matches `matscan`
  finding no position in the camera. `[inferred-static 2026-09-26]`
- **get_ViewMatrix is `(camera, Matrix4x4f* result) -> result`** (`Hooks.cpp` l.1066-1090, native inner function found by
  pattern `49 8B C8 E8` / `48 8B CB E8` in the reflected wrapper). Its body is not in the source, so "computed from the
  owner's transform each call" is not shown; the missing camera field makes it likely. `[hypothesis]`
- **praydog's own note in `VR::on_camera_get_view_matrix`:** in multipass "the game *always* uses the main camera when
  calling this function, even though it's rendering the other camera". So his clone layer's view may simply be MainCamera's,
  which would explain why his clone renders a sane view while ours is identity. `[inferred-static 2026-09-26]`
- **When praydog forces a second camera's pose (RE2/RE3 path, `VR.cpp` ~l.1630):** he copies the world matrix
  (`transform1->get_world_transform() = transform0->get_world_transform()`) **and** sets the transform's **joint 0** with
  `via.Joint.set_Position` / `set_Rotation`. His restore code also works through joint 0. So joint 0 is a second copy of the
  pose. RE8 joints array: transform +0xD8 (`REJointArray`: data 0x0, `JointMatrices*` 0x8 → 0x40-byte world matrices).
  `[inferred-static 2026-09-26]`
- **Per-layer SceneInfo** = reflection property `"SceneInfo"` on `via.render.layer.Scene` (also DepthDistortion-, Filter-,
  JitterDisable-, JitterDisablePost-, ZPrepassSceneInfo). Layout (REF's struct, used for every game incl. RE8; tail from
  regenny re4/re9): view_proj 0x00, view 0x40, inv_view 0x80, proj 0xC0, inv_proj 0x100, inv_view_proj 0x140,
  old_view_proj 0x180, camera_pos 0x1C0, z_near 0x1CC, camera_dir 0x1D0, z_far 0x1DC. It is filled inside the layer's own
  `update` (vtable index `RenderLayer::get_update_vtable_index()`); praydog writes it only in the POST hook of that update.
  `[inferred-static 2026-09-26]`

## Ranked writes to try

1. **Joint 0 of the clone transform**: `tf:call("get_Joints")[0]` → `set_Position` / `set_Rotation` with the source pose,
   every LockScene, beside the +0x80 write. First log the clone's joint count: a runtime GameObject may have **zero joints**,
   which alone could be why its matrices never move. `[hypothesis]`
2. **Write the clone layer's SceneInfo natively, after its update**: vtable-hook our clone Scene layer's update in the
   plugin; post-original write view 0x40, inv_view 0x80, view_proj 0x00, inv_view_proj 0x140 (and proj 0xC0/0x100 if
   wanted). This does not care where the camera reads from. A Lua write before the update would be overwritten. `[hypothesis]`
3. **Don't write the camera itself**: no known matrix field in via.Camera for RE8. `[inferred-static 2026-09-26]`
