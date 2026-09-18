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

> ⚠️ **The first bullet below is WITHDRAWN. See §9o (2026-09-12, `/pd`).** The reading was
> right and the conclusion was wrong: `EyeDistortionRange` is a **float4** and every write in
> that experiment went through the **scalar** setter, so none of them reached the material.
> "There is no writer to hunt" happens to be true, for a different reason; "cannot be written"
> is not. Nothing else in §8d is affected.

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

### 9o. ⭐⭐⭐ THE LENS EYE-BOX WAS NEVER UNWRITABLE — IT IS A FLOAT4 AND WE KEPT WRITING IT AS A FLOAT (2026-09-12, `/pd`, no launch)

Supersedes: §8d, bullet 1 (`EyeDistortionRange` "cannot be written / the row is closed").
Source: `modding-notes/2026-09-12b-the-eye-box-was-never-unwritable.md`.

- **⭐ The variable is a `float4`, authored 0.1 / 0.3, and the plugin has always written it with
  `setMaterialFloat`** — the scalar setter — and read it with `getMaterialFloat`. A scalar write into
  a float4 slot lands nowhere; the read returns the x lane. **The `0.100` that five sessions read as
  "the game refuses our value" is Capcom's authored `x`, handed straight back.**
  `[inferred-static 2026-09-12]`
  - Structural evidence: §9k's pak read of `Weapon_SniperScopeLens2.mmtr` `[verified-numerically 2026-09-12]`.
  - Behavioural evidence, independent of any file: the same call, same mesh, same material, same
    learned ABI encoding, **verifies on all five other scalars written in that loop**
    (`ConvexNormal_Intenisty`, `FrontHole_Height`, three × `FakeSpecular_*`) and fails only on this one
    `[verified-live 2026-09-05, n=2 materials × 3 launches]`. The plugin's float4 path is known good in
    the same logs (`FrontHole_Color_*` read back exactly what they are given).
- **⭐ It is the leading candidate for §9n's placement defect, and the chain is end to end.** Our picture
  is bound into the lens material's `Reticle_BaseAlphaMap`; the shipped lens shader carries an
  eye-direction term scaled by `EyeDistortionRange` `[reported 2026-09-12]`; §8 measured in the headset
  that "off-axis the visible disc shrinks and **slides** … with view angle"
  `[verified-live 2026-09-05, n=2]`; §9n measured with our image **frozen** that what moves in the tube
  is the disc's placement `[verified-live 2026-09-12, n=1 wearer]`. **⚠️ Which sampler's UV the
  `eye_dir` term perturbs is read from a note, not from the shader, so "zeroing it removes the swing"
  stays `[hypothesis]`.** What is established is that the write can now reach the variable at all.
- **⭐ `crop_follow` CANNOT move the disc in the tube, at any setting** `[inferred-static 2026-09-12]`.
  In `ps_main` the lens circle, its edge, the reticle and the mode tab are all drawn from the
  **destination** pixel's `i.uv`; `uvCenter` (the only thing `crop_follow` sets) appears solely in the
  **source** sample `suv = uvCenter + pr * 2 * uvHalf`; and `blit_rt_into_target` fills the whole
  target viewport 1:1 with no offset. The crop moves the picture *inside* the hole; it cannot move the
  hole. ⇒ §9n's "cheapest first step (a), turn `cropfollow` on and judge tube alignment" would have
  returned "no change" by construction. **Row re-ordered; that launch is saved.**
- **Built, compile-verified, deployed, NOT run:** float4 material accessors with the same
  verified-read-back contract as the scalar ones; `EyeDistortionRange` moved to a float4 block that
  logs all four authored lanes at every bind; the 2026-09-05 scalar ladder and its hold window
  retired; a frame-rate `eyedist_hold_tick`; and one live knob `eyedist` (harness → pane file →
  plugin, persisted): `0` = off and held, `-1` = the authored value restored and left alone,
  `-9`/absent = not commanded. `[compile-verified 2026-09-12]`
- ⚠️ **WITHDRAWN by §9p, later the same day: `eyedist 0` is the WRONG direction.** The shader
  guards `EyeDistortionRange.y == .x` with `hi = x + 1e-4`, so all-zeros pins the smoothstep at
  **1** — the largest offset, permanently. Default corrected to `-1`. The float4 finding itself,
  and the `crop_follow` disproof, are unaffected. The superseded test read:
- ~~**The one wear that decides it:** `eyedist 0` then `eyedist -1`, judging TUBE ALIGNMENT only.~~ Disc
  still at `0` and sliding at `-1` ⇒ solved. No difference, with the log saying the float4 write
  verified ⇒ not the cause, and §9n route (b) (our own material, eye-aware shader) is the remaining
  route. Bind-time log line to read either way:
  `look: [2] EyeDistortionRange shipped (0.100,0.300,…) -> … reads back …` — the `shipped` tuple is
  also the live check on §9k's file read.

### 9p. ⭐⭐⭐ THE LENS SHADER, READ: THE ENGINE MOVES OUR PICTURE WITH THE HEAD, AND TWO SCALARS SWITCH IT OFF (2026-09-12, `/pd`, no launch)

Supersedes: §9o, final bullet (the `eyedist 0` test).
Source: `modding-notes/2026-09-12c-the-lens-shader-says-exactly-what-slides-and-what-stops-it.md`;
evidence and the reproduction recipe in `dev-archive/recon/2026-09-12-lens-shader-read/`.

- **⭐ `weapon_sniperscopelens2.mmtr` opens.** 7 MB, **378 ordinary DXBC blobs with reflection
  intact**, nine mentioning this material's variables; the lit pixel shader disassembles cleanly
  through `D3DDisassemble`. Tool: `dev-archive/tools/mmtr_shaders.py` (carve / find / dump / disasm).
  ⚠️ The in-pak version suffix is a 10-digit number (`.2102188797`) — the entry point is the
  community file list inside the REE.PAK.Tool checkout on this machine, not guessing.
  `[verified-numerically 2026-09-12]`
- **⭐⭐⭐ What the lens does to our picture:**
  ```
  uv = base_uv * Reticle_UV_Scale + Reticle_UV_Offset + (dot(T,d), -dot(B,d)) * k
  d  = s * viewDir - (1 - s) * cameraForward
  s  = smoothstep(EyeDistortionRange.x, EyeDistortionRange.y, distance(camera, lens pixel))
  k  = lerp(Reticle_Depth_Max, Reticle_Depth_Min, pow(saturate(dot(cameraForward, N)), Reticle_DepthCurve))
  colour = Reticle_BaseAlphaMap.Sample(uv)          // t18 = the slot OUR picture is bound into
  ```
  `T`/`B`/`N` are the lens's tangent frame, welded to the rifle; `s`, `viewDir` and `cameraForward`
  all move with the head, and `viewDir` differs between the two eyes. **The engine slides our
  picture inside the lens. It was never our compositor.** Authored `Reticle_Depth_Min = 0.388`,
  `Reticle_Depth_Max = 500.0`, so on-axis `k ≈ 0.388` — a displacement of ~40% of the texture.
  `[verified-numerically 2026-09-12]` for the maths; that it is *the* wearer's complaint is
  `[hypothesis]` until worn.
- **⭐ The off switch is `Reticle_Depth_Min` + `Reticle_Depth_Max` = 0.** The whole offset is
  multiplied by `k`. Neither variable appears anywhere else in the shader — `cb6[9].w` on one
  instruction and `cb6[10].x` on two, all three inside this term, counted in the disassembly — and
  **both are plain scalars**, so the plugin's verified scalar writer reaches them today. That is
  exactly what `EyeDistortionRange` could not do. `[verified-numerically 2026-09-12]`
