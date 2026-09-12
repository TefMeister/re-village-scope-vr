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
- **REFramework revision actually run** (recorded 2026-09-04 after a `/gr` drop pointed out it
  was missing; read from the log header, `[verified-live 2026-09-04, n=1 log read]`):
  - **Home PC:** commit `76298bd9796b2b32e67133ff0360a7993c2e1482`, tag `v1.5.9.1` + 671
    commits, branch **`pd-upscaler`** (gmankab's fork), build date **2026-03-11**, `dinput8.dll`
    22,825,472 B dated 2026-08-22 — the **same fork build the sibling `visceral-re2-vr` runs**.
    Plugin API exported: **1.15.0** (`re_scope_vr requires version 1.15.0` accepted).
  - **Dev PC:** REFramework **nightly 01397** (`684ca77`, 2026-08-20) per the 2026-08-24 setup
    note — a different build; results from the two machines are results about two frameworks.
  - This build predates the 2026-08-19 → 2026-08-28 window in which `re.on_pre_gui_draw_element`
    ignored `false`, and predates September's Lua array/string fixes on `master`. **Record the
    revision beside every Lua finding from now on** (one clause, the way a game patch is recorded).
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


### 7x. Field result, 2026-09-04: the GT curve alone matches the game; the atmosphere package is retired

`[verified-live 2026-09-04, n=2 outdoor spots]` With the compositor on the game's own three-section
curve (parameters read live: m=0.220, l=0.400, white point applied) at the 0.134 knob and the
**atmosphere package OFF**, the scope matched the game at the village well and at the mountain
view: snow textured, village "about the same", sky "looks like it should" (screenshot pair in
`dev-archive/recon/2026-09-04-gt-curve-sky-package-off/`). The package — sky fill, threshold
ladder, white balance — was what blew the snow to flat white: across a 20× exposure sweep the snow
did not change, the `+` probe showed finite source values (blocks 1.5–18.5, pixel max 136) and a
compositor output max of 0.69, and switching the package off made the snow "go dark". Why its
below-threshold sky mask reached raw-18 snow is not understood `[hypothesis: another brightening
term in the package]`. **Keep the package off; treat the black-dome problem it was built for as
solved by the curve until a spot proves otherwise.** Aspect fix of 2026-09-02 also verified the
same evening (well square, reticle square with no reticle code touched); scope zeroed at
`cropY = 0.60`; the crop centre now has a horizontal key (numpad 4/6) and 0.01 steps.


## 8. The mirror in the headset: what the eye does to the picture (2026-09-05)

Source: `modding-notes/2026-09-05c-the-headset-says-steering-off-on-axis-is-right.md`; evidence
`dev-archive/recon/2026-09-05-vr-model-test/`.

- **The flat-tuned rig pose and zero are correct in VR for the on-axis eye.** Steering OFF, scope
  centred in the view, eye behind the eyepiece: scene ahead, right way up, shots land near the
  reticle. `[verified-live 2026-09-05, n=1 scene]`
- **The picture is eye-dependent.** Leaning the head sideways with the rifle still shifts the
  content. `[verified-live 2026-09-05, n=1]` So the mirror does reflect relative to the viewer,
  and a per-frame plane correction is needed — but see the next point for its shape.
- **Deriving the plane from scratch per frame is wrong.** Both `n = normalize(v − d)` (eye→mirror
  ray) and `n = normalize(f − d)` (camera forward) were tried in the headset; both showed the
  jacket off-axis, and the first turned a correct on-axis picture upside down and away.
  `[disproved 2026-09-05, n=1 each]` On-axis these formulas have v ≈ d, so n is a small-difference
  vector nearly perpendicular to the bore — a large rotation applied exactly where none is needed.
  The correction must be relative to the baked pose and the identity on-axis; the proposed law is
  a half-angle slerp of `shortest_arc(bore, eye→mirror)` with the sign as a knob `[hypothesis]`.
  Dead end recorded so it is not re-derived: any steering that ignores the baked pose.
- **The crop is the second cause of a wrong picture off-axis.** The compositor samples a fixed
  point of the mirror RT (`mir_cx/mir_cy`); the plugin's aim pixel is the view centre in flat ADS
  (`(960,541)`, 15 samples) and far from it in VR (`(302..1400, 870..1190)`)
  `[measured 2026-09-05]`. Centring the scope in the view cleared the jacket `[verified-live, n=1]`.
  In VR the aim pixel exceeds 1080 vertically, so the projection space of the aim pixel — and of
  the mirror RT itself under the VR camera — is not the desktop frame and is not yet identified.
- **The lens material simulates an exit pupil.** Off-axis the visible disc shrinks and slides and
  the slot-1 picture is shifted and scaled with view angle; `EyeDistortionRange` reads back 0.100
  under every write (both lens materials, two launches) `[verified-live 2026-09-05, n=2]`. That it
  is the game's own effect rather than ours is `[hypothesis]` — nothing in our shaders draws a
  hole that changes size, but the 2026-09-04 pre-steering run was not checked for it.
- **Two facts about the VR session itself:** the desktop window does not repaint in VR mode, so
  BitBlt captures are static and the REFramework log is the only oracle
  `[verified-live 2026-09-05, n=1 launch]`; the 1920×1080 movie `.rtex` is accepted as the mirror
  RT and the plugin latches the 1920×1088 raw-HDR allocation `[verified-live 2026-09-05, n=2]`.
- **Texture identity:** `getMaterialTexture` returns a `via.render.TextureResourceHolder` wrapper
  with none of `get_Resource / getResource / get_ResourceHolder / get_Texture / getTexture /
  get_Handle / get_NativeResource`, and a fresh wrapper per call `[verified-live 2026-09-05, n=2]`.
  A bind-order guard cannot be built on wrapper pointers; it is disabled.

### 8a. Model 2, and two corrections to the readings above (`/pd`, 2026-09-05 afternoon, static)

Source: `modding-notes/2026-09-05d-model-2-is-built-and-the-eye-box-may-not-need-a-hunt.md`; code
`staging/re-village-scope-vr` `2a3ec1f`.

- **The steering correction now has a form that is the identity on-axis, and that property is
  proved rather than intended.** `corr = slerp(identity, shortest_arc(bore, eye→mirror), k)` applied
  on top of the baked pose. `[verified-numerically 2026-09-05, 71 checks against the shipped text]`
  — on-axis the returned rotation equals the baked one to 1e-9; the plane turns by exactly
  `k × angle(bore, eye-ray)`; `+k` and `−k` are exact opposites; degenerate and antiparallel inputs
  are refused rather than propagated. Test: `scripts/tests/steer_corr_test.lua`, which slices and
  runs the shipped text, not a transcription.
- **Why `k = 0.5`, checked independently of our own code:** a plain reflection formula confirms a
  mirror swings the reflected ray by **twice** the plane's rotation (six angles, to 1e-4)
  `[verified-numerically 2026-09-05]`. So to swing the view by the eye's angular offset, turn the
  plane by half of it. **The magnitude is theory; the SIGN is not derivable and is a knob**
  (`steerk`).
- **⚠️ Correction — an aim pixel above the frame height is NOT evidence of a second projection
  space.** §8 records the VR aim values (up to `(302,1188)` against a 1080-high frame) as meaning
  "the projection space is not the desktop frame". The plugin's own `project()` accepts normalised
  coordinates out to ±2 before refusing a point, so its output legitimately spans about −0.5·bh to
  1.5·bh. Running the logged VR values back through that formula against a 1920×1080 frame:
  `(302,1188)` is `nx=−0.685, ny=−1.200` — inside horizontally, a fifth of a frame below the bottom
  edge — and `(1400,1007)` is `nx=+0.458, ny=−0.865`, **entirely inside the frame**
  `[verified-numerically 2026-09-05, n=3]`. Nothing observed requires a second projection space. The narrower open question that survives is whether the aim pixel's
  frame and the **mirror RT's UV frame** agree — they demonstrably do on the backbuffer path. The
  world log line now carries `proj=WxH` so this is readable rather than arguable.
- **⚠️ Correction — the eye-box may have no writer to find.** §8 reads `EyeDistortionRange → 0.000
  reads back 0.100` as the game re-asserting the value, and queues a hunt for the writer. The
  plugin's own older comment beside that write reads the same number as a **min clamp at 0.1**. Both
  are consistent with every observation so far, because every observation so far is that single
  value. A three-value ladder now runs at bind time and separates them on any launch:
  `0.500→0.500` with `0.050→0.100` is a clamp (**no writer exists**; cancel the hunt); `0.500→0.100`
  is re-assertion (fix is a per-frame **hold**, the pattern already in this file for
  `Reticle_Emissive`); `0.500→0.500` with `0.050→0.050` means something later in the frame
  overwrites it, and only then is finding the writer the right step.
- **The plane-to-view sign is measured: pitching the mirror plane +5° swings the view DOWN.**
  Re-measured from the 2026-09-05 flat sweep's own captures, monotonic across +5 to +25°, with no
  sky ever entering the disc `[measured 2026-09-05, n=6 frames]`. The yaw series is a genuine null
  control — every yaw frame is the *same picture* as the baseline at 100 % patch consensus — which
  **independently re-confirms that the plane's normal is local Y** and proves the measurement finds a
  match when one exists. ⚠️ This settles the physics, **not** the sign of `steer_k`: that also needs
  how `shortest_arc`'s direction in the rig's local frame maps onto the harness `pitch` axis, which
  is unmeasured.
- **The gain is far higher than a slope fit can capture: each 5° of plane pitch replaces the picture
  outright, i.e. > ~60 px/deg** `[measured 2026-09-05]`. Phase correlation validated to 0.01 px on
  synthetic shifts and to a ~300 px ceiling on a real re-rendered frame still finds 0–3 % patch
  agreement on the pitch steps. Consequence for tuning: **if model 2 overshoots in the headset, read
  it as excess gain and walk `steerk` down (0.1, 0.05) before doubting the model.** A 0.5° sweep is
  what would give a number.
- **Pitching the plane also ROLLS the picture** — the scene texture's dominant edge direction turns
  ~1.68° per degree of plane pitch `[measured 2026-09-05]`, which a pure pitch should not do.
  Consistent with the earlier flat-sweep observation and with `roll_k` existing.
- **⚠️ Instrument trap, recorded because it produced a confident wrong answer:** correlating the whole
  scope disc without masking the reticle makes the correlator **lock onto the static crosshair and
  report a near-zero shift with high apparent confidence.** Any image measurement on this glass must
  mask crosshair, bezel and the inner dark sub-disc first. The weapon also idles, drifting the whole
  scope 3.6–17.1 px between captures — a ±13 px noise floor independent of any commanded angle.
- **`crop_follow`** (settings key, default 0) makes the mirror crop centre the aim pixel, with
  `mir_cx`/`mir_cy` re-read as a delta from 0.5. The sampled window is clamped inside the source
  unconditionally, so a wrong frame mis-aims but cannot sample out of bounds.
- **Practical trap worth keeping:** a deployed script diffed against its repo copy can differ on
  **every line** and still be content-identical — CRLF versus LF. That is also what a lost-work
  collision looks like, and the two are one `tr -d '\r'` apart. Normalise before concluding.

### 8b. The steering was fed a 35-degree lie (flat launch, 2026-09-05 evening)

Source: `modding-notes/2026-09-05e-the-flat-control-failed-and-named-the-shared-root-cause.md`;
evidence `dev-archive/recon/2026-09-05e-flat-control-and-eyebox-ladder/`.

- **⭐ The eye→mirror ray every steering model uses points at the rig's PARKED PLACEMENT, not at the
  scope glass — and that placement is 35 degrees off the bore by construction.** In flat ADS, where
  the plugin's own anchor reads `local=(0.00,0.00,-0.22)` and the aim pixel is dead centre, model 2
  still computed `arc=35.3 deg` and rotated the plane 17.6 degrees, replacing the picture entirely
  `[verified-live 2026-09-05, n=1]`. The pane is parked at `fwd=1.000 right=-0.715`, and
  `atan(0.715/1.0) = 35.56 deg`; recomputing the angle between the two vectors the plugin printed
  gives `35.27 deg` `[verified-numerically 2026-09-05]`. **The arc is the parked offset, in full.**
- **This is the shared root cause of all three models, and it is upstream of every imaging
  assumption.** The two models disproved in the headset on 2026-09-05 also derive their direction
  from `mirror_pos`. That session read the failures as "the imaging model is wrong"; the model was
  never reached. **Dead end recorded: do not judge a steering model while `v` is measured to the
  parked rig.** The fix is to aim `v` at the lens anchor the plugin already tracks, which genuinely
  sits on the bore in ADS.
- **⭐ `EyeDistortionRange` does NOT min-clamp.** The ladder returned `0.500->0.100  0.050->0.100
  0.000->0.100` on **both** lens materials `[verified-live 2026-09-05, n=2 materials]`. A clamp at
  0.1 would have passed 0.5 through, so the long-standing "min-clamps to 0.1, fine" comment is
  `[disproved 2026-09-05]`. Two readings survive and the ladder does not separate them: the game
  re-asserts the value every frame, or **the write never lands** — the likelier one, since
  `set_material_float_verified` tries several encodings and reports failure. **Discriminator: hold
  it at frame rate for a second and read back.** Either way the hunt for a writer stays cancelled.
- **✅ An aim/anchor pixel outside the frame is a point outside the frustum, not a second projection
  space.** First gameplay line of a FLAT launch: `px=(1983,1481) ... proj=1920x1080`
  `[verified-live 2026-09-05, n=1]`. The 2026-09-05 morning reading is `[disproved]`.
- **⚠️ Measurement hygiene on this glass — third instance, now a rule.** Any image measurement here
  must be masked to the scope disc itself. Masks built from "high variance" lock onto the animated
  world OUTSIDE the scope, which does not move with the plane, and return a confident `(0,0)` with a
  peak/rms near 500. **Whole-frame mean-abs is worse than useless**: the model-2 test, whose frames
  differ unmistakably by eye, scores 14.6 against a same-state noise floor of 10.0. Prefer a large
  unmistakable action and look at it — a 40-degree pitch step settled in one move what two
  correlators could not.
- **The pitch slider does reach the rig**: `rq=(-0.05,0.34,0.94,0.02)` at pitch 220 against
  `(-0.05,0.00,1.00,0.00)` at 180 `[verified-live 2026-09-05, n=1]`.
- **Launch trap:** `start steam://rungameid/1196590` issued while Steam is still starting produces no
  process and no log growth at all — silently. Steam must already be up.

### 8c. The measurement bug behind three wrong answers, and a withdrawn bound (2026-09-05 evening, `/pd`)

Source: `modding-notes/2026-09-05f-the-mask-was-the-bug-and-the-sweep-cannot-give-a-gain.md`;
validated script and results in `dev-archive/recon/2026-09-05e-flat-control-and-eyebox-ladder/`.

- **⚠⚠ A BINARY MASK MAKES PHASE CORRELATION LIE, CONFIDENTLY.** A hard-edged annulus has enormous
  energy at its own rim; after high-passing, that rim is the strongest feature in both images and is
  in the same place in both, so the correlator locks onto the mask and returns exactly `(0,0)` with a
  peak/rms around 500. **That is what produced every "the picture did not move" result on this glass
  today.** `[verified-numerically 2026-09-05]` Use a **smooth raised-cosine taper in radius** instead.
- **The control that catches it, and the only thing that did:** roll the baseline by a known offset
  and require the pipeline to recover it before believing anything else. Hard mask recovered
  `(0,0)`; the taper recovered `(-23,+17)` exactly, and pinned the sign convention as a bonus.
  **Every image measurement here should carry that control.**
- **⚠️ WITHDRAWN: the `> ~60 px/deg` lower bound** recorded from the 5° sweep is downgraded to
  `[hypothesis]`. It rested on the correlator finding 0–3 % patch agreement — a correlation
  *failure* — and a correlation failure on this glass can be a masking artefact. What survives from
  that session is the part read **by eye**: the view swings DOWN as the plane pitches up, from the
  monotonic ordering of six frames against a flat yaw null control `[measured 2026-09-05]`.
- **The noise floor on this rig is ±26 px, and it is the weapon's idle sway.** Two frames at the
  *same* pitch, seconds apart, differ by up to `dy = -26`. Over 2.5° of plane pitch the picture moves
  less than that, so **the fitted slopes (dx -3.5, dy +4.9 px/deg) have residual rms of 7.0 and 6.0 px
  — larger than the change across the whole sweep** `[measured 2026-09-05]`. A gain measurement here
  needs a much larger step with landmark tracking, or the idle suppressed.

### 8d. Both fixes run: the eye-box is closed, and the steering ray has a measured target (2026-09-05, `/lm`)

Source: `modding-notes/2026-09-05g-both-fixes-run-one-answered-one-was-aimed-at-the-wrong-thing.md`;
evidence `dev-archive/recon/2026-09-05g-both-fixes-run/`.

- **⭐ `EyeDistortionRange` CANNOT BE WRITTEN through `setMaterialFloat`, and that is now settled
  rather than suspected.** Holding `0.5` at frame rate for ~1.5 s reads back **`0.100`** on both lens
  materials — exactly what writing it once did `[verified-live 2026-09-05, n=2 materials]`. The
  ladder had already killed the min-clamp reading; this kills re-assertion, because **a per-frame
  writer would have lost the race against a per-frame hold and it did not.** The variable is
  read-only through this API, driven from somewhere the material does not expose, or we are writing
  an instance the renderer never samples. **There is no writer to hunt** — the row is closed, and the
  eye-box has to be approached another way (or lived with) if it matters.
- **⭐ The steering ray now has a MEASURED target, not a guessed one.** On-axis in flat ADS, the angle
  between the bore and the eye→target ray, for the three candidates tried:

  | ray aimed at | angle from the bore |
  | --- | --- |
  | the rig's parked position | **35.3°** |
  | the rifle transform's origin | **50.1°** |
  | **the plugin's lens anchor (its `joint=` field)** | **3.9°** |

  `[verified-live 2026-09-05, n=1]` / `[verified-numerically 2026-09-05]`. The rifle transform origin
  is the weapon ROOT, down at the grip — `eye→mirror` came out as `(0.64,-0.77,0.07)`, steeply
  downward. **The lens anchor is the only one that is on-axis when the scope is**, and its 3.9°
  residual is honest: the scope sits a few centimetres above the barrel.
  ⚠️ The Lua has no route to that position today; the plugin computes it every frame from the
  weapon's Body joint plus the mount calibration. Publishing it is the next step.
- **The cheap on-axis flat control has now caught two wrong steering models in one day**, each of
  which looked entirely plausible in code, and neither reached a headset. Keep it as the gate in
  front of every steering change: flat ADS is on-axis, so a correct correction must do **nothing**
  there, and any implementation that does something is wrong before comfort or feel is even a
  question.

### 8e. The flat control passes: the steering ray is on the scope (2026-09-05 evening, `/lm`)

Source: `modding-notes/2026-09-05h-the-flat-control-passes-at-last.md`; evidence
`dev-archive/recon/2026-09-05h-the-control-passes/`.

- **⭐⭐ The lens anchor is the weapon's `Body` joint plus the mount offset `(0, 0.151, 0.099)` in that
  joint's own frame**, and the Lua can compute it directly — no channel from the plugin is needed.
  With the ray aimed there, on-axis in flat ADS: **`arc = 0.7 deg`, applied `0.3 deg`, picture
  unchanged** `[verified-live 2026-09-05, n=1 launch, 12 consecutive steer lines under 1 deg]`.
- **The full progression, all measured on-axis**, is the useful record:

  | ray aimed at | arc from the bore | picture |
  | --- | --- | --- |
  | the rig's parked position | 35.3° | replaced |
  | the rifle transform's root (the grip) | 50.1° | replaced, worse |
  | **Body joint + mount offset** | **0.7°** | **unchanged** |

- **⚠️ What passing does NOT establish.** On-axis is exactly the case where every value of `k`
  behaves identically, so `k = 0.5`, its sign and the half-angle law remain untested. The control
  proves the implementation is sound, not that the model is right.
- **✅ `EyeDistortionRange` cannot be written through `setMaterialFloat` — now n=2 launches.** A
  1.5 s frame-rate hold reads back `0.100` on both lens materials on both runs
  `[verified-live 2026-09-05, n=2 launches, n=2 materials]`.
- **The on-axis flat control has now caught two wrong rays and confirmed the third, in one day, for
  the cost of three flat launches and no headset time.** Keep it as the gate in front of every
  steering change.

## 9. The shipped `.rtex` inventory, and the one named `mirror_env` (`/gr` drop, drained 2026-09-05)

From Ekey's public `RE8_STM_Release.list` path listing — path strings only, no game content read or
redistributed. Source: `external-research/topics/2026-09-05-the-1920-rtex-path-is-confirmed-and-the-shipped-inventory-holds-a-mirror-env-target.md`.

- **`natives/stm/movie/rtex/movie_1920_1080.rtex.5` exists** `[verified-live 2026-09-05, n=1 file
  read of the release list]` — the path the plugin guesses was a guess no longer. Our own runs had
  already confirmed it end to end (`mirror RT: using movie/rtex/movie_1920_1080.rtex`, no fallback,
  latched at 1920×1088, `[verified-live 2026-09-05, n=2]`), so this arrives as corroboration rather
  than news. It still buys one thing: **a future 1280 fallback in that log line now means the
  request or the latch failed, never a missing file.**
- **⚠️ Corrected inventory.** An earlier note recorded "~30 entries incl. 1920×1080". Actual shape
  `[verified-live 2026-09-05]`: **56** `.rtex` entries, of which only **five** are generic
  size-named `movie/rtex` targets — 650×850, 1144×1048, 1170×784, 1280×720, **1920×1080**. The
  other 51 are purpose-built. **There is no 2048, 2560 or 4096 `.rtex` anywhere in the game.**
- **So borrowing a bigger shipped target is exhausted at 1920×1080.** Any further resolution step
  would have to *create* a target, which is the unsolved `⛔ RT GPU BACKING` problem again.
- **If 1920 still looks mushy, try `movie/rtex/movie_1144_1048.rtex` before concluding anything**
  `[inferred-static 2026-09-05]`: the scope picture is a circle, and a 16:9 target spends most of
  its pixels outside it. 1144×1048 inscribes a ~1048 px circle against 1920×1080's ~1080 — near
  identical detail from **half** the pixels. Assumes the latch tolerates a near-square source.
- **🔭 `natives/stm/mastermaterial/textures/rendertarget/mirror_env.rtex.5` — a shipped,
  engine-owned render target named for mirror rendering.** The reopened `via.render.Mirror`
  candidate's stated weak point is that binding a render target *we* create shows nothing —
  "backing needs pipeline registration not yet found" (2026-08-24). A target the engine already
  registers is exactly the trick that made the movie `.rtex` route work, now pointed at the lead
  that most needs it. **`[hypothesis]`, deliberately:** the name may denote a static environment
  texture rather than a live Mirror output, and the six `systems/rendering/{xn,xp,yn,yp,zn,zp}.rtex`
  cube faces in the same inventory are a reminder this engine does static environment capture too.
  **One reflection read of its type, dimensions and flags settles which** — the same check that
  proved the 728×1280 `R8G8B8A8_UNORM_SRGB` / `RENDER_TARGET` backing on 2026-08-24.

Credit: **Ekey**, REE.PAK.Tool.

### 9a. The instrument for that question is built, and what it cannot see (2026-09-05 evening, `/lm`, static)

`fn probe_rtex` in the producer reads `mirror_env.rtex`, the six `systems/rendering` cube faces and
both movie targets through reflection, and reports type, dimensions and format to the log.
`[compile-verified 2026-09-05]` — built, deployed, **not yet run**.

- **It enumerates the type's zero-argument value getters rather than guessing accessor names.** The
  guessing approach returned "all seven candidate accessors absent" on
  `via.render.TextureResourceHolder` the same day — a result that describes the guess, not the
  object. Only value-type and string returns are called: a primitive getter is a field read, an
  object getter may construct, and `pcall` does not catch an access violation.
- **`movie_1280_720` is read last as a CONTROL**, against its known descriptor — 1280×728,
  `R8G8B8A8_UNORM_SRGB`, `ALLOW_RENDER_TARGET` `[verified-live 2026-08-24]`. A wrong control voids
  every negative in the same run. This is the habit that caught three wrong answers earlier today.
- **⚠️ The `RENDER_TARGET` flag is NOT readable this way, and must not be reported as absent.** It
  lives on the D3D12 allocation; only the plugin's `CreateCommittedResource` hook (F6) sees it. An
  **engine-owned** resource that is already resident allocates nothing on `create_resource`, so F6
  sees nothing either. **Dimensions and format are the honest discriminator**: screen-shaped 2D =
  the Mirror lead alive; small square matching the cube faces = static environment capture, lead
  dies.
- **Path form:** the release list writes `<path>.rtex.5`; the `.5` is the resource version and
  `create_resource` does not take it. The working `movie_1280_720` path settles the un-suffixed form
  `[verified-live 2026-09-05]`.
- The **by-eye** version of the same question (SC — cycle candidate engine textures onto the glass)
  existed since 2026-08-29 but was **a REFramework panel button only**, unreachable from a driven
  session. Now published as `fn sc_next`. General lesson worth keeping: **anything reachable only
  from the panel is invisible to a session with nobody at the mouse, and nothing errors to say so.**

### 9b. Borrowing a bigger target is exhausted, and the near-square idea is not free

`fn rtex_1920` / `fn rtex_1280` reorder the existing candidate list so the "is 1920 actually
sharper?" judgement happens **inside one launch** `[compile-verified 2026-09-05]`. Both are 16:9 and
both already pass `looks_like_mirror_target`, so the aspect path and the latch are untouched.

**⚠️ `movie_1144_1048.rtex` was deliberately left out.** The arithmetic is attractive — a circular
scope picture wastes most of a 16:9 target, and 1144×1048 inscribes a ~1048 px circle against
1920×1080's ~1080, near-identical detail from half the pixels `[inferred-static 2026-09-05]`. But it
is **near-square, and both `st.aspect_val` and the latch's size window are written around 16:9**.
Adopting it is a change to the working display path, not a resolution knob, and it needs its own
session with its own control.

### 9c. The latch was matching on width alone, and `mirror_env` resolves (2026-09-05 late, `/lm`, one flat launch)

Notes: `modding-notes/2026-09-05j-one-flat-launch-the-latch-was-matching-on-width-alone.md`.

- **⚠️ The mirror-source latch grabbed an engine HDR intermediate instead of our movie target.** On
  the third and fourth rig rebuilds of one session it latched **1920×1088 fmt=26 flags=0x5**
  (`R11G11B10_FLOAT`, `ALLOW_RENDER_TARGET | ALLOW_UNORDERED_ACCESS`) and the scope went black;
  the first rebuild had latched **1920×1088 fmt=29 flags=0x1** and shown the world
  `[verified-live 2026-09-05, n=4 rebuilds, n=2 wrong]`. `looks_like_mirror_target` checked
  dimension, width, a height window and `ALLOW_RENDER_TARGET` — both allocations pass all four.
- **Measured discriminator:** every movie `.rtex` the engine has handed this project is
  **fmt=29 / flags=0x1 exactly** — 1280×728 (2026-08-24, and again today), 1920×1088 (today)
  `[verified-live, n=4 latches across 2 launches]`. The predicate now requires
  `DXGI_FORMAT_R8G8B8A8_UNORM_SRGB` and refuses `ALLOW_UNORDERED_ACCESS`; a movie target in another
  format yields **no latch line** rather than a black scope `[compile-verified 2026-09-05]`, unrun.
- **General shape worth keeping:** a latch that identifies by *measurement* is only as specific as
  the measurements it takes. Width + height + one flag was enough on the day it was written and
  stopped being enough the moment the engine allocated something the same size.
- **`mirror_env.rtex` resolves through `create_resource` and binds to the lens (2 slots)**
  `[verified-live, n=1]`. On the lens: warped environment imagery, sky above / terrain below, that
  changes with view direction `[verified-live, n=1]` — **not** a live-vs-static discriminator
  (a static cube map sampled as a reflection does the same). Dimensions/format still unread.
- **`sdk.find_type_definition("via.render.RenderTargetTextureResource")` returns nil** while
  `sdk.create_resource` resolves the same string `[verified-live, n=1]`. Resource types are not
  managed-TDB types on this build; take the type from the returned object.
- **The REFramework overlay cannot be clicked from outside**: hover registers, clicks do not, via
  `mouse_event` and `SendInput`+`MOUSEEVENTF_ABSOLUTE` `[disproved 2026-09-05, n=3 attempts]`.
  So a Lua edit costs a relaunch. A harness `reload` was rejected: re-executing the producer
  duplicates every `re.on_frame` registration.
- `EyeDistortionRange` read back 0.100 again on a fresh launch — `[verified-live, n=3 launches]`.

### 9d. The latch, corrected: `fmt=26` is wrong only as a FIRST source, and re-arm is a pending replacement (2026-09-05 late, `/lm`)

Supersedes: §9c, bullets 1–3 (the predicate-level format gate). Notes:
`modding-notes/2026-09-05k-the-fix-was-a-regression-and-the-record-said-so.md`.

- **§9c's fix was a regression.** The 2026-08-31 design latches the 8-bit `fmt=29` resolve and then
  **upgrades** to the `fmt=26` raw-HDR scene buffer when it allocates next (§7's GT grading tonemaps
  that HDR source). The upgrade line is in launch 1 tonight and in the headset run where the shots
  landed `[verified-live 2026-09-05, n=3 logs]`. A format gate inside `looks_like_mirror_target`
  refused the upgrade too; the gated launch ran on the SRGB resolve — the 08-31 "golden veil" — and
  its "good" picture was a whitened wash `[verified-live, n=1 launch]`.
- **Corrected:** the predicate is geometric; the hook decides "may this be a **first** source"
  (`fmt=29`, no UAV) `[verified-live, n=7 movie-target latches all fmt=29/0x1]`; the `fmt=26`
  **upgrade** branch is reachable again. As a *first* source `fmt=26` is a random HDR intermediate
  and shows black `[verified-live, n=2]`; as an upgrade it is the mirror's scene buffer.
- **Whether a rebuild allocates at all is not predictable from outside** — one process allocated
  1280 twice and 1920 once across six cycles `[verified-live, n=6]`. So numpad `.` no longer retires
  the source; it marks a replacement **pending** and the next acceptable allocation swaps in,
  otherwise the current picture stays. The HDR early-return yields to a pending re-arm.
  `[compile-verified 2026-09-05]`, unrun.
- **The boot latch is never ours:** `1920×1080 fmt=28` (`R8G8B8A8_UNORM`, exact 1080) fires before
  any rig exists `[verified-live, n=3 launches]`. The cold order's re-arm was displacing it.
- **Reticle square: green = mirror source latched, blue = none** `[verified-live, n=3]`.
- **Reflection cannot describe a resource on this build.** `create_resource` returns something
  with **no type definition** for all nine `.rtex` paths `[verified-live, n=1]`; yesterday the type
  *name* was unknown, today the *object* is. `mirror_env`'s descriptor needs the D3D12 route — the
  plugin's existing `CreateShaderResourceView` hook can `GetDesc()` the resource the lens samples.

### 9e. The corrected latch passes its control, and a target switch can strand it (2026-09-05 late, `/lm`, same flat launch resumed)

- **All three control readings of §9d pass in one process** `[verified-live 2026-09-05, n=1 each]`: the
  `fmt=29` first-source latch upgrades to `fmt=26` (21:39:25 at boot, 21:54:19 on the rebuild); `.` marks a
  pending replacement and the next acceptable allocation on the OTHER width replaces (`REPLACED on pending
  re-arm (1280-wide)` after a 1920-wide boot source); a rebuild that allocates nothing keeps the picture
  (green square, world in the glass). No cream-with-blue in the process. The 21:13 regression is closed.
- **Allocation happens on a target's FIRST use in the process and does not recur** `[verified-live
  2026-09-05, n=1 process]`: 1920 allocated at 21:48 (first rig, nothing pending — ignored by design),
  1280 at 21:54 (first use, pending — replaced); every later rebuild on either target logged
  `mirror RT: using` with no latch line. Consequence: **an allocation that lands with nothing pending is
  lost for the rest of the process.** The cold order therefore presses `.` BEFORE the first `fn p10` on each
  target that must be compared — the sharpness recipe in `status/`.
- **A width switch without an allocation strands the latch on a frozen buffer** `[verified-live
  2026-09-05, n=1]`: with the 1280 `fmt=26` buffer latched, a 1920 rig gave a still frame of Ethan's jacket
  (the lowered rifle's last view), unchanged under `dyaw 25`; a 1280 rig brought the live world straight
  back with no latch line. Reading: the engine's mirror HDR intermediate is **pooled by width**, so a
  same-width mirror writes the latched buffer and a different-width mirror does not `[hypothesis]`. Plugin
  change queued (`[PD]`): log + amber square when the rebuild width differs from the latched width and no
  allocation arrived; never auto-clear, because the same-width case recovers by itself.
- **The sky ladder is the whitening** `[measured 2026-09-05, n=1 sweep]`: sky-band mean 103 at atmo=0,
  132 at threshold 0.5, 192 at 8, 201 at 12, back to 110 at atmo=0; wb 0.0 throughout. Confirms §7's
  post-mortem shape and the 2026-09-04 decision to retire the package.
- **Flat vs VR is decided at launch:** `XR_ERROR_FORM_FACTOR_UNAVAILABLE` from the Virtual Desktop OpenXR
  runtime when the headset is not connected at process start; the run is then flat for its lifetime
  `[verified-live 2026-09-05, n=1]` (Tefa, same day: VR cannot be switched on mid-session).

### 9f. `via.render.Mirror` looks where the VIEWING camera looks; the pane sets only roll (2026-09-05 late, `/lm`, headset, three launches)

- **The mirror's reflected view direction belongs to the viewing camera, not to the plane.** With steering off,
  `dyaw 40` (rotation about the measured mirror normal, local Y) changed nothing in the glass; `dpitch 20` (about
  local X) rolled the image and moved its direction not at all that the eye could see; a steering rotation of
  60° (model 3, k=−2) changed nothing `[verified-live 2026-09-05, n=1 each, headset]`. In flat ADS the viewing
  camera is on the bore, which is why every flat steering control passed: the picture was on the bore because
  the camera was. In VR the viewing camera is the headset, so the scope picture is tied to the head.
- **Consequence:** steering the pane (models 0/1/2/3) cannot decouple the picture from the head; `[disproved
  2026-09-05]` as a VR lever. The pane's remaining job is roll (and the flat control). The lever is the CROP:
  the scope's content for a given head pose is a region of the head's reflected render. `crop_follow` is that
  lever; its mapping today uses the eye-projection aim pixel (2688×2880 in VR) against a 1920×1088 render
  and loses lock at the edges `[measured 2026-09-05, n=1]` — plugin work, game closed.
- **Model 3 (`ref`)** in the producer: reference ray captured at switch-on (identity there by construction),
  `anchor_reach` 0.35 m along the bore so a head lean is a small angle (the flat lens anchor sits at the VR eye;
  a lean swung the raw ray ~95°). Works as designed `[verified-live, n=3 captures]`; moot for VR by the finding
  above.
- **Latch notes:** after a Lua reload the recreated holder allocates and the upgrade grabbed a wrong `fmt=26`
  (black) `[n=1]` — a reload costs a relaunch; no boot latch in VR processes `[n=3]`; the 1280 target crops
  into the sky in VR `[n=1]`.

### 9g. The crop mapping is four candidates, and the 9f reading is stronger than its evidence (2026-09-06, `/pd`, static)

- **Two unknowns hid inside "project into the mirror's render".** (1) `via.render.Mirror`'s projection:
  either it shares the viewing camera's (then the 1920×1088 target holds the 0.933-aspect VR eye view
  **anamorphically**, and NDC maps 1:1 onto the texture), or it renders its own 16:9 projection at the same
  vertical FOV (1.9× wider horizontally). Flat cannot separate them (1920×1080 vs 1920×1088, 0.7 %); VR can.
  Tefa's "squashed vertically in VR" `[reported 2026-09-05, n=1]` is what the anamorphic reading predicts
  `[hypothesis]`. (2) Direct point or its reflection across the pane. For the BAKED pane these differ by
  under a degree at 50 m, because that pane is a **horizontal mirror ~0.2 m under the line of sight**
  (normal = the rifle's −Y; derived from the shipped sliders `fwd 1.0 / up −0.2 / right −0.715 / pitch 180 /
  yaw 90` through the Lua's own quaternion convention and, independently, rotation matrices —
  `plugin/tools/crop_follow_test.cpp` check 4 `[verified-numerically 2026-09-06]`).
- **Built:** `plugin/src/crop_follow_math.h` computes all four (`crop_mode` 0..3 = direct/reflected ×
  shared/16:9; default 2), the plugin holds the last good centre across a lock drop, logs the four with an
  `inside`/`OUT` flag once a second plus the bore's angle off the gaze, and cross-checks its pane against
  the one the Lua publishes (`agrees`/`DISAGREES`). The producer publishes sliders, pane normal, rigged
  `.rtex` width, a rebuild counter and a census counter through `reframework/data/re_scope_vr_pane.txt`;
  the harness switches `cropmode` / `cropfollow` / `aspectmode` live. 31-check suite green; nothing run.
- **Why 05n's `crop_follow=1` "changed nothing", from its log:** the bore pointed ~40° left of the gaze and
  13° up while the glass sat 36° right (every `world[]` line: `aim=(−30…−150, 960…1200)`,
  `px=(2600…3850, …)` of 2688×2880). Under the shared projection the target is at NDC x ≈ −1.06 — just
  outside the eye image — so the crop clamped to the edge; under 16:9 it lands at u ≈ 0.22, inside
  (check 9 reproduces both). **The mirror can only show what the (reflected) head camera sees**: the rifle
  must be inside the head's view. That is a usage limit of the design, now printed in the log.
- **9f, re-read:** yaw about the normal leaving the plane unchanged, pitch about the bore rolling the image,
  and the picture turning with the head are each exactly what a true planar reflection of a mirror rigid
  to the rifle predicts; model 3's zero change at −60° is consistent with its rotation axis being the pane
  normal for a sideways lean (its own log line defines "swing 0 = about the normal, moves nothing", and
  the swing value was not quoted). So "the pane sets only roll" is `[hypothesis]`, not disproof of the
  reflection mechanism — it changes nothing about the lever (crop-follow is cheaper and does not fight the
  roll law), but a bisector-plane steering (normal along the eye's offset from the bore line, plane through
  the midpoint, which puts the reflected camera ON the bore line and cancels lean exactly) is not ruled out.
- **Stranded latch and SRV census** (the other two 05n `[PD]` rows) are built the same session: rebuild
  counter → ~2 s watch → one of three verdict lines, AMBER indicator on a strand, no auto-clear; `fn sc_next`
  → 90-tick window describing every RT-flagged resource that gets an SRV. The census verdict is
  asymmetric by construction (a hit is evidence of a live capture; an empty window is not evidence of a
  static one) and its close-out line says so.

### 9h. The bore was never wrong — FOV 51.3 is the hip carry, and the roll lever is now flat-testable (2026-09-06 evening, `/pd`, static)

- **Crop-follow reads dead centre in real ADS** `[verified-live 2026-09-06, n=1 launch, 300+ one-second
  samples]`: after the harness's `ads 1` the FOV drops 51.3 → 48.6, the muzzle joint moves to camera-space
  (0.00, 0.00, −0.22), and every `crop-follow:` line reads the bore 0.1–0.3° off the gaze with the centre at
  (0.50, 0.51) — all four candidates. The 06b "40° off in flat ADS" `[measured]` was real but mis-labelled:
  every such sample sits at **FOV 51.3 with the joint at (0.13, −0.13, −0.15)** — Ethan carrying the rifle
  across his body, not aiming. The bore-axis hypothesis is `[disproved 2026-09-06]`; no code changed.
- **Pose signature, for every future log read** `[verified-live 2026-09-06 flat]`: hip carry = FOV 51.3,
  `local≈(0.13,−0.13,−0.15)`, bore ~40° off; ADS = FOV 48.6 (zoom suppressed), `local≈(0,0,−0.22)`, bore
  <1° off. The 05n headset log shows the hip signature on 29 of 41 samples (fov 81.1), so 06a's "rifle held
  across the body" reading of that run stands `[inferred-static 2026-09-06]`; the VR row now demands the
  ADS signature in the `world[]` line before any crop-follow verdict. The crouched-aim row's "(0.13, −0.13,
  −0.09) at FOV 51.3" is the same hip pose seen crouched `[n=1]` — that discriminator is weak.
- **Simulated rifle roll** `[compile-verified 2026-09-06]`, not run: the producer's `rot_roll` turns the
  whole rig about the bore (rot = root · roll(Z) · yaw(Y) · pitch(X), offsets rotated about az);
  `roll_sim` replaces the plugin's measured `g_roll_rad` while non-zero; harness `roll` / `rollpane` /
  `rollsim` / `droll`; the `crop-follow:` line now ends `roll meas/sim/k -> applied`. Sign pinned against
  the shipped `roll_signed_angle`: a rifle rolled +20° about its bore measures +20°, so the feed is
  +deg → +rad (`crop_follow_test.cpp` §11, 40/40 `[verified-numerically 2026-09-06]`).
  `dev-archive/tools/roll_sweep.py OUT roll|rollpane|rollsim`. Expected: picture rolls 2× the rig's roll
  `[hypothesis]`, sign by `flip_h/flip_v`.
- **Stranded-latch watcher** `[compile-verified]`: a latch move to the rigged width within 150 ticks BEFORE
  the rebuild counter is read now counts as "followed" (the allocation lands inside `fn p10`, ahead of the
  ~0.25 s file poll — 06b's wrong-verdict-on-a-good-rig). The STRANDED path is untouched.
- **The `.rtex` is a 64-byte descriptor** `[measured 2026-09-06, n=6 files]`, pulled from the pak by name
  hash with `dev-archive/tools/ree_pak_extract.py` (format from Ekey's public REE.Unpacker source; credit
  Ekey): `RTEX`, v5, 4, DXGI format, width, height, 1, 0, 0, 1, 0, 0, 0, 1.0f, 1.0f, 0. All five movie
  targets are format 29 (R8G8B8A8_UNORM_SRGB — the plugin's fmt=29 rule was this field), `mirror_env` is
  26 (R11G11B10_FLOAT) at 1024×1024. **The shipped heights are name + 8:** 1920×1088, 1280×728 — the
  "padded" sizes the latch sees are in the file, not runtime rounding; 1144×1048 is really 1144×808.
  `rtex_author.py` writes the structure from scratch and reproduces the shipped 1920 and 1280 files byte
  for byte `[verified-numerically 2026-09-06]`. Authored 2560×1448 and 3840×2168 descriptors are deployed
  as loose files under `natives/stm/movie/rtex/`, `LooseFileLoader_Enabled` flipped to true (config
  backed up), producer `fn rtex_2560` / `fn rtex_3840` with fallback to 1920, latch widened to both
  widths `[compile-verified 2026-09-06]`. Engine acceptance of a never-shipped size, and the loose loader
  serving a path the pak lacks, are `[hypothesis]` until one flat launch.

### 9i. Both of those hypotheses are now live facts, and the resolution ceiling is gone (2026-09-06 23:06, `/lm`, one VR launch)

- **A `.rtex` we authored is allocated by the engine** `[verified-live 2026-09-06, n=1]`:
  `mirror RT: using movie/rtex/movie_2560_1440.rtex (2560x1448)` → `MIRROR SOURCE latched: 2560x1448
  fmt=29 flags=0x1` → `MIRROR SOURCE UPGRADED to raw-HDR allocation: 2560x1448 fmt=26`. So **REFramework's
  LooseFileLoader serves a path the pak does not contain** (not just an override), the engine honours a
  width and height it never shipped, and the pre-clip HDR upgrade follows at the new size. The
  2026-09-05 finding "borrowing a bigger target is exhausted at 1920×1080" stands, but its implied wall
  does not: **creating one is a 64-byte file**. 3840×2168 is deployed, untested.
- **Tefa, in the headset:** *"it is way better the quality, if it stayed like this would be great!"*
  `[verified-live 2026-09-06, n=1 observer]`. **This supersedes the 1920-vs-1280 sharpness row** — three
  launches failed to settle that by captures, and a bigger jump plus a human eye settled it in one look.
  Frame cost unmeasured.
- **VR aiming puts the muzzle joint on the gaze axis** `[verified-live 2026-09-06, n=1 launch]`, closing
  9h's open hypothesis. Pose table (camera-space joint / bore off the gaze / roll vs camera): **aiming
  (−0.00, −0.03, −0.30) / 3.5–5.9° / −4 to −14°**; ready-but-not-aimed ~40° / ~−7°; lowered ~40° / **~165°**.
  Flat ADS for comparison is (0, 0, −0.22) / 0.1–0.3° / ~0. **`bore < 20°` is the one-line gate that says
  a headset verdict is worth recording** — it caught a bad judging window on the night it was written.
- **The rifle really rolls against the head in VR** (a few degrees aiming, far more at rest) where flat
  produces none — 06b §4's `[inferred-static]` reading, now measured. **`roll_k` is therefore a `[VR]`
  question**; the flat `roll_sim` harness is a rehearsal rig, not the test.
- **crop_follow does not fix the tracking** `[verified-live 2026-09-06, n=1 observer, 2 of 4 mappings]`:
  modes 2 and 0 both still swing with head turn and tilt (*"the picture inside is moving where i look and
  tilt"*), while the numbers looked right (centre ≈ (0.46, 0.53), all four candidates `inside`). ⚠️ I first
  filed this as `[reported]` with a caveat that the verdict might have been given off-pose, because the log
  showed the bore at ~40° nearby; Tefa corrected it — those samples were the gaps *between* tests, headset
  on the forehead, and every verdict was given while looking. **A report from Tefa about what the game
  looked like is primary evidence; telemetry explains it, never overrules it.** If 1 and 3 also fail, §9g's
  decision table retires crop-follow as the lever and sends the work to the bisector-plane steering left
  open there.
- **Two log defects, found by use** `[measured 2026-09-06]`: the latch line prints a hardcoded
  `(1280-wide)` next to a 2560×1448 source; and the `lua-pane DISAGREES` warning misfires under rifle
  motion in VR (13.0° then 3.5° seconds apart — the Lua publishes at ~2 Hz, the plugin recomputes per
  tick), while its text asserts a derivation error and says "do not tune, fix".

### 9j. ⭐⭐ §9g IS ANSWERED, AND CROP-FOLLOW WAS NEVER THE LEVER: REFramework FORCES THE HMD EYE PROJECTION ONTO THE MIRROR CAMERA (inbox drained 2026-09-09, `/lm`)

Four `/gr` and `/sr` drops dated 2026-09-07 folded in here as one finding. They form a supersedes
chain — `2026-09-07-gr` → `2026-09-07b-gr` → `2026-09-07-sr` → `2026-09-07c-gr` — and were read in
full before any of it was written down, per the claim-hygiene rule. The net position:

**§9g asked the wrong question.** It asked whether `via.render.Mirror` renders with the viewing
camera's projection or its own. The answer is **"its own — and then REFramework overwrites it."**

1. **Natively the Mirror renders with its own camera and projection.** `via.render.layer.Scene`
   holds a `via.Camera*` immediately followed by a `via.render.Mirror*`, and REFramework's own
   `is_fully_rendered()` requires `get_mirror() == nullptr` — praydog's code treats a mirror-bearing
   layer as *not the main view* by construction. praydog, issue #698: *"The way scopes work is they
   create a separate scene, yes."* `[inferred-static 2026-09-07]`
2. **🎯 But `VR::on_camera_get_projection_matrix` has its primary-camera guard COMMENTED OUT, while
   the matching guard in `on_camera_get_view_matrix` is LIVE.** So the mirror render receives the
   current eye's **asymmetric off-centre HMD projection** on top of the mirror camera's **own,
   non-eye view matrix**. **A projection that changes with head pose over a view matrix that does
   not is exactly "the picture inside is moving where I look and tilt."** `[inferred-static 2026-09-07]`
3. **praydog hit this on RE4's scope and fixed it by EXEMPTION** — commit `20a3ec5442`, 2023-04-06,
   *"VR (RE4): Fix scope not being zoomed in"*: match the camera GameObject's name prefix
   `ScopeCamera` and return without overriding. `[reported]` RE8 uses a Mirror where RE4 uses a
   ScopeCamera, so the *match condition* differs; **the remedy does not.**

**⇒ This retires crop-follow as the lever on its own terms.** Every one of the four candidate
mappings tried to *describe* the mirror's projection. If the projection is being overwritten with a
head-pose-dependent one each frame, no fixed mapping can describe it, and both headset launches
swinging is the predicted result rather than a puzzle. The board's ⭐ `[VR]` row is re-written
accordingly.

#### ⚠️ AND THE PROPOSED REMEDY WAS ALREADY IN FORCE WHEN THE SWING WAS SEEN — it is failing, not absent

The `/gr` drop's best paragraph was that `pd-upscaler`'s `RenderingTechnique_V2` **MULTIPASS** mode
erases every mirror-bearing layer from the override list, so "under MULTIPASS the mirror keeps its
own projection". `/sr` then established the home PC runs exactly that branch (`76298bd`, tag
`v1.5.9.1` + 671 commits, branch `pd-upscaler`), and the third `/gr` drop removed the
"reproduce the swing on the home PC first" step because the swing **was** seen here.

**Checked on this machine, 2026-09-09, with no launch — and it does not say what the chain expects:**

- `re2_fw_config.txt` line 99 reads **`VR_RenderingTechnique_V2=2`**.
- The framework log from the **23:03:59 launch of 2026-09-06 — the swing session itself** — carries
  **8 warnings** between 23:04:04.9 and 23:04:26.6:
  `[VR] Multipass textures are not setup correctly.` and
  `[VR] Multipass textures are not setup correctly: Re-using backbuffer.`
  `[verified-live 2026-09-06, n=1 log]`

So the multipass code path **was selected and running while the swing was observed**, and it
**degraded to re-using the backbuffer** rather than doing the thing the remedy depends on.
`[inferred-static 2026-09-09]` for "value 2 selects MULTIPASS" — the warnings are the evidence, not
a read of the enum.

**⚠️ Do NOT write the next VR row as "switch to MULTIPASS and look." It is already on.** The live
question became: *does the multipass texture setup succeed, and does the swing change when it does?*
⚠️ **Not established:** whether the fallback persisted past 23:04:26 — the warnings appear only in
the first 22 seconds of an 11-minute session and never repeat, which is consistent with either a
startup-only stumble that later succeeded **or** a silent permanent fallback. Deciding that is one log read — but ⚠️ **it must be a VR launch.**
The warning is emitted from the VR path, ~1.7 s after `VR::on_initialize()`, so a **flat run cannot
produce it** and would return a *vacuous* "no warnings" indistinguishable from the good outcome.
Checked here before it cost anything: the 2026-09-06 headset log has **148** `[VR]` lines and the
multipass warnings; the 2026-08-26 flat log has **5** `[VR]` lines and **no multipass lines at all**
`[verified-live 2026-09-09, n=2 logs]`. It rides along with any other headset run at no extra launch.

⚠️ Recorded because the board row for this was first written `[FLAT]`, on the reasoning that a log
read is cheaper flat — and that was wrong in the one way that matters: **the cheap run returns the
same output as success.**

#### Two more things worth more than the row they came from

- **⭐⭐ RE8 SHIPS CAPCOM'S OWN VR SNIPER SCOPE, and it works unlike all four of our candidates.**
  `app.VrWeaponSniperScopeLensUpdater` (hash `e6d05808`) is in RE8's type DB with `DistortionBegin`
  (float), `ExpansionRate` (float), `ReticlePosition`, and — the point — **`LensLeftPosition`** and
  **`LensRightPosition`**, both `via.GameObjectRef`. `[reported 2026-09-07]` That is **per-eye lens
  position anchors against a fixed rendered image**, plus a radial distortion term — *not* a per-eye
  reprojection. It addresses Tefa's **first** symptom, *"moving around the pipe of the scope"*,
  which **none of our four candidates ever addressed**; they all only ever went at the second.
  RE8 has no `_ScopeCameraObject`-style field where RE4 does, which is consistent with RE8 handling
  the eyes **at the lens** rather than at the render.
- **A second independent suspect for a head-tracking lag:** the right eye is produced by replaying
  `WaitRendering`→`EndRendering` a second time with an erase list that includes **`UpdateMovie`**
  (praydog: *"Causes movies to play twice as fast if ran again"*). **Our target is a `movie/rtex`
  target.** If its refresh runs under `UpdateMovie` the right eye sees a **stale image**, presenting
  as lag that tracks head motion. `[hypothesis]` Cheap to separate: log the target or a frame
  counter on both passes.

#### One engine fact to pin beside the crop maths

praydog's own comment: *"the game **always** uses the main camera when calling this function, even
though it's rendering the other camera."* **The camera a pass calls a getter on does not identify
the camera that pass is rendering.** Any instrumentation that assumes otherwise misleads — worth
re-reading our own `crop-follow:` instrumentation against.

### 9k. ⭐⭐ Capcom's VR scope is a DEAD END on PC, and §9j is measured (2026-09-12, `/lm`, headset on a stand)

- `app.VrWeaponSniperScopeLensUpdater : via.Behavior` read live: the five researched fields **plus**
  `_mesh` (`via.render.Mesh`), `_materialIndex`, and six material-variable indices
  (`_lensCenterPosIndex`, `_distortionBeginIndex`, `_reticlePosIndex`, `_lensLeftPosIndex`,
  `_lensRightPosIndex`, `_expantionRateIndex`); methods `start`/`lateUpdate`. It is a **per-frame
  material driver** for a lens shader. `[verified-live 2026-09-12, n=1]`
- **0 live instances** in the loaded village scene with the rifle equipped `[verified-live 2026-09-12, n=2]`.
- **The shader it drives is not shipped on PC.** `it02_070_sniperrifle_01.mdf2.19` puts both lens
  materials on `Weapon_SniperScopeLens2.mmtr`, whose variables are `ConvexNormal_CenterPos`,
  `EyeDistortionRange` (float4, 0.1/0.3) and `Reticle_*` only — none of the six the component writes.
  The release list holds one "scope" master material. `[verified-numerically 2026-09-12]`
  ⇒ turning Capcom's VR scope on would mean writing the lens shader; **row retired**.
- **§9j in numbers:** with the rig up, `MainCamera` and `MainCamera (Clone)` both return
  `m00=0.9848 m11=1.1696 m20=+0.1736 m21=-0.2111` from `get_ProjectionMatrix`, every second — an
  off-centre HMD eye projection on a camera that is not an eye `[verified-live 2026-09-12, n=1 launch]`.
  Which of the two is the mirror's camera is **not** identified (`findComponents(via.render.Mirror)`
  returns nothing). Pass/fail for the exemption: the mirror camera's `m20/m21` → 0 while
  `MainCamera` keeps the asymmetry — readable with nobody wearing the headset.
- Multipass warnings: 8 per launch, all before gameplay, `[verified-live 2026-09-12, n=2]` (n=3 with
  2026-09-06). `rtex_3840`: allocates, latches, upgrades to fmt=26, not stranded
  `[verified-live 2026-09-12, n=1]`; frame cost still has no readout.
- Lua API note: `get_ProjectionMatrix` returns a sol-bound glm `mat4`; read rows as `m[r]` and
  components as `.x/.y/.z/.w` — integer `[r][c]` is nil `[verified-live 2026-09-12]`.
- Headset on a stand with the proximity sensor taped: REFramework opens the OpenXR session on the
  Quest 3 with nobody wearing it, and the whole driving profile works in VR mode
  `[verified-live 2026-09-12, n=3 launches]`. Unattended VR runs are a thing now.

### 9l. ⭐⭐ THE MIRROR-CAMERA EXEMPTION IS BUILT, DEPLOYED AND FIRES (2026-09-12, `/lm` + reader; drained from two reader inbox drops the same day)

**Why a praydog-style name match could never work here:** the mirror layer's camera **is the main
camera, same address** (2026-08-30 sky-hunt §1 `[verified-live, n=1]`), and REFramework's MULTIPASS
filter admits the primary camera on purpose (`VR.cpp:272-276`; `m_multipass_cameras` = `{primary,
duplicate}`, `VR.cpp:794-798`; the duplicator clones only the primary, `CameraDuplicator.cpp:83-96`).
So inside `on_camera_get_projection_matrix` (`VR.cpp:255`, guard commented out at :259-261) and
`on_camera_get_view_matrix` (`VR.cpp:326`, guard live at :335-339) the camera argument is identical
for the main pass and the mirror pass `[inferred-static 2026-09-12, reader]`.

**The fix exempts the PASS, not the camera.** Patch `D:\RE2 REFramework builds\tools\REFramework-src\mirror-exemption.patch`
(322 lines, against fork `76298bd` = `gmankab/reframework-pd-upscaler-build` `pd-upscaler`,
v1.5.9.1 + 671 — the exact build this PC runs): a thread-local flag is raised in
`on_pre_scene_layer_update`/`_draw` when `layer->get_mirror() != nullptr` and dropped in the post
callbacks; while it is up, both getter hooks return without overriding. Fallbacks: camera address
(4 slots) and name prefixes `ScopeCamera`/`MirrorCamera`/`ScopeMirror`. Toggle `VR_ExemptMirrorCameras`
(default on) + UI checkbox; a second toggle `VR_ExemptMirrorCamerasSticky` (default off) keeps the
window open until the next non-mirror layer, for the case where the getters land between layer
calls. Counters and two log lines fire before the HMD check, so a flat run can read them.
Build: CMake 4.4.3 + VS 2022 BuildTools, target `RE8`, Release, 0 errors (C# language stripped
from `cmake.toml` locally; DirectXTK shaders compiled by hand once). DLLs, labelled, in
`D:\RE2 REFramework builds\`: `…mirror-exemption_2026-09-12…` (22,745,600 B, MD5 `9f90b183…`) and
`…STICKY-OPTION…` (MD5 `54836923…`). `[verified-numerically 2026-09-12]`

**Live, VR, rig up, 11:49** `[verified-live 2026-09-12, n=1 launch]`:
`Mirror-bearing scene layer seen (update): … camera_is_primary=true camera_go="MainCamera"` and
`Mirror layer windows=1200 get_ProjectionMatrix calls inside=600 get_ViewMatrix calls inside=600 exempted proj=48101 view=48101 (by window=1200 camera=95002 name=0) hmd_active=true`.
The getters ARE called inside the window and ARE exempted. On the same run the probe reads
`'MainCamera (Clone)' m00=1.7527 m11=2.0815 m20=0 m21=0` (its own symmetric 51.3° projection) while
`'MainCamera'` keeps `m20=+0.1736 m21=-0.2111`. Deployed as the game's `dinput8.dll`; the previous
(fork) DLL is `dinput8.dll.pre-mirror-exemption-backup-2026-09-12` beside it — and that backup is
the only copy of what was running (MD5 `41af4484…`, not the labelled `DLSS-capable` file).

**⚠️ WORN 12:00 — the swing is UNCHANGED, and the eyes DOUBLED** `[verified-live 2026-09-12, n=1 wearer]`.
So with both getters exempted inside the mirror window the picture still moves with the head: the
getter override is **not** the swing's cause, or not its only one — §9j's "exactly the reported swing"
is `[disproved 2026-09-12]` as the sole cause. The double eye is the address stage exempting the
multipass duplicate eye camera (`by camera=95002`). Original DLL restored 12:05; any rebuild is
window-only. Next candidates: plan B(1) below, or the pane re-aiming with the head (§9f).

**Was not established before the wear:** the swing itself, which needs a head. If a wearer still sees it: (1) set
`VR_ExemptMirrorCamerasSticky=true` with the STICKY DLL; (2) plan B(1), restore the native
projection into the mirror layer's `SceneInfo` post-update (`Renderer.cpp:1897-1915`, restore point
`VR::on_scene_layer_update` `VR.cpp:664`) `[hypothesis]`; (3) do NOT give the layer its own camera —
tried 2026-08-30, the host object freezes. Full reader text: modding-notes 2026-09-12 §5.

**Frame cost, measured** (plugin `frame:` line, VR, standing, VD cap 72): no rig 13.9 ms; 1280
15.0; 1920 15.5; 2560 16.1; 3840 18.0 `[verified-live 2026-09-12, n=1 launch]`.

### 9m. ⭐⭐ THE SWING IS NOT IN THE HOOKED GETTERS AT ALL (2026-09-12, `/lm`, two worn tests)

Two builds, two negatives, both with the mechanism proven to fire:

1. **v1, projection+view exemption inside the mirror window** — counters showed 48,101 exemptions,
   the mirror-side camera read a symmetric projection, **swing unchanged** `[disproved 2026-09-12, n=1 wearer]`.
   Side effect: the camera-ADDRESS stage caught the multipass duplicate eye camera and **doubled the
   eyes** (*"two pictures on either lens, quite close to each other, but off"*).
2. **v2, window-only + plan C** (inside a mirror window, `on_camera_get_view_matrix` returns
   `view_native * W_hmd * inverse(W_orig)`, i.e. the game's own un-HMD'd pose): counters
   `un-HMD'd 1800 times, skipped 0`, `by camera=0` — **swing unchanged again**
   `[disproved 2026-09-12, n=1 wearer]`.

