# Reader: plan B, a clone camera from the native plugin (2026-09-26)

Source: REFramework `pd-upscaler` `CameraDuplicator.cpp`, `VR.cpp/.hpp`, `shared/sdk/Renderer.cpp/.hpp`; master `include/reframework/API.h/.hpp`;
the game folder's `re2_fw_config.txt` and `re2_framework_log.txt` (read only); `dev-archive/recon/2026-09-05-vr-model-test/launch2-full-re2_framework_log.txt`.
Static reading only; nothing launched.

## Headline: a second camera already renders on this machine, in VR

- The installed REFramework is `76298bd9` = "Merge branch 'master' into pd-upscaler", 2026-03-11, so it contains CameraDuplicator.
- `re2_fw_config.txt` has `VR_RenderingTechnique_V2=2` = **Single Frame Multipass** (the TDB 69 default). The duplicator runs only when
  the headset is active AND the technique is multipass (`CameraDuplicator.cpp` lines 61, 84-90) `[inferred-static 2026-09-26]`.
- The 09-05 VR log shows it doing so: `Hooking getPrimaryCamera`, `Cloning MainCamera @ ...`, `Created new component via.Camera ...`,
  the same 21 components our `clonemake` makes `[verified-live 2026-09-05, n=2 processes, read from archived logs]`. Its clone draws the
  second eye, so the engine does execute a non-primary camera's Scene layer here. **This corrects the §9cr line "praydog's VR.cpp has no
  second-camera path for RE8"** for this build.
- In flat (no headset) the duplicator is off, and our 09-25 VR test ran with THREE cameras (main, `MainCamera (Clone)`, ScopeCam).

## 1. What praydog does that Lua cannot

Everything in CameraDuplicator itself is reachable from Lua (create, createComponent, setParent, byte writes 0x12/0x13, priority +0x48,
the `get_PrimaryCamera` hook, LockScene timing, `add_ref`) `[inferred-static 2026-09-26]`. What is NOT reachable from Lua, nor from the
plugin API (which offers pre/post application entry, `Method::add_hook`, invoke, raw pointers, but no layer callbacks):
- **Reading the clone's picture.** VR.cpp never uses the RenderOutput; it takes the texture from the clone layer's child `PrepareOutput`
  output state (RTV 0 -> Texture -> ID3D12Resource), found by offset scans in `Renderer.cpp`. Portable into our plugin as raw reads.
- **Layer update/draw callbacks** (`on_pre_scene_layer_update` etc.) are REFramework-internal vtable hooks.
- Nothing in VR.cpp switches the clone's layer on: its layer hooks always return "draw" `[inferred-static 2026-09-26]`.

## 2. Consequence

**An empty glass does not prove our layer never runs.** Output ID 3 with no RenderTarget goes nowhere visible; praydog pulls the picture
out of the layer `[inferred-static 2026-09-26]`. `clonewatch`'s ResizeFrame is not a run counter (MainCamera's is static too).

## Ranked next steps

1. **Execution detector in the plugin** `[hypothesis]`: log `CreateCommittedResource` calls in the 2 s after `clonemake` (targets sized
   1114x835 = the clone's scene size); then copy one each frame to a readback buffer and log whether its pixels change.
2. **Flat: force a resize after `clonemake`** (window 1280x720 -> other -> back) `[hypothesis]`: multipass VR rewrites the window/scene-view
   size every frame (HMD+1 / -1), which may be what builds a new camera's targets.
3. If 1 shows it runs: port praydog's PrepareOutput -> RTV -> ID3D12Resource read into the plugin and copy that to the glass `[hypothesis]`.
4. In VR, give ours a RenderOutputID other than 3 (praydog's clone uses 3) `[hypothesis]`.
