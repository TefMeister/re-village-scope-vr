# inbox: what makes RE Village draw a SECOND camera into a texture? (from the modding lane, 2026-09-26)

For `/gr`. Dossier §9cr; evidence `dev-archive/recon/2026-09-26b-rifle-camera-draws-nothing/`.

**What we know** `[verified-live 2026-09-26]`: a `via.Camera` + `via.render.RenderOutput` (id 2, RenderTarget = our own
`movie_*.rtex` holder) on a fresh GameObject parented to the rifle is REGISTERED by the engine — two Scene layers, 13 passes each,
sized to the target, enabled — but NEVER DRAWN: the target stays a cleared flat colour, the HDR intermediate is junk memory. Adding
every `via.render.*` component of MainCamera, the pose, `UpdateSelf`, and the background colour change nothing. The only working
secondary view we have is `via.render.Mirror` (a mirror layer per eye camera).

**Questions for the open web / the community:**
1. Which RE8-era (RE2R / RE3R / RE7 / RE8, TDB ~70) game object renders a camera into a texture — in-game monitors, RE8's factory
   security cameras, RE2R's police-station monitors — and which components/flags does it carry (`UseCustomSceneLayer`?
   `RenderModeChangable`? a `via.render.Mirror`-like registration? a `via.SceneView` list?).
2. Has anyone rendered a second `via.Camera` to a texture through REFramework Lua/C++ in a TDB-70 game (not RE4/SF6/DD2, where the
   engine's multipass/duplicate camera path exists)? praydog's `CameraDuplicator` is NOT in the current REFramework tree.
3. Does REFramework's own VR mod (the RE8 "RE8VR" code) touch `via.Camera` FOV every frame — something forces our camera's FOV from
   20 to 26.23 within two seconds.
