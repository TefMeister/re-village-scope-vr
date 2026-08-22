# Recon session 2026-08-22 — sniper scope mechanism + M0 plugin scaffold

Flat-monitor session (home PC, no headset). Probe: `re8_scope_recon_probe.lua`
(v3 included in this folder). Log source: `re2_framework_log.txt` in the game
root (REFramework uses that filename even for RE Village).

## Probe iterations (what changed and why)

- **v1** — GUI element collector (gated on HMD active), per-frame FOV watch,
  button-triggered player/weapon dump. Two faults found from its own output:
  the GUI collector never fired flat (HMD gate — removed, flat is the *better*
  recon condition since REFramework's VR scope handling is HMD-gated and stays
  out of the way), and a log-reading mistake on our side (element names log at
  first sight, early in the session — `tail` on the log missed them).
- **v2** — fixed the silent component dump: managed-object type names come from
  `obj:get_type_definition():get_full_name()` (REFramework-native methods on the
  object), **not** `obj:call("get_type_definition")` — the reflected call fails
  silently under pcall, yielding counts with no names. Added a one-shot GUIScope
  structure dump (components + transform children).
- **v3** — hands-free capture: you cannot hold ADS and click debug UI, so the
  weapon dump auto-fires the first time the scope is detected active
  (`FOV < 45°` or `GUIScope` drawn within 0.3 s), plus an "arm timed dump"
  button giving a 10 s window. This is the version that produced the results.

## Raw findings

### FOV (primary camera, `get_FOV`)
- Normal play: **~63.00°** (max observed).
- Scoped: smooth ramp down to **24.37°** (min observed, repeatable exactly),
  smooth ramp back on release. Intermediate stops observed near ~39° and ~51°
  during transitions.
- Magnification therefore ≈ 63/24.37 ≈ **2.6×**, applied to the MAIN camera.

### GUI elements (drawn while raising the scope)
- `GUIScope` — the only scope-related element; appears the moment the scope
  comes up. Reticle names from praydog's RE8 script (`ReticleGUI`, etc.) also
  present in normal play.

### GUIScope structure (one-shot dump)
```
gs-comp: via.Transform
gs-comp: via.gui.GUI
gs-comp: app.GUIScope
```
No render-texture/scene-capture component, no children logged. It is a mask +
reticle overlay only.

### Player GameObject (65 components, dumped while scoped)
Body/motion/audio/physics components only (`app.PlayerUpdaterFPS`,
`via.motion.Motion`, `app.MoveController`, Wwise components, ragdoll, etc.).
**No equipment/weapon-holder component on the player** — the equipped rifle is
a separate GameObject; its scope-lens joint is a future recon step.

## Conclusion locked by this session

The game has **no separate scope render**. Scope = main-camera FOV zoom +
`GUIScope` mask. A real VR scope must therefore create its own magnified
render-to-texture — which REFramework's **Lua API cannot do** (no render
target/camera/render-pass functions; verified against the REFramework Book).
Path chosen: **native C++ REFramework plugin**.

## M0 scaffold (same session)

- Project: CMake, VS2022 x64 Release, C++17. Vendored published SDK headers
  `include/reframework/API.h` + `API.hpp` (v1.15.0, MIT, praydog). All plugin
  code written from scratch.
- Exports `reframework_plugin_required_version` + `reframework_plugin_initialize`;
  registers `on_present`, `on_device_reset`,
  `on_pre_application_entry("BeginRendering")`; logs renderer type
  (D3D11/D3D12) + device/swapchain/command-queue pointers at init, and one-shot
  "first fire" markers from each callback.
- Compiled first try; deployed to `<game>\reframework\plugins\re_scope_vr.dll`.
- **Verification pending:** native plugins load at game start (a script reset
  is not enough). Expected log markers: `M0 scaffold loaded (renderer=…)`,
  `first on_present fired`, `first BeginRendering entry observed`.

## Leads for M2 (the magnified render)

- REFramework VR has a "Rendering Technique → Single Frame Multipass" mode —
  interaction with an extra pass needs checking.
- Prior art elsewhere uses a second camera enabled only when the eye is near
  the scope (performance). Worth probing whether RE Engine's sniper has any
  latent second-camera path before building a manual pass.