- **⚠️ `eyedist 0` was the wrong direction and is corrected.** `if (EDR.y == EDR.x) hi = x + 1e-4`
  makes all-zeros saturate the smoothstep to `s = 1` — the largest offset, held there. Default is
  now `-1` (leave the authored value alone); the knob is kept for sweeps. Nothing was ever run
  with the bad default, but it had been deployed and was the next thing on the board.
- **Also in the same excerpt:** `FrontHole_Height` multiplies the **same** 2D offset for the painted
  tube-hole. We have zeroed that one successfully since August — so one of the offset's two
  consumers has been off all along, and the one carrying our picture has not.
- **Built, compile-verified, deployed, stamped, NOT run:** the `retdepth` knob (harness → pane file
  → plugin, persisted; `0` = offset dead and held, `-1` = authored values back and left alone),
  `ret_depth_hold_tick` at frame rate because the `Reticle_*` family is re-asserted every frame, and
  a bind-time log of the authored values before they are overwritten. `[compile-verified 2026-09-12]`
- **The one wear:** `retdepth 0` then `retdepth -1`, judging TUBE ALIGNMENT only. Still at `0` and
  sliding at `-1` ⇒ solved. No difference with both writes verifying ⇒ the term is off and the
  remaining candidate is plain geometry (a flat picture on a plane recessed behind the tube rim),
  i.e. §9n route (b). Writes not verifying ⇒ the hold has to move earlier in the frame.
  Bind-time lines: `look: [2] Reticle_Depth_Min authored 0.388 -> 0.000 reads back 0.000` and the
  matching `_Max`, which also check the material-file read live.

### 9q. ⭐⭐⭐ WORN: THE DISC SITS STILL (A→B→A), AND WITH IT GONE THE GUN STEERS THE PICTURE UNDER MODEL 0 (2026-09-12, Tefa wearing, then `/pd`)

Source: `modding-notes/2026-09-12d-first-worn-win-the-disc-sits-still-and-the-gun-steers-the-picture.md`;
evidence `dev-archive/recon/2026-09-12-first-worn-win-retdepth-model0/`.

- **⭐⭐⭐ §9p's off switch works in the headset, blind, both directions.** `retdepth 0`: *"it does not
  slide around the tube anymore, the scope glass is actually the scope glass, right where it has to be"*;
  `retdepth -1`: *"it slides around the tube again"*; `0` again: still.
  `[verified-live 2026-09-12, n=1 wearer, A→B→A]`. The placement row is CLOSED; `retdepth 0` is the boot
  default. Both scalar writes land (`authored 0.388 / 500 → 0.000 reads back 0.000`, both materials), and
  `EyeDistortionRange` reads live as the float4 `(0.1, 0.3, 0, 0)` — §8d's "cannot be written" is now
  disproved in the game, not only on paper `[verified-live 2026-09-12, n=2 materials]`.
- **⚠️ Consequence for everything since 2026-09-05: the content-line disproofs are void in BOTH
  directions.** They were judged with the disc sliding, so a model that worked could not have been seen to.
  Steering model 0, "DISPROVED" in §8, is un-disproved by this — and, below, it works.
- **The horizontal-mirror signature, described by the wearer without knowing the law.** `cropfollow 0`,
  baked pane: *"left and right with head movement, not gun movement; up and down with gun movement, and
  head movement is inverted — head up moves the picture down"* `[verified-live 2026-09-12, n=1]`. A flat
  mirror under the line of sight preserves yaw and inverts pitch; its viewpoint is the eye's, never the
  rifle's. The plane has to be steered.
- **Model 2 (identity on-axis): no change**, pane within ~6° of −Y — it is built to do nothing where the eye
  is when aiming `[verified-live 2026-09-12, n=1]`. Wrong tool for this symptom.