⇒ **The mirror's image is not derived from `via.Camera::get_ViewMatrix`/`get_ProjectionMatrix` calls
made on the calling thread inside the layer's update/draw window.** Both of REFramework's overrides
are now ruled out as the swing's cause. What is left is §9f, measured in the headset three launches
ago: **`via.render.Mirror` looks where the VIEWING camera looks** — which in VR is the eye, so the
reflection re-aims with the head natively, inside the engine, below anything REFramework hooks.

⭐ **And that un-blocks the steering family.** `steer`/`model 2`/`steerk` were built to cancel exactly
a geometric head-dependence, and were retired in §9j only because a projection rewritten every frame
made them undescribable. That confound is gone in the v2 build, so the steering test is newly valid
and costs no rebuild — harness `model 2` + `steerk ±0.5` + `steer 1`.

⚠️ **Unattended-VR reading rule (Tefa, 2026-09-12):** when the headset is handed over it sits on a
table and **the motion controllers are parked side by side on a shelf**. So every controller-derived
number — hand positions, grip, dock distance, wrist poses, rifle-from-controller pose — is
meaningless on these runs, and hands may look twisted. Judge only head-independent quantities, or
quantities the user reports while actually wearing it. `[reported 2026-09-12]`

Also seen once: a launch came up with a **completely black picture** in the headset and needed a game
restart `[reported 2026-09-12, n=1]` — cause unknown, no log read taken.

