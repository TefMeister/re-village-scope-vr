# REFramework writes the FOV only on the PRIMARY camera, but the eye projection on every camera

*Answers the modding lane's 2026-09-26 hand-off ("what makes RE Village draw a second camera"), question 3, and
records what was and was not found for questions 1 and 2.*

## Why it matters here

The rifle-scope camera (`via.Camera` + `via.render.RenderOutput` on a fresh GameObject) is registered by the engine
but never drawn, and its FOV moves from 20 to 26.23 within two seconds of being set. If REFramework's VR mod were
the writer, the fix would be a REFramework setting; if not, something in the game is driving that camera.

## What REFramework's source says (read 2026-09-29, `praydog/REFramework` at commit `09284e2fee`, 2026-04-25)

- `VR::on_pre_update...` (src/mods/VR.cpp ~1459-1526) takes `sdk::get_primary_camera()` and, every frame, calls
  `set_FOV(vfov)`, `set_VerticalEnable(true)` and `set_AspectRatio(aspect)` **on that one camera**, with the vertical
  FOV and aspect derived from the HMD projection. `[inferred-static 2026-09-29]`
- `sdk::get_primary_camera()` is `via.SceneView.get_PrimaryCamera` of the main view (shared/sdk/SceneManager.cpp).
- `Camera::on_pre_application_entry` (src/mods/Camera.cpp) writes a user "global FOV" at `BeginRendering`, again
  only on the primary camera, and only when that option is on.
- By contrast, `VR::on_camera_get_projection_matrix` has its "only the primary camera" guard **commented out**, so the
  per-eye HMD projection is handed to every camera; `on_camera_get_view_matrix` does keep the primary-only guard.
  (This matches our 2026-09-07 topic.)

**So:** unless the rifle camera had become the view's primary camera, REFramework is not what moves its FOV from
20 to 26.23 `[inferred-static 2026-09-29]`. The next suspect is the game's own camera logic (a component on the
cloned GameObject, or a camera controller that adopts new cameras). A cheap live check: read
`via.SceneView.get_PrimaryCamera` while the rifle camera exists; if it is the rifle camera, the VR mod IS the writer.
A value of 26.23 does not look like an HMD vertical FOV, which points the same way `[hypothesis]`.

## Questions 1 and 2: not found

- No public write-up was found of an RE2R/RE3R/RE7/RE8 (TDB ~70) object rendering a camera into a texture (police
  monitors, factory security cameras), nor of anyone doing it through REFramework Lua/C++ on those games. Two web
  searches and a code search of REFramework (`RenderOutput`, `SceneView`, `TargetTexture`) turned up only the VR
  mod's own use of `RenderOutput` (setting `DistortionType` per eye on the primary camera) and the regenny layouts.
  ⚠️ Automated searching; not a proven absence.
- `via.SceneView` (regenny, re8) holds a `Window*`, a `Scene*`, background colour, size, custom display size and
  present rect; it has no obvious camera list in the laid-out fields `[inferred-static 2026-09-29]`. Whether a second
  SceneView is what an in-game monitor uses stays open.

## Sources

- praydog, REFramework: `src/mods/VR.cpp`, `src/mods/Camera.cpp`, `shared/sdk/SceneManager.cpp`,
  `shared/sdk/regenny/re8/via/SceneView.hpp` (github.com/praydog/REFramework).