- **⭐⭐ Model 0 (the exact reflection law): THE GUN STEERS THE PICTURE.** *"aiming with gun also moves the
  picture left right up down and Ethan's clothes do rarely show on the scope"* — the 2026-09-05 jacket goes
  with it. Remaining: *"turning my head rotates the picture … rotating as I look and aim"*; *"both head and
  gun roll the picture, but head tilting does not seem to"* `[verified-live 2026-09-12, n=1 wearer, tilt
  part hedged]`. That is the mirror law: a plane that swings by α about the bore turns its image by 2α.
  One flat mirror cannot be direction-correct and roll-free; the roll is computable and is cancelled in
  the compositor.
- **Built with nothing running (`/pd`): the steered-mirror roll cancel.** `src/mirror_roll_math.h`
  (reflect camera forward/up across the pane in use, signed angle from world-up about the reflected
  forward, minus the 180° that `flip_h + flip_v` already pay for, so the baked pane returns 0);
  `tools/mirror_roll_test.cpp` **89/89** `[verified-numerically 2026-09-12]` (horizontal → 0 at 35 poses,
  turned-by-α → 2α against first principles, degenerate → `ok = 0`; the first run's 8 failures were a
  hand-waved sign in the test's expectation, fixed in the test). Applied as
  `roll_k·rifle_roll + mroll_k·mirror_roll`; live knobs `mrollk` (signed, default 1) and `mrollmode`
  (1 = world-up camera, default; 0 = real camera up). Deployed, stamped, **not run**.
- **Next wear, exact order (nothing steering-side persists):** keys `110` → `fn p10` → `fn drive_on` →
  keys `106` → `cropfollow 0` → `model 0` → `steer 1`; then `mrollk 1` / `-1` / `0` judging only the
  spin, `mrollmode 0` only if head tilt now rolls it. Log: `crop-follow: … | mroll X deg mode M k K`.

### 9r. ⭐⭐ FOUR WEARS: THE SPIN CANCEL GOES FROM "SPINS AND SNAPS" TO "HALF STRENGTH, NO SNAPS, ONE STEADY TILT" (2026-09-12 evening, `/lm`, Tefa wearing)

Source: `modding-notes/2026-09-12e-four-wears-the-spin-cancel-goes-from-snapping-to-half-strength.md`;
traces and a headset frame in `dev-archive/recon/2026-09-12-mroll-first-wear-and-the-spin-trace/`.

- **⭐ The roll lives in the MIRROR IMAGE, not downstream of the compositor.** Our crosshair is
  drawn upright in the render target; worn, *"the crosshair just sits there without moving at all"*
  while the picture behind it turns `[verified-live 2026-09-12, n=1 wearer]`. So the thing to cancel
  is the mirror-law roll of §9q — §9q's idea stands, its v1 maths did not.
- **v1 (world up, about the reflected forward) was wrong in both reference choices.** Worn: spins AND
  snaps at `mrollk 1`; spins without snapping at `0`. Trace: the term sat near **—134°** while still
  and jumped 26° in a second when the pane moved — with the head 40° off the bore the reflected
  forward points steeply down and "world up perpendicular to a near-vertical axis" is ill-conditioned
  `[verified-live 2026-09-12, n=1]`. ⚠️ A stable-looking large value is not a small correction.
- **v2: about the BORE, from the RIFLE'S up, as the excess over the BAKED pane computed at the same
  instant** (zero by construction when steered = baked; no baseline state to go stale). Worn:
  `mrollk 1` "less, sometimes not rotating at all on pure left/right"; **`mrollk -1` "rotates, then snaps
  back to the right way up"** ⇒ **—1 is the sign**, and the snap-back is LAG: the plugin read the
  steered normal from the Lua's pane file (~2 Hz publish / ~4 Hz read) `[verified-live 2026-09-12, n=1]`.
- **v3: the plugin recomputes the Lua "eye" model's normal EVERY TICK** (§9q's `mrollsrc 1`):
  `v = normalize(anchor — eye)`, `d = bore`, `n = normalize(v — d)`, with the plugin's joint as the
  anchor and the **verified muzzle axis** as both the bore and the roll axis (not the root's +Z).
  Tests: 176/176 `[verified-numerically 2026-09-12]` — baked pane → 0 at 35 poses, normal turned by
  alpha about the bore → 2 alpha, pane PITCHED toward the eye → 0 (the case v1 broke on; bounded
  at |pitch| < 45°, beyond which the reflection genuinely inverts), whole rifle rolled → 0, and for
  eyes all round the rifle the recomputed normal reflects the eye ray onto the bore with the roll even
  in the sign of `n`. Worn: the term reads **—7 to —37°** as the head moves; **no snapping**.
  `mrollk -1` over-corrects (still swings), **`mrollk -0.5` swings less with a steady tilt left over**
  `[verified-live 2026-09-12, n=1 wearer]`. **Shipped default —0.5 / src 1 / mode 1.**
- **What is left, separated:** (a) the moving part's STRENGTH — between —0.5 and —1, or a magnitude
  error in the recomputed normal (Lua anchor vs plugin joint, `flip_d`); (b) a **constant tilt** the
  excess-over-baked construction cannot see by design — the baked picture's own roll, or `roll_k`
  (still 0), or a fixed compositor-to-glass offset — one offset knob decides it; (c) **warp/stretch
  while rotating** — an obliquely tilted planar mirror reprojects the scene and a rotated rectangular
  crop of a 16:9 render cannot undo that; not a roll problem. Also verbatim for the content line:
  *"moving my head is inverted left and right in game, moving my head up and down causes the picture
  inside the scope to snap to where it is pointing"* — the mirror's AIM steps and yaw is mirrored.
- Cosmetic, seen twice: the goat rig prop turning on the side of the rifle as the pane steers; the goat
  visible through the lens with the rifle turned far right.
- Wearer's summary of the state on v2: *"honest feel of it is like aiming down a scope now. just needs
  to be right, but it feels good."*

### 9s. ⭐⭐ THE CONSTANT TILT GETS A KNOB THAT MEASURES ITS OWN VALUE (2026-09-12 night, `/pd`, no launch)

Source: `modding-notes/2026-09-12f-the-constant-tilt-gets-a-knob-that-measures-itself.md`.
Closes all three `[PD]` rows §9r queued — two as built, one **corrected**.

- **⭐⭐ `mrolloff <deg>`: the constant added to the applied angle.** §9r's cancel is the excess over
  the BAKED pane, so it is zero by construction whatever roll the baked picture itself carries —
  **a fixed tilt is invisible to it by design.** Harness ⇒ pane file ⇒ plugin, persisted.
  ⚠️ Its "not commanded" sentinel is **—999, not —9**, because **0 is a real value** here unlike the
  0/1 knobs beside it.
- **⭐ And the knob's value is MEASURED, not swept.** The plugin now computes the roll the **baked pane
  alone** gives against the rifle's up — the same quantity the cancel subtracts — and prints it once a
  second as **`baked-roll`**. Never applied; it exists to be read. **Non-zero and steady with the rifle
  held still ⇒ `mrolloff` is minus that number.** That turns a three-wear sweep into "read one number,
  set the knob, one wear".
- **⭐ `n-vs-lua`: is the plugin's recomputed normal the one the Lua applies?** The per-tick normal
  (§9r, `mrollsrc 1`) assumes the plugin's joint anchor and muzzle axis reproduce the Lua's `"eye"`
  model, which uses its own `anchor_pos` and can flip the bore (`flip_d`). If they differ the cancel's
  **magnitude** is off by exactly that angle — **indistinguishable in the headset from a wrong
  coefficient**, and that is the other reading of "—1 over-corrects, —0.5 under". Now printed as the
  angle between the two, compared **as planes** (a normal's sign is arbitrary, so the Lua's is flipped to
  the same side first, or a perfect match would read 180°). Never acted on.
- **⚠️ THE GOAT ROW WAS NOT THE FREE COSMETIC CHANGE IT WAS WRITTEN AS.** §9r said *"hide the rig prop's
  mesh — cosmetic; the pane must stay"*. `rig_mesh_draw()` has existed since M19, but **the producer's
  own comment has asked since 2026-08-27 whether the mirror keeps PRODUCING with its host mesh hidden**,
  and nothing in the dossier or the notes answers it — no run has ever tested it. Hiding it by default
  could blank the scope. **Corrected to a one-command test:** `fn goat_hide` / `fn goat_show` published to
  the harness (the function existed; nothing driven could reach it), default unchanged. `[hypothesis]`
  that hiding is safe.
- **Verification:** all three numeric suites re-run against the changed source — `mirror_roll_test`
  **176/176**, `crop_follow_test` **40/40**, `roll_math_test` **20/20** `[verified-numerically 2026-09-12]`;
  both Lua files parse and both `string.format` calls arity-checked (the pane file is 26 lines and carries
  `mroll_off`); and **the C log line tokenised: 35 specifiers, 35 arguments**, last five aligned.
  ⚠️ `LOGI` is a variadic wrapper, so the compiler does **not** check that pair — and two earlier
  attempts at the check produced confident wrong numbers (one matched a different `crop-follow:` `LOGI`,
  the other was fooled by string literals inside the *arguments*). Worth knowing before trusting a
  quick grep on any `LOGI` in this file.
- **Deployed and stamped, NOT run.** The install was verified current first: a rebuild hashed identical
  to the installed DLL before any edit.
- **The next wear reads two numbers before it touches a knob:** `baked-roll` non-zero and steady ⇒
  set `mrolloff` to minus it; ~0 ⇒ the tilt is not the baked pane and `roll_k` (the rifle's own roll,
  3—6° measured today, never applied) is the next suspect. `n-vs-lua` ~0° ⇒ the strength is a real
  coefficient question, sweep `mrollk`; tens of degrees ⇒ fix the anchor/`flip_d` mismatch instead of
  tuning around it.

### 9t. ⭐ THE RIG PROP: SHRINK IT, DO NOT MOVE IT — AND WHAT THE PROP ACTUALLY IS (2026-09-12 night, `/pd`, no launch)

Source: `modding-notes/2026-09-12g-shrink-the-prop-instead-of-hiding-it.md`. Tefa's idea, reshaped by
reading the code.

- **What the "goat" IS, since it keeps being misread as scenery:** a prefab borrowed from the game
  (`sm80_382_totemeveryware_00_swing`, a hanging totem), spawned only because the engine will not let us
  create a bare `via.render.Mirror` from nothing — we need a real object to bolt components onto. The
  prop is scaffolding; the mirror is the point.
- **⚠️ PARKING IT AWAY CANNOT WORK.** `rig_pose_once()` copies the RIFLE's transform onto the prop every
  frame, so **the prop's position IS the mirror's position**. Above the head ⇒ the scope shows a
  reflection taken from above the head. Tefa's idea was to park it *"slightly behind the player and above
  the head"*; this is why that specific form of it fails, and it is worth having written down.
- **⭐ But the same function gives the version that works.** `rig_pose_once` writes `set_Position` and
  `set_Rotation` and **nothing else** — and that is not a reading of one function but an exhaustive
  grep: **the only scale write anywhere in the producer, the harness or the plugin is the one added
  today** `[verified-numerically 2026-09-12]`. A scale written once has nothing in our code to undo it,
  and a plane is a point plus a normal, neither of which has a size `[hypothesis]`.
  ⇒ **Shrink the prop, do not move it.**
- **Strictly better than hiding the mesh.** `fn goat_hide` disables the mesh component, and whether the
  mirror keeps PRODUCING with its host mesh hidden has been open in the producer **since 2026-08-27 and
  has never been tested**. Shrinking never touches the mesh.
- **Built:** `fn goat_shrink` (×0.001), `fn goat_shrink2` (×0.05, deliberately visible — it tells "the
  shrink worked" apart from "the prop was never in view"), `fn goat_unshrink`. The prefab's OWN scale is
  captured once on the first shrink (these props are not all unit-scaled, and the capture-once guard
  stops a second shrink stranding the restore); every write is read back and logged; a failed read
  refuses rather than writing something it could not undo; `destroy_rig` forgets the capture.
- **⭐ Re-assertion is visible without a wear:** while a shrink is in force the periodic `sliders:` line
  echoes the live scale and prints `<-- SCALE RE-ASSERTED` if it climbs back. If the game owns the scale,
  that shows up in the log rather than as a prop quietly returning in the headset — and the fix would
  then be a per-frame hold, exactly like `Reticle_Emissive`.
- **The test, three commands, any launch:** `fn goat_shrink2` ⇒ `fn goat_shrink` ⇒ `fn goat_unshrink`.
  Picture unchanged ⇒ ship the shrink at rig build. Picture dies ⇒ the mirror scales with its
  object (worth knowing beyond this project), fall back to `goat_hide`. `WRITE DID NOT LAND` ⇒ wrong
  setter, the log names the next step. Prop returns ⇒ per-frame hold.
- **Not addressed, and deliberately:** Tefa's roomscale/stick constraint. It does not apply while the prop
  rides the rifle, but it becomes real the day anything is parked relative to the PLAYER — it would have
  to follow both smooth-turn and physical turning, and getting only one right looks fine standing still
  and wrong in play.

### 9u. ⭐ THE TICK IS A VOLUME KNOB ON THE PENDULUM; DISABLING THE PENDULUM UN-HOOKS THE GOAT; THE GLASS BIND CAN NEED PRESSING TWICE (2026-09-12 night, `/lm`, Tefa wearing)

Note: `modding-notes/2026-09-12h-silent-invisible-goat-the-tick-was-a-volume-knob.md`.

- **`app.SimplePendulum` owns the sound.** Live field dump (`fn goat_pend_dump`, 23:32): `IsWwiseTrigger`,
  `TriggerHash 2156741340`, `WwiseContainerApp`, `SoundMaxDistance 14`, `Gain 1.0`, `DistanceGain`,
  `Gravity 9.8`, `PendulumList`, `TargetTransform`, `MaxUpdateDist*`, `Override*Gain`. **`Gain = 0`
  silences the tick; `Gain = 1` brings it back** `[verified-live 2026-09-12, n=2, A→B→A]`. `IsWwiseTrigger =
  false` alone: no effect `[verified-live, n=1]`. Harness: `pendset <field> <value>` (writes + reads back).
- **Do NOT disable the pendulum.** Two runs with it disabled (22:26 strip, 22:38 vanish) showed a
  full-size goat frozen in mid-air while the rig root read 0.001 and tracked the rifle; the run with it
  enabled (22:04) and tonight's final run showed the goat tiny on the rifle. The 22:38 run had exactly
  one `SPAWNED`, so the floater was not a stray. Reading: the visible mesh is a child the pendulum poses
  from the root each frame. `[hypothesis, n=2 consistent]` Supersedes the "stray from an un-destroyed
  earlier rig" reading in §9t / the 22:34 code comment.
- **The glass bind can be undone between the bind and the look.** 23:46 run: `glass: 2 slot(s) bound`
  logged, mirror latched, rig alive — Tefa saw the **stock** lens (red crosshair, beige). A second
  numpad-`*` after the shrink stuck. `[verified-live, n=1]` The guard that would re-bind is disabled
  (no stable texture identity — see the guard comment in `Plugin.cpp`), so the bring-up must bind late,
  and re-bind if the stock reticle is visible. Who undoes it is not known (`app.VrWeaponSniperScopeLensUpdater`
  is the obvious suspect and is untested) `[hypothesis]`.
- **Can enemies break the goat? Unknown.** It is a breakable prop and the rig keeps `app.HitController`,
  `app.ProcDamage` and `via.physics.Colliders`; disabling those three is known-safe for the rig (the 22:26
  strip did it) and is the cheap insurance. `[hypothesis]`
- **⛔ 00:28 — "THE PICTURE IS FROZEN" — `[disproved 2026-09-13 00:40]`, see the bullet below it.** Two stills ten
  seconds and a long walk apart show the same mountain and sky inside the scope `[verified-live 2026-09-13,
  n=1 wearer, 2 stills]`. Tefa: *"the picture does not change when i change locations."* So the 23:53 "both
  wells" reading is also consistent with a **stale frame**, and tonight's rotation work may have been chasing
  the rotation of a still image. Candidates, cheapest first: **(1) the engine stops updating a mirror whose
  host prop is 0.001 across** — this prefab already carries distance gating (`MaxUpdateDistCommon=13`) and the
  shrink is new tonight; **(2) the plugin's latched source is a stale allocation** — this launch logged
  `rig rebuild #1: the latch had already followed 3 ticks before the rebuild counter was read`; **(3) the
  mirror camera is not ticked** — weakest, the rig heartbeat read `update=true draw=true` all evening. All
  `[hypothesis]`. First test: `fn goat_unshrink`, walk, look. ⚠️ `rt=false` in the heartbeat is not evidence
  either way — it printed `false` while the picture was live.