### 9n. ⭐⭐⭐ THE "SWING" IS THE IMAGE'S PLACEMENT IN THE TUBE, NOT THE IMAGE'S CONTENT (2026-09-12, `/lm`, the test that reframed the project)

After three worn tests all came back "exactly the same", `fn destroy_rig` was sent purely as a
control — to find out whether Tefa was looking at OUR picture at all. The answer settled two
questions at once, and the second one is the important one.

**1. We WERE seeing our picture, so today's negatives are real.** Tefa, immediately after the
teardown: *"picture inside the headset is now a still picture … i can see some rails and the goat"* —
the producer's own warning (*"teardown can no longer kill its rendering — the glass just freezes"*)
made flesh. So the glass bind works, the mirror feeds the lens, and §9l / §9m's disproofs stand
`[verified-live 2026-09-12, n=1 wearer]`.

**2. 🎯 With the image FROZEN, the complaint persists:** *"the scope still moves around in the scope
tube when i move my head or the weapon, but the image inside the scope is still."*
`[verified-live 2026-09-12, n=1 wearer]`

⇒ **A frozen image cannot re-aim. So what moves is the DISC OF PICTURE relative to the scope tube —
its placement — not the scene inside it.** Every attack this project has mounted since 2026-09-05
(the four crop mappings, the steering models, the roll law, §9j's projection override, §9l's
exemption, §9m's plan C) aimed at the *content's* projection. **The symptom was never there.**

That also explains, exactly, why `steerk 0.5 → 3.0` and a deliberate `dyaw 25` were all indistinguishable
to the wearer: they move the content, and the content was not what was wrong.

**⭐ And this is precisely the problem Capcom's own VR scope solves.** §9k read
`app.VrWeaponSniperScopeLensUpdater` live: **`LensLeftPosition` / `LensRightPosition`** (per-eye lens
position anchors), `ExpansionRate`, `DistortionBegin` — *placement and magnification of a lens image
against a fixed rendered picture*, per eye. The 2026-09-07 research note already said this addressed
Tefa's FIRST symptom, *"moving around the pipe of the scope"*, *"which none of our four candidates
ever addressed"*. It was right, and it was filed under an idea we then retired for a different reason.

**What this means for the next attempt** (`[hypothesis]`, none of it run):
- Our composited picture is blitted into one engine texture drawn on the glass mesh, so **both eyes
  sample the same texture on the same quad** — it behaves like a sticker on the glass rather than an
  image formed by optics, and a sticker slides against the tube as the eye moves. That is the defect.
- The fix is per-eye: the sampled crop centre must shift with **the eye's position relative to the
  lens axis**. The `crop-follow` machinery already computes an eye→mirror crop centre (it logs four
  candidates every second) — it was built for the right geometry and judged against the wrong symptom.
  **First cheap test: turn `cropfollow` ON and judge it against TUBE ALIGNMENT, not content.**
- If one texture cannot serve two eyes, the honest route is our own material on the glass with an
  eye-aware shader — i.e. rebuilding Capcom's design with the four ingredients §9k already gave us.

⚠️ The rig is destroyed and the glass is frozen; `numpad .` re-arms the latch and a new producer appears.

## 10. The framework's offset table is an assumption with a date on it (`/sr` drop, drained 2026-09-05)

Source: `flat-to-vr-cross-engine-research` → RE Engine family page. Read from the merged pull
request; nothing cloned or installed.

- **REFramework PR #1822 (porlock2, opened and merged 2026-09-05) fixes the static offset accessors
  for `via.render.Texture`** `[reported 2026-09-05]`. A March 2026 Resident Evil 4 update
  (1.5.9.0) re-laid-out that type to match Street Fighter 6: the description field moved base, and
  the D3D12 resource container moved **`0xA0` → `0xB8`**. The fix is a per-title branch; the
  contributor states the offsets were measured, not estimated.
- **Why it lands here: those accessors are the surface this project's M2 work sits on.** A
  magnified scene rendered into a render target and composited back is texture-descriptor and
  resource-container territory — the two things that moved. **Nothing says our build is broken**;
  RE Village is not RE4 and the fix is title-scoped. What it establishes is that
  **`via.render.Texture`'s layout is per-title *and* per-game-version.**
- **Both our builds predate the fix, and on this one point the two machines agree** — the home PC's
  fork `76298bd` (2026-03-11) is three weeks before the RE4 layout change landed, and the dev PC's
  nightly `684ca77` (2026-08-20) is before the fix. Worth writing down precisely because the two
  machines usually differ.
- **⚠️ The symptom is the part to remember.** The crash this fixed happened **at the Capcom logo
  during startup, on game worker threads, with no framework frame anywhere in the call stack**,
  with or without upscaling. Nothing about it pointed at a stale struct offset. **If this project
  ever meets a startup crash that looks unrelated to the framework, read the offset accessors
  before debugging our own code** — it is a one-file check and it is upstream of every other
  hypothesis.
- **Also on this surface:** upstream `master` gained three Lua data-model commits on 2026-09-04
  (array element setting, general array handling, string-vs-number ambiguity), the substantive one
  widening managed-array creation length to signed 64-bit so a negative length cannot wrap into a
  huge allocation, and making out-of-range indexing return nothing or raise rather than be
  undefined. **None of that is in either of our builds.** Exposure shape: wrong values rather than
  errors, landing on recon code rather than shipped scripts.

Credit: **porlock2** (the fix and its measurements), **praydog** (REFramework).
