# Engine dossier — Resident Evil Village sniper scope (RE Engine + REFramework)

The distilled technical reference for building a real VR sniper scope in
Resident Evil Village. Everything here was established by live probing on
2026-08-22 (methods in the
[dev archive](https://github.com/TefMeister/re-village-scope-vr/tree/main/dev-archive))
or verified against REFramework's published sources and documentation.

## 1. The game and the framework

- **Game:** Resident Evil Village (`re8.exe`), Capcom RE Engine.
- **VR:** praydog's [REFramework](https://github.com/praydog/REFramework)
  native VR (no separate VR mod needed for RE8); injection via `dinput8.dll`.
- **Log file:** `re2_framework_log.txt` in the game root — REFramework uses
  that filename even for RE Village.
- **Scripting:** REFramework Lua (reflection over the managed type system,
  hooks, 2D drawing/ImGui). **No render-target, camera-creation, or
  render-pass API exists in Lua** — render infrastructure is native-only.

## 2. How the flat game implements the sniper scope

Two pieces, both confirmed live:

1. **Magnification = main-camera FOV zoom.** Aiming down the scope smoothly
   narrows the primary camera's FOV from ~63° to **24.37°** (~2.6×), and ramps
   it back on release. There is no second camera and no offscreen scope
   render — the whole frame is the "scope view."
2. **The scope look = `GUIScope`.** A GUI element with exactly three
   components — `via.Transform`, `via.gui.GUI`, `app.GUIScope` — drawn over
   the zoomed frame. It is a mask + reticle only: no render texture, no scene
   capture, no children.

Consequences for VR:

- A stereo headset view cannot adopt a fullscreen FOV zoom (wrong and
  sickening), so the magnification half of the trick is unusable as-is.
- REFramework's generic VR handling world-positions GUI elements along the aim
  ray, which turns the fullscreen mask into a giant floating plane — the
  well-known "huge flat screen with a crosshair" symptom.
- **Nothing exists to reuse:** a VR scope must create the magnified image
  itself.

Related engine facts:

- The equipped weapon is **its own GameObject**, not a component of the player
  (the player object carries body/motion/audio/physics components only). The
  scope-lens joint for mounting a picture-in-picture quad must be found on the
  weapon object.
- REFramework's `re8_vr.lua` already computes the true aim impact point via an
  async physics raycast (`via.physics.System.castRayAsync`) — the natural
  bore-sighting reference for a scope.

## 3. The REFramework native plugin API (what a scope plugin gets)

From the published SDK (`include/reframework/API.h`, v1.15.0, MIT):

- A plugin is a DLL in `reframework/plugins/` exporting
  `reframework_plugin_required_version(REFrameworkPluginVersion*)` and
  `reframework_plugin_initialize(const REFrameworkPluginInitializeParam*)`.
  **Plugins load at game start** — unlike Lua scripts, a script reset does not
  reload them.
- The initialize parameter provides:
  - `renderer_data` → `renderer_type` (`REFRAMEWORK_RENDERER_D3D11` /
    `D3D12`), `device`, `swapchain`, `command_queue` — everything needed to
    create GPU resources on the game's own device.
  - `functions` → callback registration: `on_present`,
    `on_pre_application_entry(name, cb)` / `on_post_application_entry`
    (module-entry boundaries such as `"BeginRendering"` / `"EndRendering"`),
    `on_device_reset` (recreate GPU resources here), `on_message`, ImGui frame
    hooks, `on_pre_gui_draw_element`, Lua-state lifecycle + lock/unlock, and
    `log_info/warn/error` into the framework log.

## 4. The VR scope design derived from all this

1. **Suppress the main-camera FOV zoom while scoped in VR** (Lua-reachable:
   the FOV is readable/writable on the primary camera; scoped state is
   detectable from `GUIScope` drawing or the FOV ramp itself).
2. **Hide the `GUIScope` mask in VR** (Lua-reachable:
   `on_pre_gui_draw_element` can suppress it, as REFramework already does for
   other elements).
3. **Render a magnified view to a texture** — the native plugin's job, on the
   device handed over at initialize. Two candidate routes, in test order:
   (a) drive the engine itself to render a second camera view (check for any
   latent second-camera path around the sniper first), else (b) a manual
   render pass. Note REFramework VR's "Single Frame Multipass" rendering
   technique when integrating.
4. **Composite the texture on a lens quad** at the weapon's scope joint,
   bore-sighted to the raycast impact point, only magnifying what the barrel
   actually points at.

Milestones: **M0** scaffold loads + callbacks fire → **M1** own a render
target and composite it visibly → **M2** magnified scene render into it →
**M3** lens quad + bore-sight + zoom suppression + mask hide in VR.

## 5. Probe technique notes (reusable)

- **Recon flat-screen first**: REFramework's VR handling is HMD-gated, so a
  monitor session shows the engine's native mechanism cleanly.
- **Hands-busy capture**: when inspecting a state that needs both hands on the
  controls (ADS), have the probe trigger its own dumps on the state transition
  (FOV threshold / element-draw recency), or on an armed timer — not on a UI
  click you cannot make.
- **Reflection gotcha**: a managed object's type name is
  `obj:get_type_definition():get_full_name()` — REFramework-native methods on
  the object. Routing them through `obj:call(...)` fails silently inside
  pcall guards.

## 6. Scene objects: spawning things that actually draw

- **Runtime GameObject assembly does NOT produce a drawable mesh in RE8.**
  `[verified-live 2026-08-28, n=1 — our own M18–M26 sessions]` A `via.render.Mesh` built by
  creating a GameObject and attaching components will not draw through any recipe we tried, up
  to and including EMV Engine's own constructor calls. This blocked Mirror pane control, the
  project's named linchpin. Negative record:
  `modding-notes/2026-08-28-rig-mesh-hunt-and-clean-camera-retest.md`.

- **✅ The working route is prefab instantiation.** `[verified-live 2026-08-29]`
  `via.Prefab` instance → `set_Path` → check `get_Exist` → `instantiate(via.vec3, via.Folder)`.
  The engine spawns the complete object through its own registration path, so it is **born
  visible** — no manual component wiring. Proven here by spawning a goat totem that hosts the
  mirror, with pitch and yaw provably steering the image.
  - Two constraints found live: it must run on the **game thread**, and the prefab must be a
    **non-item** prefab.

- **Public precedent agrees, and arrived independently.** `[reported, /gr 2026-08-29]` EMV
  Engine spawns `.pfb` prefabs in all games, and its README explicitly warns that component-list
  assembly "will not work well for complicated GameObjects… use via.Prefabs for those" — the
  same wall, documented publicly. **Note the order: our live result came first (2026-08-29) and
  the research corroborates it rather than having unblocked it.** Recorded this way so nobody
  re-opens a closed question. Research write-up:
  `external-research/topics/2026-08-29-runtime-mesh-spawning-via-prefab-instantiate.md`.

- **RE8 prefab paths worth keeping** `[reported, /gr 2026-08-29 — not yet spawned by us]`:
  - `environment/props/prefab/item/detailsearch/ri3042_detailsearch.pfb` — a spawnable
    standalone copy of the F2 rifle.
  - `movie/prefab/c22e500_00_mirror.pfb` — a Capcom-assembled cutscene mirror, worth dumping
    live as a reference recipe for how they build one.

- **Generalisable habit:** when an engine refuses hand-assembled objects, look for the path the
  engine uses on itself. Spawning through the game's own registration is not a workaround here;
  it is the supported route, and the hand-assembly attempt was the deviation.

## 7. Grading: the game's tone curve, and the scope's copy of it

- **Where the grading lives.** `via.render.ToneMapping` is a component on the MainCamera
  GameObject (`getComponent(System.Type)` with the runtime type, same pattern as everything else
  on that object). `get_EV` is the game's live light meter — 3.0 outdoors, ~2.0 in a dark
  interior, a smooth glide between `[verified-live 2026-08-30]` — and the compositor has read it
  every frame since 08-30 to drive its exposure (`knob × 0.4 × 2⁻ᴱⱽ` on the raw-HDR mirror path).

- **The game's curve is three-section, and its numbers are on disk.** `[measured 2026-08-30]`
  (`dev-archive/recon/2026-08-30-grading-ev-recon/gr-recon-log-extract.txt`):
  `UseTripleSectionTonemap = true`, `LinearSectionBegin = 0.22`, `LinearSectionLength = 0.40`,
  `SDRToe = 1.0`, `HDRToe = 1.33`, `Contrast = 1.0`, `MinWhitePoint = 5.6`, `MaxWhitePoint = 15.0`,
  `WhiteRange = 0.9`, `TonemapRange = 0.1`, `PreTonemapRange = 1.0`. Every one has a setter. The
  white-point fields **move with the zone**: `MinWhitePoint` 5.6 → 8.0 and `WhiteRange` 0.9 → 0.8
  going indoors, in the same session `[measured 2026-08-30]`.

- **Identification.** The vocabulary — triple section, linear section as *begin + length*, toe,
  shoulder to a white point — is Uchimura's GT tonemap (CEDEC 2017), and the live values
  0.22 / 0.40 / 1.33 / 1.0 are that curve's **published defaults to the digit** (m, l, c, a).
  `[inferred-static 2026-09-03]` — a strong fingerprint, but the engine's algebra has not been
  read; `SDRToe`/`HDRToe`/`WhiteRange`/`TonemapRange` do not map one-to-one onto the published
  parameter list. Nothing built here depends on the identification, only on the measured shape.

- **In GT, the straight section spans `m .. m + (P − m)·l / a` = 0.22 → 0.532 for these values,
  not 0.22 → 0.62** — the "length" is a fraction of the headroom, not an absolute.
  `[verified-numerically 2026-09-03]` for our implementation; the game's own span is inferred.

- **The scope now uses this curve** (`staging 87efe59`, `plugin/src/tone_curve.inc`, build of
  2026-09-03, `[compile-verified 2026-09-03]`, **not run**): the raw-HDR path tonemaps with GT
  (P = 1, no pedestal) on the exposed value, with `m`, `l`, toe and contrast **read live from the
  same component at ~2 Hz** and logged on every change; numpad 5 cycles GT / exponential /
  exponential-with-EV-frozen so the old `1-exp` look stays one press away, each with its own knob.
  Details and the first-look protocol: `modding-notes/2026-09-03-tone-curve-gt-shoulder.md`.

- **What the curve alone will and will not do** `[verified-numerically 2026-09-03]`: at the
  same knob GT is brighter in the mids (x′ 0.4 → 0.400 vs 0.330) and clips the top *harder*
  (raw 500 at the 09-02 knob → 0.999 vs 0.965). The snow comes back only when the knob comes
  down; the straight middle is what should let the village survive that. Whether it does is
  the open test. The mirror render has no atmosphere pass (§ the 08-31 finding: black sky,
  sun-only light), so its dynamic range is plausibly wider than the game view's and a global
  curve may not close the gap by itself `[hypothesis]`.

- **Open, each with a knob or a log line waiting for it:** which toe the game uses (chosen from
  the swapchain format, logged at init, `[hypothesis]`); whether `Contrast` is GT's `a`
  (`[hypothesis]`, harmless at 1.0); what the three white-point fields do (`tone_wp=1` in the
  settings file applies `MinWhitePoint / 5.6` as an input divisor, off by default, `[hypothesis]`
  on the direction alone).

- **Correction to the 2026-09-02 board row.** "Above ~25 raw = flat white at exposure 0.134"
  treated the knob as the effective exposure; the effective value is `0.134 × 0.4 × 2⁻³ = 0.0067`
  at EV 3, so flat white starts at raw ≈ 480. The defect is real (screenshots); the threshold was
  ~20× off.

- **Method worth keeping:** the curve is *one file compiled twice* — `#include`d as C++ for the
  CPU-side inverse and read by CMake into a raw-string header prepended to the HLSL — so the
  numeric harness (`plugin/tools/tone_curve_check.cpp`) tests the bytes the shader runs, and
  `plugin/tools/check-shader.sh` runs `fxc` over the assembled source so a runtime-compiled shader
  is checked without the game. Both are how a `/pd` session can touch shader code at all.
