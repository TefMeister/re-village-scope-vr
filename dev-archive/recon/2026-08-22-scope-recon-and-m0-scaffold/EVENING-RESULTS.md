# Evening results (2026-08-22 late -> 2026-08-23 ~01:00)

Same-night continuation of this recon session. All verified live in-game.

- **M0 verified:** plugin loads, renderer = D3D12 (device/swapchain/command
  queue all provided), BeginRendering + on_present fire, survived repeated
  device resets during OpenXR init.
- **M1 verified:** own 480x360 render target cleared per frame and composited
  into the backbuffer at present time (barriers + fence). We own pixels in the
  game's frame.
- **M2a verified:** digital-zoom scope image. Backbuffer captured at present,
  magnified crop drawn into the RT (root signature + runtime-compiled HLSL +
  PSO), composited as an alpha-blended CIRCLE (crosshair + vignette; the
  vignette reads as raised glass). F9 cycles zoom presets live via the
  window-message hook.
  - Key lesson: frame magnification as "the render target IS the lens" -
    the source crop covers rt_size/zoom pixels. Cropping full-FOV/zoom gives
    a region larger than the box = a downscaled mini-monitor, not a magnifier.
- **Authentic magnifications measured** (FOV dwell analysis, hip = 63.00 deg):
  stock F2 scope 26.23 deg = 2.40x; High Magnification Scope 24.37 deg =
  2.58x. Only ~8% apart; confirmed visually indistinct. All earlier 24.37
  readings were the high-mag scope (mounted on the main save all along).
- **Weapon recon complete (probe v5):** F2 = `ri3042_Inventory`
  (`app.WeaponGunCore`); 7 joints only (root/Body/Magazine/Slide=bolt/
  Trigger/vfx_muzzle/Cartridge); zero child objects. No scope bone, no
  attachment object - scope geometry is a mesh part under the customization
  components. Lens mount design: `Body` joint + calibrated offset;
  `vfx_muzzle` = barrel axis for bore-sighting.
- **Architecture confirmed:** the plugin init param includes the full native
  reflection SDK (`->sdk`) - no Lua bridge needed; ships as one DLL.

Next: "lens rides the rifle" - native camera/joint resolution + projection
driving the composite viewport per frame (flat screen first), then aim-point
crop centering, then VR eye-texture composite + FOV suppression + GUIScope
hide.