- **✅ 00:40 — THE PICTURE IS LIVE; IT IS AIMED AT THE HORIZON.** Tefa: *"the picture still moves when i turn my
  head or the weapon … only moved forward … but if i move the gun or my head, it still changes and rotates"*
  `[verified-live 2026-09-13, n=1 wearer]`. **Rotation changes it, translation does not** — which is what a live
  mirror looking at sky and far mountains does, since distant geometry has no parallax. Both 00:28 stills showed
  a ridge and sky and nothing near the player, so they matched. The freeze reading and its three candidates are
  withdrawn. ⚠️ **Method note:** the freeze hypothesis was ranked and boarded on ten seconds of evidence and
  removed by one sentence from the next look; the check that would have pre-empted it is *does it respond to
  rotation?* To test "is it live" properly, aim at something a few metres away and strafe — near geometry has
  parallax, distant scenery cannot answer the question.
- **The real fault, stated sharply:** the disc shows the horizon rather than where the barrel points, and rotates
  with head and rifle. Same fault as `n-vs-lua ≈ 38°` — the plugin's recomputed plane is tens of degrees from the
  Lua's. Fix the plane, not the roll knob.
- **⭐ 00:50 — THE REFLECTION DEGRADES WITH DISTANCE FROM THE SPAWN POINT, AND THE PROP IS NOT THE CAUSE.**
  Tefa: *"the further away i go, the more things get nonsensical, lot of sky and stuff, when i get closer to the
  goat spawn point the more it looks like the world"* — with birds visible at distance at some angles, so the
  view is live. **The prop is riding the rifle**, measured from the log: rig↔rifle gap a constant ~1.2 m at both
  23:48 and 00:29, the pair ~30 m from the spawn, `rq` changing throughout `[verified-numerically 2026-09-13]`.
  So something OTHER than the prop is anchored to where the rig was built. Candidates, all `[hypothesis]`:
  (1) the reflection's draw volume was fixed at build time; (2) a captured scene layer still points at a camera
  left at the spawn (the dangling-camera lesson); (3) the plane travels but the scene reference was resolved
  once. **First test, two commands, no rebuild:** destroy and re-create the rig far from the original spawn and
  see whether the good region moves with it.
- **Final state 23:53** `[verified-live, n=1 wearer]`: goat ×0.001 on the rifle, silent, picture live.
  **`mrollsym 1` (side-flip) judged 00:05** `[reported, n=1]`: less chaotic, kept on. Remaining: picture sideways, not showing where the scope points; turning left rotates it counter-clockwise, and at the far end of a right turn it rotates back. That reversal at one extreme is the next session's spec.

