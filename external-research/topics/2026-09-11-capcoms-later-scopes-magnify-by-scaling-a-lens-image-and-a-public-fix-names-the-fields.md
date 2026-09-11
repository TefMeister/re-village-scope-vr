# Capcom's later scopes magnify by scaling a lens image, and a public MIT-0 fix names the exact fields

**Status:** 🆕 new · **Priority:** medium — it does not move a board row by itself, but it gives the
⭐⭐ `[PD]` "read Capcom's own VR scope" row a concrete reading of what `ExpansionRate` is likely
to be, and a worked public pattern for hooking an `app.*` scope controller's parameter block.

## Why this was looked up

The ⭐⭐ `[PD]` row rests on `app.VrWeaponSniperScopeLensUpdater` (`DistortionBegin`,
`ExpansionRate`, `ReticlePosition`, `LensLeftPosition`, `LensRightPosition`). The 2026-09-10 pass
recorded that **nothing public documents that class**, and that is still true. What this pass asked
instead is narrower: *how do Capcom's other RE Engine scopes magnify, and has anyone in public
already hooked one?* The nearest sibling with public work is Resident Evil Requiem (RE9), whose
community has a scope-resolution complaint and a fix for it.

## What is public

**TonWonton's `RE9_ScopeResolutionFix`** (Nexus + GitHub, MIT-0, Lua and C# versions, needs
REFramework) `[reported 2026-09-11]`. Read online in the repo viewer only; nothing cloned or copied.
In the author's words the base game "rendered at a higher FOV and zoomed/scaled that image instead
of just zooming in with FOV", which is why the flat RE9 scope looks soft — the lens picture is a
**scaled crop of a wider render**, so its effective resolution is a fraction of the frame.

Mechanism, described from the script (own words, no code):

- It looks up two managed types, **`app.ScopeCameraControllerV3`** and **`app.ADSCameraController`**.
- It pre-hooks the scope controller's *set display scope* method, reaches the controller's
  **`_ParamUserData`** block and writes **`_LensImageDefaultScale` = 1** and
  **`_LensImageZoomRate` = 0** — i.e. it switches the lens-image scaling **off**.
- It pre-hooks the ADS controller's *update FOV* method and rewrites each zoom step's
  **`_ZoomFov`** so the magnification comes from the camera FOV instead. One setting,
  `f_scopeBaseZoomMultiplier` (default 2.0).
- It never detects "scope active" — it relies on those two engine methods only being called while
  the scope is in use.

Result claimed by the author: full-resolution scope **and** better frame time when scoped (the wide
render is no longer wasted). Both are `[reported]`; nobody here has run it.

## What it means for THIS project

1. **RE8 flat is different and that is already on record** — dossier §2: RE8's flat scope is a
   main-camera FOV zoom with a GUI mask, no lens image, no offscreen render. So the RE9 fields do not
   exist to be flipped in RE8's flat path. **Do not go looking for `_LensImageDefaultScale` in RE8.**
2. **But RE8's VR scope class has a term of the same family.** `app.VrWeaponSniperScopeLensUpdater`
   carries `ExpansionRate` and `DistortionBegin`. RE9's flat scope calls its lens-image magnification
   a *zoom rate* on a *default scale*. The family resemblance suggests **`ExpansionRate` is a
   lens-image magnification against a fixed rendered picture, not a camera-FOV or reprojection
   term** `[hypothesis]` — which is consistent with the dossier's reading that RE8 handles the eyes
   *at the lens* (`LensLeftPosition` / `LensRightPosition`) rather than at the render. When the type
   is dumped, the first things to read are: is `ExpansionRate` applied to a quad/material UV scale,
   and does `DistortionBegin` bound a radial region of that same picture.
3. **A worked pattern for the `[PD]` dump.** The RE9 script is a minimal public example of the
   exact move the row needs once the type is read: find the `app.*` controller, hook one of its
   methods, reach its parameter user-data and write a float. It is REFramework-Lua-generic; nothing
   RE9-specific about the *shape* of it.
4. **A cautionary parallel for our own lever.** Capcom's own lens-image design costs resolution
   because the picture is a crop of a wider render. Our mirror route pays instead with a second
   full-scene render at the `.rtex` size (the `[FLAT]` frame-cost row). Neither is free; the RE9
   author's "better performance when scoped" is the reminder that a *narrower-FOV* mirror camera at
   a *smaller* target can beat a wide render cropped — worth remembering if the 2560/3840 cost
   measurement comes back ugly.

## Also checked this pass, negative and worth not re-spending

- **REFramework `master` today still has the `on_camera_get_projection_matrix` primary-camera guard
  commented out and the `on_camera_get_view_matrix` guard live; no scope, mirror or RE8-specific
  exemption exists in either** `[reported 2026-09-11, read from the file on master]`. Nothing
  upstream has retired the ⭐⭐ mirror-camera-exemption `[PD]` row.
- Nexus pages for the RE9 mods return 403 to automated fetches; the GitHub repo is the readable
  source. A 403 is not a negative about the mod.

## Sources

- TonWonton — RE9 Scope Resolution Fix: https://github.com/TonWonton/RE9_ScopeResolutionFix
  (Nexus listing: https://www.nexusmods.com/residentevilrequiem/mods/588)
- TonWonton — RE9 Sensitivity Scaling Fix (same author, sibling scope/ADS work, not read in
  detail): https://github.com/TonWonton/RE9_SensitivityScalingFix
- praydog — REFramework `src/mods/VR.cpp` on `master`, read online:
  https://github.com/praydog/REFramework/blob/master/src/mods/VR.cpp

## Next step

None new for the board. When the ⭐⭐ `[PD]` type-DB read happens, read `ExpansionRate` with the
hypothesis in §2 above in hand and record whether it held.
