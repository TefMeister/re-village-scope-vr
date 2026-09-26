# 2026-09-26 reader: how to get the rifle camera's Scene layer executed (static, no launch)

Author: static reader helper beside the live `/lm` session. Nothing here was run. Answers dossier section 9cr "Open".

## Biggest finding: praydog's RE8-era second camera DOES exist, and our probe copied it wrong

`CameraDuplicator.cpp` is on REFramework branch **`pd-upscaler`**, not `master`
(`gh api "repos/praydog/REFramework/contents/src/mods/vr/CameraDuplicator.cpp?ref=pd-upscaler"`).
It is guarded `#if TDB_VER >= 69` with the comment "Untested on older than TDB 69 (RE8)", so it is meant to cover RE8.
The engine itself executes the clone's Scene layer: `VR.cpp` (same branch, `on_prepare_output_layer_draw`) only copies
its PrepareOutput result. What the clone does that ours does not:

- `new_camera_gameobject->set_shouldDraw(false)` before the components, then **`set_shouldDraw(true); // YES draw by default`**
  after them (lines ~246 and ~327). `copy_camera_properties` then sets `shouldDraw(camera_gameobject == new_camera_gameobject)`:
  **the GameObject draw flag is the per-camera switch that decides whether the camera renders.** Our `cammake` sets
  `set_Draw(false)` and never turns it back on (`re8_scope_cam_probe.lua` lines 198-200).
- `set_RenderOutputID(3)` (ours is 2). `re8.exe` names the enum `via.render.RenderOutputID` = None / Primary / Secondary /
  Tertiary / Quateary, so 2 = Secondary, 3 = Tertiary.
- Camera int at +0x48 ("priority") = -1; CameraType at +0x50 flipped to Debug only *inside* a `get_PrimaryCamera` hook,
  back to Game afterwards, so the clone renders as a Game camera but is never chosen as primary.
- Copies every component of MainCamera except `app.*`, `via.motion.*Camera`, `via.wwise.WwiseListener`, `via.physics.Colliders`,
  `via.render.ExperimentalRayTrace`.

## SceneView facts (`shared/sdk/regenny/re8/via/SceneView.hpp`, `SceneManager.hpp`, `shared/sdk/Renderer.*`, master)

- `via.SceneView` (0xb0): `window @0x10`, `scene @0x18`, `size @0x30`, `camera_type @0x6c`: **no camera pointer.** A view picks
  its camera through `get_PrimaryCamera`; `SceneManager.main_view @0x48`.
- `sdk::renderer::add_scene_view(void*)` / `remove_scene_view` (Renderer.cpp:956-981) call the engine's
  `addSceneView(via::SceneView*)`, found by byte pattern; nothing in master calls them and Lua cannot reach them.
- `layer::Output::get_scene_view()`: every Output layer carries its own SceneView. `layer::Scene` has
  `get_ViewID`, `get_Camera`, `get_Mirror`, `get_Enable`; "fully rendered" = enabled, no mirror, camera named `MainCamera*`.
- The `re8.exe` name pool puts `get_Independent, get_Version, isRegisteredScene, registerScene(via.render.layer.Scene*),
  unregisterScene` right before the Scene layer's `get_ViewID/set_ViewID/get_Camera/set_Camera/get_Mirror/set_Mirror`,
  which suggests the Output layer keeps a list of the Scene layers it runs. `[hypothesis]` (the owning type is read from order, not from the TDB)

## What to try from Lua, in order

1. After `cammake`: `go:call("set_Draw", true)` (also `set_DrawSelf` if it exists) and read raw bytes +0x13/+0x15 of the GameObject. `[inferred-static 2026-09-26]`
2. `ro:call("set_RenderOutputID", 3)`. `[inferred-static 2026-09-26]`
3. Redo `camcopy` with draw on. `[inferred-static 2026-09-26]`
4. On the parent Output layer: `isRegisteredScene(our layer)` against the main layer; if ours is false, `registerScene(our layer)`. `[hypothesis]`
5. Sidestep: `set_Camera(ScopeCam's via.Camera)` on a Scene layer that does draw (the rig's own). `[hypothesis]`
6. Last resort: a native plugin creates a `via.SceneView` and calls `addSceneView`. Heavy, and nothing public does it. `[hypothesis]`

## Other public mods

No public RE Engine mod was found that renders a second camera into a texture. Code searches for `via.render.RenderOutput`
and `RenderTargetTextureResource` in Lua returned nothing, and GitHub's code-search rate limit cut the rest short. `[reported]`
