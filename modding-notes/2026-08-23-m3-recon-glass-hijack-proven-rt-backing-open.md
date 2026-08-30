# 2026-08-23 (evening) — M3 recon: glass hijack PROVEN; RT backing is the open problem

Third act of the day. Six hot-reload Lua recon rounds (no game restarts needed
for any of it — `re.on_pre_gui_draw_element` + Reset Scripts is a wonderful
lab bench). Verdicts, in order:

## Proven (user-verified visually)

1. **The scope glass is hijackable at runtime.** The F2 rifle mesh has four
   materials; `it02_070_Sniperrifle_01_Lens_Mat` / `Lens2_Mat` (materials 2/3)
   are the glass. Each has exactly TWO texture slots: `FakeSpecularMap` (0)
   and **`Reticle_BaseAlphaMap` (1) — the visible reticle image**, and
   `via.render.Mesh:setMaterialTexture(mi, 1, <TextureResourceHolder>)`
   **visibly replaces it with any loaded texture, full-color, across the whole
   glass** (rifle-body texture atlas shown on the glass, screenshot in
   dev-archive). The glass "interior" is shader-faked (parallax — the user saw
   the reticle move depth-wise in VR); there is no scene texture in it.
2. **Occlusion truth (flat):** the game's ADS weapon-hide is load-bearing for
   any backbuffer-crop scope — with the rifle visible, the scope model
   occupies exactly the pixels the crop magnifies ("a magnified picture of the
   scope itself"). Companion keeps the game's hide behavior; M3's real capture
   is what allows a visible rifle.
3. **Resource creation chain works from Lua AND the plugin C API** (the
   one-DLL endgame holds): `sdk.create_resource("via.render.RenderTargetTextureResource",
   "movie/rtex/movie_1280_720.rtex")` → non-nil; `res:create_holder(
   "via.render.RenderTargetTextureResourceHolder")` → non-nil. RE8's PAK ships
   usable `.rtex` (movie_1280_720/1920_1080, mirror_env, per-character
   recordsys RTTs — full list: Ekey/REE.PAK.Tool `RE8_STM_Release.list`).
   Path convention: relative, after `natives/stm/`, no trailing `.5`.
4. **`via.gui.GUI.set_RenderTarget(holder)` takes effect** — redirecting
   GUIRemainAmmo removed the ammo counter from the HUD instantly.
5. **Type compatibility:** `RenderTargetTextureResourceHolder` IS-A
   `TextureResourceHolder` → RTs plug directly into `setMaterialTexture`.
6. **`via.render.Mirror`** exists with `get/set_RenderTarget` +
   `registerScene(Scene, Scene)` — a component whose whole job is rendering
   the scene into an RT.

## The open problem: RT GPU backing

Binding our created RT to the glass returns success but changes nothing, even
with a redirected GUI producer and delayed/repeated rebinds (3 s × 5). Reading:
an `.rtex` resource is a descriptor; its GPU texture materializes only through
pipeline registration we haven't found (mirrors/movies do extra setup). The
redirected ammo GUI most likely rendered into the void, not into our RT.

## Next-session candidates (in order)

1. **Mirror as producer:** instantiate/attach `via.render.Mirror` (component
   add via reflection), `set_RenderTarget(our RT)` + `registerScene` — its
   entire purpose is forcing scene→RT. If the glass then shows the mirrored
   scene, we have an engine-rendered scope image (mirror aimed by us =
   periscope optics; FOV/framing = later problem).
2. **Plugin-side texture hijack:** find the D3D12 resource behind the
   CURRENTLY WORKING reticle texture binding and overwrite its GPU contents
   per frame (format question: likely BC-compressed → may need an
   uncompressed replacement texture bound first via setMaterialTexture, then
   overwrite THAT).
3. **RecordSys angle:** the per-character `*_recordsys_rtt.rtex` + whatever
   `app.RecordSys*` types exist — RE8's model-viewer probably runs a second
   camera into an RT; finding its runtime API could hand us a steerable
   engine camera→RT path.

## Cleanup state (IMPORTANT for the next session)

- All `m3_recon*` scripts are RETIRED from autorun (recon6 would otherwise
  redirect the ammo GUI every launch). Copies live in `-staging/scripts/`.
- Companion restored to shipping config (`keep_weapon_visible=false`).
- All experimental material/GUI state is runtime-only — **one game restart
  restores stock visuals (ammo counter included)**.
- Known plugin nit: F10 never reached us — F10 arrives as WM_SYSKEYDOWN, not
  WM_KEYDOWN (Windows menu key). Fix in the next plugin build.
