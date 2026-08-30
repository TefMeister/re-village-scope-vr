# 2026-08-23 (afternoon) — Flat PiP scope complete; VR recon; M3 pivots to the in-world lens

Second act of the day (after "lens rides the rifle", see the morning entry).
Plugin v5→v9 + Lua companion v1→v3, all user-tested flat, then a deliberate
5-minute VR recon that redirected the M3 architecture.

## Flat PiP scope — feature-complete (user: "this feels great… a game changer")

- **v5:** hide on unequip (per-frame resolve IS the equip detection — no lens
  on pistols, appears as the rifle is drawn); `ri3042` scoped-weapon filter
  (GameObject name via managed-string `StartsWith` invoke, cached per weapon
  pointer, fail-open); aim-point-centered crop via a **self-calibrating barrel
  axis** — each frame, the muzzle-local axis most aligned with camera forward
  is the bore (no axis-name guessing, no extra launch cycles).
- **v6 (fast-turn fixes):** the game's weapon sway swings the muzzle
  off-frustum on quick turns — hide logic built for holstering made the lens
  flicker out. Now: hide only on unequip, ~0.75 s last-good hold, wider NDC
  bounds, 0.5-factor exp smoothing with 250 px snap-through. Dual-entry
  sampling (BeginRendering vs LockScene, F8 A/B) probes where in the frame the
  presented camera is finalized.
- **v7 (the PiP moment):** Lua companion suppresses the game's scope
  presentation — `on_pre_gui_draw_element` returns false for `GUIScope`
  (draw skipped; game state untouched; the draw signal doubles as the ADS
  detector) + LockScene FOV pin back to remembered hip FOV (also fixes double
  zoom: the lens had been cropping an already-FOV-zoomed backbuffer). Reticle
  styles per zoom preset (plain 1x / duplex stock / fine+dot high-mag),
  root constants 4→8.
- **Companion v3 (weapon vanish):** recon dump showed scope mode hides the
  rifle via the weapon GameObject's **`DrawSelf=false`** (mesh enabled and
  player untouched). Fix = per-frame `set_DrawSelf(true)` hold while scoped —
  holds-over-triggers again. Remaining ADS **camera teleport** (the game never
  interpolates scope ADS because its fullscreen overlay used to mask the cut)
  is PARKED for the flat-polish pass — RE8 hip-fires fine and VR bypasses
  this camera path.
- **v8:** Body-joint mount + live numpad calibration (offset in the joint's
  frame; steps later refined to 0.2 mm x/y) + **distance-scaled lens** from a
  physical lens radius (ADS fills the objective, hip shrinks; crop covers
  lens_w/zoom screen px so magnification stays true at any display size).
  **User's calibration baked as defaults: offset (0, 0.151, 0.099), radius
  0.039** (numpad 0 resets to these).
- Discovered en route: the scope 3D model has its own red glass reticle
  texture, and the F2 rifle has **fully modeled iron sights** under the scope.

## VR recon (Quest 3, deliberate 5-minute peek) — three findings

1. **The lens never reaches the headset** — the composite draws on the desktop
   swapchain, which in VR is only a mirror.
2. **The mirror ACCUMULATES** (no full redraw per present — cursor trails
   prove it) → our draw+capture fed back into a spectacular lens-of-lens
   Droste storm on the monitor. v9 adds a VR guard: composite skipped when
   FOV ≥ 75° (VR renders ~81°, flat tops out ~63°), F10 cycles
   auto/force-off/force-on.
3. **The plugin C API has no VR surface at all** (upstream API.h fetched and
   verified byte-identical to our vendored copy — zero VR/eye/OpenXR symbols).
   There is no supported way to composite into REFramework's eye textures.

Bonus: the reflection chain itself works fine in VR (camera tracks the HMD,
FOV 81.1, `ok-body` reached). Projection no-locked with a
length-not-preserved-through-rotation smell in the numbers — not worth
chasing, because M3 replaces that path entirely.

## M3 PIVOT — the in-world lens (new primary architecture)

Since eye-texture compositing is unsupported, the "plan-B research track" is
now plan A, and it is the better scope anyway:

- Build the lens **inside the game world**: an engine-side render target
  displayed on a quad mounted to the rifle. REFramework VR then renders it in
  **true stereo with real depth for free** — no compositor work, correct in
  both eyes, and the flat game gets the same object.
- The engine door is already known: **`app.CameraSystem`** exposes
  `getViewProjMatrix` + `captureToTexture` /
  `setRenderTargetTextureResourceHandle` — recorded during the RE2
  inventory-camera probe with the note "for the RE Village scope M2b!".
- Open research questions for the next sitting: create/locate a second camera
  to feed `captureToTexture`; make/assign an engine render-target texture;
  spawn a quad (or reuse a scope-glass mesh part) with that texture; mount it
  at the calibrated Body-joint offset (already measured!).

## Where everything stands

- Deployed: plugin v9 (VR-guarded flat PiP scope), companion v3, probe v5.
- Flat PiP scope = candidate for the standalone non-VR release (STATUS §7).
- The flat version keeps working in flat; VR is safe (guard) but scopeless
  until M3 — the game's own scope also stays suppressed in VR while the
  companion is enabled (set `cfg.enabled=false` in the companion to restore
  stock behavior for actual VR playthroughs).