### 9v. THE BRING-UP IS ONE COMMAND: `bringup` (2026-09-13, `/pd`, no launch)

Note: `modding-notes/2026-09-13a-the-whole-setup-is-one-command.md`. Built, deployed, stamped, **NOT run**.

- **`bringup`** in `re_scope_cmd.txt` replays §9u's working order through the harness's own `apply()`:
  `pfb_goat` → `p10` → (wait for rig, 10 s fail) → `drive_on`, `model 0`, `steer 1`, `mrollsym 1` →
  `goat_armour` → `goat_vanish` → (wait for `mirror_latched=1` in the plugin status file, 10 s warn) →
  numpad `*` → `*` again at +5 s and +20 s → `pendset Gain 0` → `bringup: DONE`. Refuses if a rig exists.
  `[verified-numerically 2026-09-13]` for the ORDER only (`scripts/tests/bringup_sequence_test.lua`, 23/23).
- **Only non-persisted settings are set.** The plugin persists `crop_follow`, `mroll_k/mode/src/off`,
  `ret_depth`, `eyedist` in `reframework/re_scope_vr_settings.txt`; the Lua's `steer`/`model` and the plugin's
  `mroll_sym` are not persisted, so those three are what `bringup` sets.
- **`goat_vanish` now silences** (`Gain 0` via the extracted `pend_set`, read-back checked). **`goat_armour`**
  disables `app.HitController`, `app.ProcDamage`, `via.physics.Colliders` on the ROOT only and reports (does
  not touch) matches on children. `[hypothesis]` that this stops enemies breaking the prop.
- **The re-binds are blind:** the undo §9u saw cannot be detected, and its timing was never measured, so
  +5 s / +20 s may be too early. Stock crosshair after `DONE` ⇒ send `bind` and note the time — that is the
  first measurement of when the undo happens. Keys go through the producer's VK queue
  (`_G.re8_scope_vk_push`), so the keys file still has one writer.

### 9w. ⭐⭐⭐ THE EXACT MAP: ONE HOMOGRAPHY FROM THE GLASS TO THE RENDER; FOUR FAULTS FOUND BY READING (2026-09-13, `/pd`, no launch)

Note: `modding-notes/2026-09-13b-the-exact-map-one-formula-instead-of-a-roll-knob.md`. Built, deployed, stamped, **NOT run**.

- **What a `via.render.Mirror` render IS:** the eye's view of the reflected world, in the eye's own screen
  coordinates (that is what lets the surface be textured by screen UV). So the picture's orientation at a pixel
  is the eye's screen orientation plus that pixel's perspective skew — §9r's v3 ("reflected up about the bore")
  equals it only with the gaze on the lens; 9–18° off and up to 23 % stretch at 20–40° off `[verified-numerically
  2026-09-13, geom_test case 6]`. **And the render is stored mirrored in u**: a horizontal mirror alone only
  inverts vertically, yet flat needs `flip_h` too `[inferred-static 2026-09-13]` — so every u read from it is
  1 − u, and the crop-follow centres never were. That is the "head left/right inverted" report.
- **`scope_geom_math.h`:** K = R_camᵀ·Refl_n·[rx ry d]; H maps glass tangent coordinates to render UV; the
  shader evaluates it per pixel (`geom 1`, boot default). Roll, warp, off-axis magnification, centre and flips
  are all inside H. 103/103 against an oracle built from `cf_reflect_point` + `cf_project_ndc`.
- **Four faults, all in the inputs and the sampler, none in v3's formula on-gaze:** (1) the plugin's plane
  recompute used the MUZZLE as the anchor, the Lua the LENS → the 12–53° `n-vs-lua`; (2) crop-centre u not
  mirrored; (3) the bore axis picked against the camera forward flips past 45° off-gaze → `roll meas` 148–168°;
  (4) the sampler rotates in a 4:3 frame while the in-world glass shows the RT's UV square as ~1:1 (the
  2026-09-12 headset frame's duplex bars: 0.6 R vs 0.82 R, ratio 0.73 ≈ 0.75 predicted `[measured 2026-09-13,
  n=1 frame]`) → a rotation becomes a shear = "warps while it turns". All four fixed or knobbed: `geom`,
  `glassaspect` (boot 1.333, judge by equal duplex bars), `geomhm`, `geomproj`, `crophm`; `flip_d` published.
- **§9s's `mrolloff` / `baked-roll` procedure is legacy-path only now** (`geom 0`). On the exact path there is
  no roll knob to set.
- **Limits:** which eye rendered the render (3 cm ≈ up to 8° of picture roll; `eye moved` in the `geom:` log
  line measures it); far field only; symmetric projection assumed.

### 9x. ⭐⭐⭐ WORN: STEERING OFF + THE EXACT MAP = "THE CLOSEST TO WHAT IT SHOULD BE LIKE" — 180° OFF, AND THE GOAT FLOATS (2026-09-13, `/ms`, Tefa wearing)

Note: `modding-notes/2026-09-13c-first-wear-of-the-exact-map-steering-off-is-the-closest-yet.md`; stills in `dev-archive/recon/2026-09-13-exact-map-first-wear/`.

- **`steer 1` + `geom 1`: still spins** — no improvement over 2026-09-12 `[verified-live 2026-09-13, n=1 wearer]`.
  The eye→lens ray sat 65–90° from the bore in VR carry; the steered plane tilts by half that.
- **`steer 0` + `geom 1` + `glassaspect 1.0`: the picture barely moves with the head and follows the rifle
  naturally** — first time the head stopped moving the world in the scope `[verified-live 2026-09-13, n=1
  wearer]`. Remaining: **rotated ~180°** (still `-142808`: roof down AND lantern swapped; log `exact-roll`
  174–180° throughout, stretch ~1.3, skew ~0) and **map centre at u ≈ 1.0** (half the samples off the render
  edge = the smeared "trail following my head"). One sign in H is wrong `[hypothesis]`; `geomhm 1` is the
  first A/B, a v-flip knob the second.
- **§9w's steered-plane premise is therefore demoted:** the exact map is right to use, but the plane it maps
  should be the BAKED one. The steered plane was the spin's source `[verified-live, n=1]`.
- **Duplex bars left/right longer at `glassaspect 1.333`** — as predicted for a ~1:1 glass `[verified-live, n=1]`.
- **The goat floats in BOTH rigs this launch, with and without armour** — armour cleared `[verified-live, n=2
  rigs]`; the root rides (hb ~1.2 m), the visible goat does not. Leading suspect: drive + shrink in the spawn
  frame (last night: +4 s / +20 s) `[hypothesis]`.
- `bringup` now boots `steer 0` + `glassaspect 1.0`.

### 9y. THE HEADSET EYE IS NOT A SYMMETRIC PINHOLE; THE "HALF-TURN" WAS PROBABLY A MIRROR; THE FRAME DUMP (2026-09-13 evening, `/pd`, no launch)

Note: `modding-notes/2026-09-13d-the-headsets-real-lens-shape-two-frame-knobs-and-a-frame-dump.md`. Built, deployed, stamped, **NOT run**.

- **The VR eye projection is asymmetric and its tan-aspect is not the pixel aspect:** the game's own matrix
  (vrlens probe 2026-09-12) `m00 0.985 m11 1.170 m20 0.174 m21 −0.211` → ~91° × 81°, tan-aspect 1.19 vs 0.93 in
  pixels, offset ~0.17 NDC `[verified-numerically 2026-09-13]`. The map now reads `get_ProjectionMatrix` every
  tick (row-vector form; transposed input detected) and logs it. The fov guess stays as `geomusep 0`.
- **§9x's "rotated ~180°" is demoted to "mirrored in one axis" `[inferred-static 2026-09-13]` (read from one wear's log):** the map's roll read-out
  was undefined (jumping −113…180°), which is what an improper 2×2 gives; the new build prints `IMPROPER`.
  Which input is reversed — `get_AxisY` vs the quaternion, or the lens material mirroring u (only v was ever
  checked, §9x's look-back) — is printed by the new `geomdbg:` line. Knobs `geomrot` / `geomflip` fix the
  picture meanwhile without touching the exact head/rifle behaviour.
- **`bringup` staggered** (drive +3 s, shrink +5 s more, then `goat_pend_dump`) for the floating goat `[hypothesis]`.

### 9z. THE ONE-FRAME FLICKER, READ FROM THE CODE: A DIFFERENT PICTURE FOR ONE FRAME, PROBABLY A POOLED BUFFER (2026-09-16, `/pd`, dev PC, no launch)

Note: `modding-notes/2026-09-16-the-one-frame-flicker-read-from-the-code-and-three-knobs.md`. Built, deployed on the dev PC, stamped, **NOT run**.

> ⚠️ **All nine builds in this section were run in the headset on 2026-09-17: read §9aa before relying on any bullet below.** Two work, one is a regression, and the premises of three are disproved. The bullets are left as written, as the dated record of what was believed before the run.

- **What the stills show, re-cropped:** the flicker frame is not the mirror picture with a rifle added;
  it is **another framing** (pedestal moved a third of the disc, a grey shape / a sleeve across it) while
  the frames either side are identical to each other `[inferred-static 2026-09-16, n=2 flicker frames]`.
  So the glass shows a *different render* for one frame with nothing moving.
- **The chain:** the Lua's holder is `movie_1920_1080.rtex` → the engine allocates an 8-bit sRGB target
  (fmt 29, flags 0x1) for that path; the plugin latches it, then **upgrades** to the next 1920×1088
  **R11G11B10_FLOAT, flags 0x5 (RT + UAV)** allocation — an engine intermediate that is path-bound to
  nothing of ours — and samples it directly at present time. Taken as a *first* source that kind of
  allocation showed **black** twice `[verified-live 2026-09-05, n=2]`, i.e. it is not always the mirror's.
- **Leading reading `[hypothesis]`:** the raw-HDR source is a **pooled** engine buffer that another pass
  sometimes writes; we then sample that pass's picture (a main-view framing with the rifle, sleeve,
  fence). Fits "random", fits `posehook` changing nothing. Alternatives ranked in the note: the other
  eye camera's mirror pass (B), a one-frame wrong mirror pose (C), the stock glass (D — does not fit).
- **Built, all off by default, all live through the pane file:**
  - `hold 1|2` — a 16×12 frame-change measure (mean |luma delta| vs the last *shown* scope image,
    read back each present). 1 = log spikes + a 25 s summary (`frames/spikes/holds/avg/max`, plus the
    eye-phase sign for reading B); 2 = re-show the last good frame on a spike, never twice in a row.
    `plugin/src/hold_math.h`, `tools/hold_test.cpp` 16/16 `[verified-numerically 2026-09-16]` — the
    first draft held every other frame of a steady pan (36 Hz judder); the test caught it, the frame
    after a spike is now always shown and the average adapts to it. `holdt` sets the threshold (0.08).
  - `src8 1` — the 8-bit resolve is now **kept** on upgrade (`hook::mirror_sdr`) and can be sampled
    live. Path-bound, so nothing else writes it: **flicker gone on `src8 1` ⇒ the pooled buffer is
    the cause.** Sunlight clips to white there (§4's 2026-08-31 finding), so it is the test, not the fix.
  - `fn rtex_hdr` (before `bringup`) — an authored **float `.rtex`** (`scope_1920_1080_hdr.rtex.5`,
    1920×1088, format 26 = what `mirror_env.rtex` ships in). Raw HDR without the upgrade. The plugin
    takes a fmt-26 first source only while the Lua says it rigged this (pane `rtex_hdr=1`) and never
    with UAV. Expected log: `latched: 1920x1088 fmt=26 flags=0x1`, no `UPGRADED`. `[hypothesis: the
    engine allocates a float .rtex as flags 0x1]`.
- **The diagnostic that would show the derivation wrong:** `hold 1` logs no spikes while flickers are
  seen ⇒ the change happens *after* our blit (the lens material / the engine's own glass draw).
- Also: the dev PC now runs the home PC's build (scripts identical, plugin from the same source) plus
  these knobs, stamped 14/14; the 2026-09-06 authored 2560/3840 descriptors re-authored into
  `staging/…/natives/`. The **patched REFramework (`mirror-exemption.patch`, v2 + plan C) exists only
  on the home PC**, nowhere in git — a `[PD @home]` row.

- **The save-reload "security camera" is the same weakness in slow motion (2026-09-16b, `/pd`):** a
  rebuild after a reload REUSES the path-cached holder (no new allocation), so the retired 8-bit
  resolve keeps receiving the new mirror's picture while the upgraded HDR buffer is left aimed at
  nothing — `the latch did not change` `[inferred-static 2026-09-16, from the 2026-09-13 log lines]`.
  Built (default ON, `rbfb 0` off): on every rig rebuild the plugin swaps back to the kept 8-bit
  resolve, retires the HDR buffer, and the upgrade watch reopens for the next fmt-26 allocation.
  Harness `rerig` = teardown + `bringup` in one word. Note: `modding-notes/2026-09-16b-the-save-reload-security-camera-falls-back-to-the-buffer-that-follows.md`. **Not run.**

- **The weapon-switch glass flash (2026-09-16c, `/pd`):** the plugin restored the stock glass the tick the
  equipped weapon changed, while the rifle stays in view ~1 s being put away `[inferred-static 2026-09-16]`.
  Built, off by default: `swdelay <ms>` schedules that restore instead (the glass holds its last frame), and
  cancels it if the same rifle returns first. Not established: whether the old rifle's mesh is still alive
  when a delayed restore runs `[hypothesis]` — binds hold no ref on it. Note: `modding-notes/2026-09-16c-the-weapon-switch-glass-flash-a-restore-that-waits.md`. **Not run.**

- **Which scope is fitted is not on disk (2026-09-16d, `/pd`):** the rifle's in-hand prefab references ONE
  mesh, `it02_070_Sniperrifle_01`, whose material file holds `A_Mat`, `B_Mat`, `Lens_Mat` and `Lens2_Mat`;
  both lens materials use `Weapon_SniperScopeLens2.mmtr` and the same `Reticle_Low_ALBA` texture; the
  configuration `.user` names no scope part `[inferred-static 2026-09-16]`. So unless the high-magnification
  scope is a separate attached object, the scopes differ by a runtime switch `[hypothesis]`. Built: a
  read-only `scope-signature:` log line on every glass bind (per-material enable flags; part bits only if a
  part-enable call AND a count accessor exist). Note: `modding-notes/2026-09-16d-zoom-per-scope-which-scope-is-fitted-is-a-runtime-switch.md`. **Not run.**

- **The hidden prop was parked 1.245 m from the rifle, and only its drop moves the mirror (2026-09-16e, `/pd`):**
  the producer adds 1.0 m forward, 0.2 m down, 0.715 m left to the rifle pose (the 2026-08-30 flat tuning).
  The worn pane's normal is the rifle's up/down axis, so forward and left lie IN the plane and cannot change
  a planar reflection; `plugin/tools/prop_offset_check.cpp` on the shipped `cf_pane_from_rig`, 5/5
  `[verified-numerically 2026-09-16]`. The exact map uses the plane direction only `[inferred-static 2026-09-16]`.
  Built: harness `propnear` (in `bringup`) / `propoff` / `propf|propu|propr`. Open: whether the engine's mirror
  clips by its host's bounds, and whether a host out of view stops the mirror `[hypothesis]`. Note: `modding-notes/2026-09-16e-the-hidden-prop-was-parked-a-metre-away-and-only-its-height-matters.md`. **Not run.**

- **Scoped spread: no field is named on disk (2026-09-16f, `/pd`):** the rifle's files reference only
  `app.WeaponGunCore` among gameplay types; field names live in the running game's type database
  `[inferred-static 2026-09-16]`. Built: harness `spreadprobe`, read-only — the plugin logs every `app.*`
  gun/weapon/aim type's spread/recoil/accuracy-like fields and methods (capped 160), then the equipped
  weapon object's numeric fields with values, one level into parameter-like sub-objects (capped 220).
  Reading `[hypothesis]`: "holding RG first" is the aim state that narrows spread. Note: `modding-notes/2026-09-16f-scope-spread-no-field-on-disk-so-a-read-only-probe.md`. **Not run.**

- **The jitter, read (2026-09-16g, `/pd`, Fable):** the exact map is directions-only, the mirror's viewpoint is
  the REFLECTED EYE, and in the headset the rendering eye alternates every tick (`eye moved` ≈ IPD, 2026-09-13c
  log) — so a fixed bore direction from a hopping viewpoint lands on a different world point each frame: 0.37°
  at 10 m for 64 mm, ~3% of the 2.4× disc `[hypothesis, fits the "slight shake" and the frozen-picture test]`.
  The board's "H for the other eye" reading would be a jump of ~a fifth of the render (the 0.17 off-axis term)
  and does not fit the size. Built, off by default: `sg_eye_bore` + `eyepar 1` aims the frame at the bore's far
  point from this tick's reflected eye; `eye_parallax_test.cpp` 14/14 `[verified-numerically 2026-09-16]`
  (identity with an independent R(F) − E; 0.363° hop; 0.33° centre shift = the re-zero to expect). Residual
  parallax at other depths remains. Note: `modding-notes/2026-09-16g-the-jitter-is-the-eye-hopping-behind-the-mirror-and-a-per-eye-aim.md`. **Not run.**

- **The worn half-turn, explained (2026-09-16h, `/pd`, Fable):** the rifle root's +X points LEFT (geomdbg
  2026-09-13), so the frame builder's "follow the rifle's X" rule mirrors the map's upright (raw = `IMPROPER`,
  `geomflip 1` = proper roll 0 `[verified-live 2026-09-13, n=1 log]`), and the in-world glass shows the composite
  v-reversed (the 2026-08-28 `glass_flip_v` finding, never modelled). u-flip + v-flip = the worn `rot 180`.
  Built, off by default: `framev 2` builds that frame directly (`sg_rifle_frame_rh`: right = bore × up, up
  negated when the glass v-flips; `geomrot`/`geomflip` ignored) and `sg_rebase` makes roll / `IMPROPER`
  meaningful against it; `frame_v2_test.cpp` 25/25 reproduces the log's readings and proves the maps identical
  `[verified-numerically 2026-09-16]`. One look decides: identical picture + proper/roll 0 ⇒ make 2 the boot.
  Note: `modding-notes/2026-09-16h-the-worn-frame-explained-a-left-pointing-x-and-a-v-flipped-glass.md`. **Not run.**

- **Hand height (2026-09-16i, `/pd`):** REFramework's VR module reads `re8vr.left_hand_position_offset` /
  `right_hand_position_offset` (both names in `dinput8.dll`; no Lua defines `re8vr`). praydog's `re8_vr.lua` sets
  them once at load; its menu's "Hand Position Offset" sliders only replace a local copy, so they most likely
  never reach the hands `[inferred-static 2026-09-16]`. Built: harness `handhigher L|R <m>` writes the offset
  directly (up lowered by `<m>`, original remembered, 0 restores); stubbed test 5/5. Open: the offset's axis, and
  whether the module reads it every frame. Note: `modding-notes/2026-09-16i-hand-height-the-menu-slider-is-disconnected-so-a-direct-write.md`. **Not run.**

### 9aa. ⭐⭐⭐ WORN: THE NINE 2026-09-16 BUILDS — TWO WORK, THE SAVE-RELOAD FALLBACK BREAKS THE SOURCE ON EVERY `bringup`, THREE PREMISES DISPROVED (2026-09-17, `/ms`, home PC, Tefa wearing, three launches)

Note: `modding-notes/2026-09-17c-the-nine-builds-checked-in-the-headset-two-work-and-one-broke-the-sky.md`. Evidence: `dev-archive/recon/2026-09-17-the-nine-builds-checked-in-the-headset/` (launch 3's log lines extracted; launches 1 and 2 transcribed, because REFramework truncates the log at every launch).

- **⛔ DEAD END AS BUILT — the rig-rebuild fallback (`rb_fb`, §9z save-reload bullet) must not be on by default.** `bringup` rebuilds the rig as part of its normal run, and the fallback cannot tell that from a save reload. Launch 1: `UPGRADED to raw-HDR` at 22:16:03.987, `rig rebuild #1: source fell back to the 8-bit resolve` at 22:16:04.110, and no re-upgrade in the 35 minutes that followed. The wearer saw the 8-bit signature: black sky, golden colours. With `rb_fb=0` in the settings file, two further launches upgraded and stayed upgraded, and the wearer confirmed the sky and colours `[verified-live 2026-09-17, n=1 wearer; log n=3 launches]`. **`rbfb 0` live does not recover it:** the panel's latch re-arm logs `PENDING` and waits for an allocation that does not come; only a relaunch does. `rb_fb=0` is now in the `RTX` settings file. Whether the fallback cures the save-reload security camera is **still untested**; a rework has to tell a reload from `bringup`'s own rebuild, or re-upgrade by itself. **→ REWORKED 2026-09-18, see §9ab below.**
- **⛔ The hold measure reads exactly zero in VR, so `hold 1` and `hold 2` cannot work as built.** 23,400 frames measured, every summary `spikes=0 avg=0.0000 max=0.000`, at `t=0.080` and at the clamp's floor `t=0.005`, while the wearer walked, aimed and counted about 12 flickers in 2 minutes `[verified-live 2026-09-17, n=8 summaries]`. A moving picture cannot measure 0.0000, so the comparison returns nothing; the cause is not found. Slots, RTV, readback copy and shader re-read: nothing visibly wrong `[inferred-static]`. Cheapest next step: a flat launch. A non-zero `avg` flat puts the fault in the VR present path.
- **The flicker is NOT the pooled raw-HDR buffer (§9z reading A is out).** Launch 1 ran on the kept 8-bit resolve throughout, which is the buffer `src8 1` selects (`hook::mirror_sdr` on both paths `[inferred-static]`), and the wearer counted about 15 and about 12 flickers per 2 minutes on it `[verified-live 2026-09-17, n=1 wearer, 2 counts]`. The rate on raw-HDR was not counted, so nothing is claimed about the two being equal.
- **✅ `swdelay 1500` works:** no glass flash on 11 switches away from the rifle, the deferred restore fires 1.49–1.50 s later every time, no crash `[verified-live 2026-09-17, n=11 switches, 1 wearer]`. Now the boot value on `RTX` (`sw_delay=1500`). The early-return path was not exercised. **Seen beside it:** switching back shows the stock glass for one second, which is the auto re-bind's fixed `+1 s` first press (1.0 s in the log).
- **⛔ `framev 2` comes out upside down, vertical motion inverted.** Its diagnostics half is right: `geom:` went from `IMPROPER`, roll 129–140°, to proper, roll 1–5°. By the 09-16h outcome table the glass path therefore does **not** v-flip as `sg_rifle_frame_rh` assumes. The panel's `7 Glass flip V` then flipped `glassFlipV` to 0 in the compositor line and the wearer saw **no change**, so either `glass_flip_v` does not reach the picture under `framev 2`, or the inversion is elsewhere `[verified-live 2026-09-17, n=1]`.
- **⛔ The per-eye aim's premise is disproved.** §9z's jitter bullet says the reflected eye hops about 0.06 m every frame. `eyepar 1`'s own line reads `eye moved 0.000`–`0.001 m` on 200 of 231 ticks and 0.037–0.051 m on 7, six of them in one 32-second stretch while the wearer was crouching and standing `[verified-live 2026-09-17, n=231 lines]`. No visible change either way. Wearer's diagnosis: the whole rifle model carries a reprojection shake and the scope rides on it `[reported]`. Look upstream of the scope.
- **⛔ `re8vr.left_hand_position_offset` is writable, reads back, and does not move the drawn hand.** `y 0.0450 -> -0.0050 (reads back -0.0050)`, back, and again: no visible movement on any of the three `[verified-live 2026-09-17, n=3 writes]`. So the direct write is as disconnected as the menu slider. ⚠️ The first run of this test was reported as a clear improvement and had not happened: the click never reached the mod and the log had no `handhigher` line. **A helper click that leaves no `harness:` echo line did not happen.**
- **⛔ No prop height is clean, and height is the wrong knob.** Standing: `-0.4` jeans, `0.1` the rifle itself, `-0.2` and `0` clothing. Crouched: `-0.2` puts the picture half under the ground; `0.1` clears the ground and shows clothing `[verified-live 2026-09-17, n=1 wearer, 2 screenshots]`. Consistent with §9z's prop bullet: the virtual viewpoint moves twice the plane's offset, so a 20 cm drop is 40 cm below the bore. Hiding Ethan's body in REFramework's VR menu (`RE8VR_HideUpperBody` / `RE8VR_HideLowerBody`; not persisted across launches here) removed the clothing at `-0.2` `[reported, n=1]` and does nothing for the ground. Untried: switching those flags from Lua only while scoped; keeping the player's meshes out of the mirror pass. The mirror's clipping is still unstudied.
- **✅ `spreadprobe` works and confirms the static read:** only `isReduceRecoil = false` and `isRestrictAimShake = true` match; no numeric spread field on the live weapon, hip carry, high-magnification scope `[verified-live 2026-09-17, n=1 dump]`.
- **🟡 The scope signature prints on every bind** (`m0..m3=1`, `parts=present-but-no-count`), one scope only, so nothing to compare `[verified-live 2026-09-17, n=18 binds]`.
- **⚠️ A panel hotkey press persists live harness overrides.** The plugin saves the settings file on a knob press and writes the *live* values. Pressing `7` while `framev 2` was on wrote `frame_v=2` as the boot value; caught and reverted at the end of the session `[verified-live 2026-09-17, n=1]`. Left alone, the next launch would have started upside down with nothing in the log to explain it.

### 9ab. ⭐⭐ THE RIG-REBUILD FALLBACK: WHY IT FIRED ON `bringup`, WHY IT COULD NOT UNDO ITSELF, AND THE DISCRIMINATOR THAT FIXES IT (2026-09-18, `/pd`, dev PC — STATIC ONLY, THE GAME WAS NOT LAUNCHED)

Note: `modding-notes/2026-09-18-the-rig-rebuild-fallback-fired-on-the-wrong-event.md`. This explains and closes the `rb_fb` bullet in §9aa above; it supersedes nothing.

- **Two different events bump the Lua's `rig_gen` counter, and they differ in exactly one observable.** `bringup` builds the first rig of a process: the engine really allocates, so our latch moves and the raw-HDR upgrade lands behind it — **nothing is stranded**. A save reload rebuilds the rig, but `sdk.create_resource` returns the engine's **cached** resource for that path, so there is no allocation, the creation hook is never called, and **the latch does not move** — which is the stranding `[inferred-static 2026-09-18]`. **The latch moving is therefore the discriminator**, and it is the only one available.
- **⚠️ The test must be "did the latch move *around* this rebuild", never "does it move *after* it".** The allocation happens inside the Lua's rig call, but the rebuild counter reaches the plugin through a **~0.25 s pane-file poll** (`pane_file.cpp`, `(n % 15) == 7`), so on a healthy rebuild the latch has **always** already moved by the time the counter arrives. A naive after-the-fact test reads false on every good `bringup`. That race was already documented in the same file, and the rebuild watch already tested for it correctly — **the fallback merely ran first, unconditionally, ahead of that test**, demoting a source the next few lines then classified as healthy `[inferred-static 2026-09-18]`. Two correct pieces of code in the wrong order.
- **⛔ WHY `rbfb 0` LIVE COULD NOT RECOVER IT — the structural reason, and it generalises past this project.** The raw-HDR upgrade lives **inside the resource-CREATION hook** (`d3d12_hooks.cpp`), so it can only run when the engine *creates* a resource. "Re-arm the upgrade watch" is therefore not something the plugin can satisfy by itself; it is a bet that the engine will allocate another fmt-26 target. Once the engine has finished allocating its pooled HDR intermediates, that call never comes `[inferred-static 2026-09-18]`. **A fallback that gives something up must be able to get it back through a path it controls.** This one depended on the engine volunteering a replacement, which is a hope, not a recovery path.
- **The gate now lives in `plugin/src/rebuild_gate.h` (`rgate::decide`)** — pure, no D3D and no globals, so `tools/rebuild_gate_test.cpp` compiles the shipped logic rather than a copy of it (the same pattern as `hold_math.h`, `crop_follow_math.h`, `scope_geom_math.h`). `already_followed` = the latch moved within `kRebuildLatchFollowTicks` (150 ticks, ~2.5 s) **and** the latched source is the width the Lua says it rigged; the fallback fires only when that is false. The width is a second, independent signal: a recent latch at the wrong width is not this rig's. **22 checks, 0 failed — and the suite was proved able to fail:** reverted to the old logic it fails exactly the bringup and boundary cases, then passes again when restored `[verified-numerically 2026-09-18]`. All nine pre-existing suites still pass unchanged.
- **A held rebuild now says so in the log** (*"the fallback is armed but HELD … this is what bringup looks like"*), so the discrimination is visible rather than inferred from a missing line.
- **Two shipped defaults changed.** `rb_fb` **1 → 0**: off even with the rework in, because the rework is compile-verified only and the failure it guards against costs a relaunch — `rbfb 1` now arms it safely for an A/B inside one launch, which was not possible before. `sw_delay` **0 → 1500 ms**: headset-verified 2026-09-17, and ⚠️ **the dev PC's settings file had no `sw_delay` line, so this machine was still booting at 0** — the fix existed and was not in effect here. Both are named constants in `rsv.h` now (`kRebuildLatchFollowTicks`, `kSwitchRestoreDelayMs`), not literals.
- **⚠️ STILL NOT ESTABLISHED: the fallback has never been observed doing its actual job.** Nothing here tests whether it cures the save-reload security camera — only that it stops firing on the wrong event. A save reload landing within ~2.5 s of an unrelated latch change would read as "already followed" and be held; deliberate trade (holding is recoverable and still reported by the watch, firing wrongly is not), but unobserved `[hypothesis]`.
- **The one check for the next live session:** `bringup` with `rbfb 1`, then read the log. *"the fallback is armed but HELD"* = the rework works. *"the latch did NOT follow"* on a fresh `bringup` = the window or the width comparison is wrong, not the idea — that line prints `since`, which is the number to read.

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
