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

### 9ac. ⭐⭐⭐ THE PLAYER'S BODY: THERE IS NO WAY TO HIDE IT FROM THE MIRROR ALONE, SO IT MUST BE TIMED (2026-09-18, `/pd`, dev PC — STATIC ONLY, THE GAME WAS NOT LAUNCHED)

Note: `modding-notes/2026-09-18b-ethan-cannot-be-hidden-from-the-mirror-alone-so-hide-him-only-while-the-scope-is-up.md`.
Answers two of the three static questions on §9aa's clothing row; supersedes nothing.

- **⛔ NO PER-PASS EXCLUSION EXISTS.** The complete mesh draw-flag family is `DrawDefault`,
  `DrawShadowCast`, `DrawFarCascadeShadowCast`, `DrawEnvmap`, `DrawVoxelize` (plus a readable
  `DrawDepthOcclusionFlag`) `[inferred-static 2026-09-18, re8.exe type strings]`, and **none is
  planar-reflection specific**. `via.render.Mirror` itself has zero fields in its whole chain and
  eight methods, none geometric and none a layer or draw mask `[verified-live 2026-08-25, n=1]`.
  **So "draw this mesh in the main view but not in the mirror" cannot be expressed.** Hiding is
  all-or-nothing per frame and must therefore be *timed*, not masked. `DrawEnvmap` is the one
  member never tested against our Mirror; it is named for cubemap probes, so it is expected not to
  help `[hypothesis]`, and `bodyprobe` reports it per mesh so the guess is free.
- **REFramework's hide-body toggles are NOT reachable from Lua, and do not need to be.**
  `HideUpperBody` / `HideLowerBody` / `HideArms` are config keys and ImGui labels in `dinput8.dll`;
  the `sol` field list for `class RE8VR` contains no hide field, and the `reframework` Lua table has
  no config get/set `[inferred-static 2026-09-18]`. **The mechanism behind them is a plain engine
  call we can make ourselves:**
  ```
  app.PlayerMeshController        <- get_playerMeshController
    UpperBodyMesh LowerBodyMesh LArmMesh RArmMesh
    UpperBodyShadowMesh LowerBodyShadowMesh LArmShadowMesh RArmShadowMesh HeadShadowMesh
    FaceMesh HairMesh WeaponMesh OtherMeshList      <- REFramework touches none of these four
    set_DrawDefault(bool)  set_DrawShadowCast(bool)
  ```
  `[inferred-static 2026-09-18]` — which is **better** than the menu toggle, because it can be
  scope-gated instead of costing the player their body for the session.
- **⭐ THE GAME HAS ITS OWN "THE SNIPER SCOPE IS UP" FLAG.** `IsAimSniperRifle` sits on
  `app.PlayerMeshController` beside `IgnoreDepth` / `disableIgnoreDepth`
  `[inferred-static 2026-09-18]`. If it reads as its name suggests it is a better trigger than
  anything we can infer, and it is the first thing `bodyprobe` prints. ⚠️ String-table adjacency is
  ordering evidence, not proof the field hangs off this type at runtime.
- **Built, not run:** `re8scope/body.lua` with harness words `bodyprobe` (read-only) and
  `bodyhide 0|1|2 [body|arms|shadow|all]`. Inert until asked, edge-triggered, restores the value it
  found per mesh, and counts re-asserts so a fight with REFramework's own `AutoHide…Cutscenes`
  logic is visible as a number. 27/27 against a stubbed engine, suite proved able to fail three ways
  `[verified-numerically 2026-09-18]`.
- **⚠️ THE BET IS UNTESTED AND IS THE WHOLE THING:** a planar reflection re-renders the scene, so it
  *ought* to honour the same per-mesh `DrawDefault` — but that is `[hypothesis]`. If the body still
  shows in the scope with every mesh hidden, the reflection pass does not honour it and this route is
  dead. One flat launch decides it.
- ⚠️ **Machine-state finding:** the dev PC's install was still the **pre-split** producer (one
  6,758-line file, no `re8scope/` folder) while staging HEAD had carried the split since 2026-09-17
  — a whole milestone behind, unnoticed because `deployed.sh check` answers *"still what we
  stamped?"*, never *"is the stamp the newest build?"*. Brought to HEAD and re-stamped, 28 files.

Credit: **praydog** (REFramework, and the hide-body mechanism this reads).

### 9ad. ⭐⭐⭐ THE FLICKER MEASURE READS ZERO: THE LOG COULD NOT SAY WHICH OF TWO CAUSES IT WAS, SO THE READBACK IS NOW POISONED FIRST (2026-09-18, `/pd`, dev PC — STATIC ONLY, THE GAME WAS NOT LAUNCHED)

Note: `modding-notes/2026-09-18c-the-flicker-measure-reads-zero-poison-the-readback-so-the-two-causes-separate.md`.
Builds the instrument for §9aa's zero-measure row; supersedes nothing and settles nothing yet.

- **⚠️ A THIRD FULL RE-READ OF THE MEASURE FOUND NOTHING WRONG** — SRV `[4]`/`[5]` = our RT / `rt_prev`
  and the diff pass binds a 2-wide table from `[4]`; `diff_rt`'s RTV is written at index 2 and the
  pass sets index 2; `ps_diff` is correct as written; the mid-frame submit **does** `Reset` the
  allocator and list before recording the rest of the frame; `rt_prev` is copied from `g.rt` every
  frame and `g.rt` is redrawn unconditionally `[inferred-static 2026-09-18]`. **Reading it a fourth
  time is not the next step.**
- **⭐ THE ACTUAL OBSTACLE IS THAT `avg=0.0000` IS AMBIGUOUS.** Two unrelated faults produce it and
  the log cannot separate them: *the readback copy never landed, so the buffer is still its initial
  zeros*, versus *the copy landed and the shader genuinely computed zero*. The second means `t0` and
  `t1` sampled identical pixels — and since `rt_prev` is last frame's `g.rt`, that means **`g.rt` is
  not changing between frames**, which is a different problem with a different fix, upstream of the
  measure entirely. Two of the row's three candidates sit either side of that line.
- **Built:** harness word `holddiag <n>` / pane key `hold_diag`. For N frames it fills the readback
  with `kHoldSentinel = -12345.0f` **before** the GPU copy — a value a mean of absolute differences
  can never produce — then reports how much poison **survived**, plus min, max, exact-zero count,
  RT size, format, `rt_prev_valid` and the source kind. Four distinguishable outcomes: **all poison
  left** = the copy never landed; **some left** = footprint/row pitch; **none left and all zero** =
  the measure is real and `g.rt` is not changing; **none left, some non-zero** = the measure works
  and the fault is downstream in the averaging or threshold.
- Off by default and **counts down to zero by itself**, so the shipped path is unchanged when it is
  off `[compile-verified 2026-09-18]`. `holddiag 120` ≈ two seconds at 60 fps.
- The verdict is a pure function, `holdm::classify` in `hold_math.h`, so `tools/hold_test.cpp`
  compiles **the shipped logic** — the same shape as `rgate::decide`. `hold_test` **26/26** (was 16)
  `[verified-numerically 2026-09-18]`, and the suite was **proved able to fail**: dropping the
  `sentinels >= n_all` branch, so a fully poisoned read falls through to the zero check, fails 12a
  and nothing else — exactly the mistake the poison exists to prevent. All ten plugin suites pass.
- **⚠️ NOTHING WAS MEASURED.** This session built the instrument; it did not take the reading. The
  four verdicts are what it *can* say, not what it *will*. One flat launch: `bringup`, `hold 1`,
  `holddiag 120`, then read the `holddiag:` lines.

### 9ae. ⭐⭐ A SETTINGS SAVE WAS WRITING LIVE HARNESS OVERRIDES AS THE NEXT LAUNCH'S DEFAULTS (2026-09-18, `/pd`, dev PC — STATIC ONLY, THE GAME WAS NOT LAUNCHED)

Note: `modding-notes/2026-09-18d-a-settings-save-was-quietly-promoting-live-experiments-to-defaults.md`.

**Two kinds of thing move a knob here, and `save_settings()` could not tell them apart.** The numpad
(and the VR panel's numpad buttons, which feed the same handler) is *durable tuning* and is supposed
to be written to `re_scope_vr_settings.txt`. A harness word in `re_scope_cmd.txt` — `framev 2`,
`rbfb 1`, `hold 1` — is a *session experiment*, and every one of them ships with a "not commanded"
sentinel exactly so the settings value stands when nobody is experimenting. The save wrote every
knob's **live** value, so any numpad press captured whatever the harness was holding and made it the
default. Pressing `7` while `framev 2` was up wrote `frame_v=2`; caught and reverted by hand
`[verified-live 2026-09-17, n=1]`.

- ⚠️ **The failure mode is silence, not breakage.** The knob is already at that value, so nothing
  changes in the session that could catch it; the cost lands on the next launch with no harness word
  in sight. It is the direct inverse of the same week's `sw_delay` trap (a verified fix that was
  *not* made a default and so was silently absent on one machine). Both are the same question asked
  badly: what is a default, and what is a dial someone is holding?
- **The rule now: a key the harness can command persists the value it BOOTED with.** Decided per key
  per save, read fresh from the pane file each poll — the producer republishes every key every cycle
  and writes the sentinel when no word is in force, so nothing is remembered across a save and no
  flag can go stale `[compile-verified 2026-09-18]`.
- **25 of the 28 harness-reachable persisted keys needed it.** The other three — `crop_mode`,
  `crop_follow`, `aspect_mode` — were never affected: they got their own `g_lua_*` atomics on
  2026-09-06 and are merged at the point of use. That is the older, heavier form of the same idea.
- **A harness word can no longer be made permanent at all**, by accident or on purpose. To keep one,
  edit `re_scope_vr_settings.txt` by hand, which is what `RTX` already did for `sw_delay`. Deliberate
  trade: silence was the defect.
- **The save now logs one line naming every knob whose live value it declined**, what it kept and what
  was on the dial.
- **`geom_vflip` joined the settings file in the same change:** `load_settings()` had always parsed it
  and `save_settings()` had never written it, so a hand-edited line was deleted by the next numpad
  press. `hold_diag` stays load-only on purpose — it is a countdown.
- `bootv::persist_value` is pure, so `tools/boot_values_test.cpp` compiles the shipped logic:
  **152/152**, four of its nine sections re-deriving the registry from `config.cpp` and
  `pane_file.cpp` as text `[verified-numerically 2026-09-18]`.
- ⚠️ **THE MUTATION RUN FOUND A HOLE IN THE TEST, AND THAT IS THE DURABLE LESSON.** Five deliberate
  breaks; four caught. The fifth — gutting the one call that marks a key as commanded — **passed all
  148 checks with the bug fully restored**. Every check verified a table or a formula and none
  verified the join between them, while reading as thorough. Check 9 covers it and all five mutants
  now fail. **A pure-logic suite around a wiring change tests the ends, not the join.**
- **All twelve plugin suites and all nine producer suites pass.** Deployed and stamped (28 files).
  ⚠️ **NOT RUN.** One flat launch says it: set a harness word, press a numpad key, read the settings
  file for the decline line.

### 9af. THE VR PANEL CAN SEND HARNESS WORDS, SO A TEST NEED NOT LEAVE THE HEADSET (2026-09-18, `/pd`, dev PC — STATIC ONLY)

The panel spoke only numpad virtual-key codes, so every harness word meant leaving Virtual Desktop,
typing at the desktop and coming back — per knob, mid-test. 21 buttons now write the word straight
into `re_scope_cmd.txt`.

- ⚠️ **The harness consumes that file by writing it EMPTY, not by deleting it**, so "already taken"
  is an *empty read*. The existing key queue's missing-file test is correct for *its* file and would
  be wrong here — it would overwrite queued words and lose them unseen `[inferred-static 2026-09-18]`.
- The harness applies **every** line it finds, so several clicks in one poll window travel together
  and all run. `hold 1` then `holddiag 120` is the intended pair.
- `scripts/tests/panel_words_test.lua` **132/132**, reading the harness's own dispatch rather than a
  kept list: every button's word must be one the harness knows, a word needing a value must be given
  one, no two buttons may share a label (imgui keys on the label, so a duplicate silently stops
  responding), and the flush must be called and must guard on a non-empty read. Proved able to fail
  on all five `[verified-numerically 2026-09-18]`.
- The panel says on screen that a word is a session experiment and will not be saved — §9ae made
  visible where someone would otherwise be surprised by it.
- **Keeping the log across launches** (same session, cheap): REFramework empties
  `re2_framework_log.txt` at every start and the 2026-09-17 session lost two of three logs.
  `mod/helpers/KEEP-LOG.bat` copies it aside with a timestamp; `mod/helpers/LAUNCH-VILLAGE.bat` calls
  it and then starts the game through Steam. Tested on a fake log in a scratch folder, exit 0
  `[verified-numerically 2026-09-18, n=1]`; the launcher itself was **not** run.

### 9ag. ⭐⭐ `framev 2` IS UPSIDE DOWN BECAUSE ONE FLAG DRIVES TWO FLIPS IN SERIES — WHICH IS ALSO WHY NUMPAD 7 IS INERT (2026-09-18, `/pd`, dev PC — STATIC ONLY, THE GAME WAS NOT LAUNCHED)

Note: `modding-notes/2026-09-18e-framev-2-is-upside-down-because-one-flag-drives-two-flips-in-series.md`.

The 2026-09-17 session reported two things that read as separate complaints and are one fault: the
`framev 2` picture is upside down with vertical motion inverted, and `7 Glass flip V` flips
`glassFlipV` in the log with **no visible change** `[verified-live 2026-09-17, n=1]`.

- **`glass_flip_v` is read TWICE on the same path, in series.** `crop_follow.cpp` derives `vneg` from
  it, which negates the frame's `ry` and so flips the scope image's **content** through `H`; and
  `present.cpp` uploads the same flag as `ps_blit`'s `_pad.x`, whose `uv.y = 1.0 - uv.y` flips the
  **finished image** into the glass material. Two flips in series multiply:

  | `glass_flip_v` | frame `ry` sign | `ps_blit` sign | product |
  | --- | --- | --- | --- |
  | 0 | −1 | +1 | −1 |
  | 1 | +1 | −1 | −1 |

- ⭐ **The product is CONSTANT, so under `framev 2` numpad 7 provably cannot move the picture's
  vertical orientation** — and the orientation it is stuck at is the one the wearer called upside
  down. Under `framev 1` the frame never reads the flag, so only `ps_blit` moves and 7 works: that is
  why only v2 showed it. `[verified-numerically 2026-09-18]`, `tools/frame_v2_test.cpp` §6, which runs
  the shipped `sg_rifle_frame_rh` for both states.
- ⚠️ **The proof needs nothing about the lens material, and deliberately establishes only half the
  question.** *That* the product is constant is settled. *Which* constant it lands on — i.e. whether
  the fixed orientation is upright or inverted — depends on the lens material's own sampling sign,
  which is the game's property and is not visible statically. Two self-consistent models of that sign
  disagree, and the headset says one is wrong `[hypothesis]`.
- **So no sign was changed.** Picking one would be a coin flip dressed as a fix, and a wrong guess
  costs a wear to find out. Instead: **`framevneg -1 | 0 | 1`** forces the frame's half of the
  coupling. `-1` is the shipped behaviour and is the default, so nothing changes for anyone not using
  the word; `0` and `1` decouple the frame from `glass_flip_v`, which also makes numpad 7 work again
  under `framev 2`. §6 proves the two forced states are exact opposites, so **one of `framevneg 0` /
  `framevneg 1` is the right way up whatever the lens does** — a two-click A/B in one launch.
- Wired end to end and checked on all four links (`knob_chain_test` **46/46**, was 41); persisted, so
  it joined the §9ae boot-value registry, which `boot_values_test` re-derived by itself — **157/157**,
  was 152, **with no edit to that test** `[verified-numerically 2026-09-18]`. The three words have
  panel buttons, so the A/B costs no desktop trip.
- ⚠️ **A model is not the shipped code.** §6 computes the coupling from a model written in the test,
  which would go on passing if `crop_follow.cpp` or `ps_blit` changed underneath it — a green test
  describing a plugin that no longer exists. §7 therefore reads the three joins as text from
  `crop_follow.cpp`, `present.cpp` and `shader_src.cpp`. **Proved able to fail on five mutants, one per
  join plus the frame function itself** `[verified-numerically 2026-09-18]`. Same lesson as §9ae's
  mutation run, from the other side: there the pure logic was covered and the wire was not; here the
  maths would not have noticed being disconnected from the plugin.
- **NEXT LAUNCH, one trip:** `framev 2`, then `framevneg 0`, then `framevneg 1`. Exactly one should be
  upright → that becomes the shipped default. **Neither** → the fault is not the frame's vertical
  baseline and §6 says the knob cannot reach it either; look downstream of `H`. **Both identical** →
  the word is not arriving; check the log for `frame_vneg -> ...`, because no echo means no test.
- ⚠️ While `framevneg` is `-1`, numpad 7 being inert under `framev 2` is **by construction**, not a
  new bug to report.
- Deployed (DLL, `panel.lua`, `pane.lua`, harness; `.bak-2026-09-18c` backups) and re-stamped, 28
  files. Twelve plugin suites and nine producer suites pass. **NOT RUN.**

### 9ah. ⭐⭐ THE RIFLE SHAKE: THE NUMBER THAT WOULD HAVE SEEN IT WAS AVERAGING IT AWAY (2026-09-18, `/pd`, dev PC — STATIC ONLY, THE GAME WAS NOT LAUNCHED)

Note: `modding-notes/2026-09-18f-the-number-that-would-have-seen-the-shake-was-averaging-it-away.md`.

The row asked for REFramework's weapon-pose path to be read. **It is not readable from here:**
`re8vr:update_hand_ik()` is a native method on REFramework's own sol object, living in its compiled
DLL; nothing on disk in the game folder contains it, and the Lua that is there only calls it
`[inferred-static 2026-09-18]`. But the row was blocked closer to home than that.

- ⭐ **`crop_follow`'s `self %.2f deg/tick` is a NET displacement sampled once a second.** The
  previous sample is taken INSIDE the `if ((tick % 60) != 0) return;` logging block, so the number is
  the angle between the pane normal now and one second ago, over 60. A rifle vibrating about a fixed
  direction returns to where it started and reads near zero — **for precisely the motion being
  investigated** — and anything faster than 1 Hz aliases. A **0.5° vibration reads as under
  0.01 °/tick** `[verified-numerically 2026-09-18]`.
- ⚠️ **It is load-bearing.** `self_rate` gates `pane_still`, which gates the pane-mismatch verdict —
  the one whose own comment says a false "DERIVATION error" costs a debugging session. 0.01 °/tick is
  well under the 0.35 threshold, so a shaking rifle reads as HELD STILL and that verdict can fire on
  the motion it was written to exclude. Never observed, and it also needs a ≥ 3° mismatch, so the path
  is real rather than the event `[hypothesis]`. `pane_still` now also requires a small accumulated
  PATH, which can only withhold judgement more often — the direction its own comment calls safe.
- **The measure: path beside net, accumulated EVERY tick.** `jitter_math.h`, pure, so
  `tools/jitter_test.cpp` compiles the shipped code. path = the sum of per-tick angular steps, net =
  first-to-last. A pan has ratio ≈ 1; a vibration has net ≈ 0 and a large ratio. Reported on the
  existing ~1 Hz `crop-follow` cadence — **no new knob**, because what had to move was the
  accumulation, not the reporting.
- Three traps, each its own check: **the accumulator must sit ABOVE the 1 Hz gate** (inside it is the
  original mistake, and §7 reads `crop_follow.cpp` as text to confirm); **angles from `atan2` of the
  cross product, not `acos`**, which is ill-conditioned for the hundredth-of-a-degree steps this is
  about; and **a quiet floor**, below which the ratio is forced to 1 rather than dividing two noise
  figures — without it a rifle on a table reads as a violent shake.
- ⭐ **The line also reports what the WEARER sees: bore travel × zoom.** A telescope multiplies
  angles, so at 6× a tenth of a degree of rifle wobble arrives at the eye as six tenths. **The picture
  looking far shakier than the rifle is expected, not a second fault**, and may by itself account for
  this reading as a scope problem.
- **jitter_test 28/28, proved able to fail on six mutants** `[verified-numerically 2026-09-18]`: path
  collapsed to net, the quiet floor removed, a degenerate reading folded in, `acos` restored, the zoom
  no longer multiplying, and the accumulator moved below the gate.
- ⚠️ **WHAT IT CANNOT SETTLE, stated up front.** It measures the rifle's direction per GAME TICK. It
  cannot see the runtime's reprojection, which resamples the head pose after the game thread is done.
  So the reading SPLITS the row: **large bore path / ratio ≥ 5** = the pose we are handed is already
  shaking, so the fault is upstream in REFramework or the controller and our scope is faithfully
  magnifying it; **small bore path while the wearer still sees shake** = the pose is clean and the
  shake is added after us, a different fault with a different owner; **large "at the eye" with a small
  bore path** = not a shake at all, just ordinary hand movement magnified. Guessing between those is
  what the previous attempts on this row did.
- **NEXT LAUNCH, no extra trip:** `cropfollow 1` for a few seconds holding the rifle as still as
  possible, then again while aiming smoothly, and read the two `jitter (last ~1 s):` lines — the
  second is the control that proves the measure is awake.
- Deployed (`.bak-2026-09-18d`) and re-stamped, 28 files. Thirteen plugin and nine producer suites
  pass. **NOT RUN.**

### 9ai. ⭐⭐ NOTHING CLIPS THE MIRROR — THE VIEWPOINT GOES UNDER THE GROUND, AND `off_u` DRIVES IT AT 2x (2026-09-18, `/pd`, dev PC — STATIC ONLY, THE GAME WAS NOT LAUNCHED)

Note: `modding-notes/2026-09-18g-nothing-clips-the-mirror-the-viewpoint-goes-under-the-ground.md`.

The row was filed as *"what CLIPS the mirror, for the ground when crouched"*. **The premise is
wrong.** Three facts already in this dossier, never put together:

1. the scope's picture is an **engine planar reflection** off a `via.render.Mirror`, so it is
   rendered from the camera **mirrored across the pane** — not from the rifle;
2. the worn pane's normal is the rifle's up/down axis, `(-0.0000, -1.0000, 0.0000)` in the rifle
   frame, i.e. the plane is **horizontal** `[verified-numerically 2026-09-16, prop_offset_check]`;
3. of the three prop offsets **only `off_u` moves that plane** — `off_f`/`off_r` slide the pane
   within its own plane and a planar mirror depends only on its plane `[verified-numerically
   2026-09-16, same tool]`.

- ⭐ **THE LEVER.** Reflecting across a plane moved by *d* along its normal moves the reflected point
  by **2d**. So **every centimetre `off_u` lowers the pane costs two centimetres of viewpoint
  height**, and the parked `off_u = -0.2` drops the eye the picture is taken from by **0.40 m**
  `[verified-numerically 2026-09-18]`. Walked over the wearer's scenario: standing with no offset
  leaves 0.80 m of clearance, the offset halves it, crouching spends most of the rest, and **crouched
  with the offset leaves 0.10 m** — the picture taken from ankle height, with another 0.1 m of pane
  putting it through the floor.
- ⚠️ **THIS IS WHY "no prop height is clean".** `off_u` has been used as a framing knob and is not
  one: it is the **only** offset that moves the viewpoint, at 2x gain, while the two that are safe to
  frame with cannot move it at all. Every framing attempt with `off_u` walked the viewpoint towards
  the floor. That reframes the knob rather than tuning it.
- **The floor is now published and reported.** The producer sends the player's own root Y (`foot_y`)
  through the pane file, reached by the same `re8vr.player` handle `body.lua` uses; the plugin reads
  it and the crop-follow block prints where the picture is taken from, the floor, the margin, the
  lever, and the `off_u` change that would leave 0.50 m of clearance.
- `mirror_ground.h` is pure, so **mirror_ground_test 28/28, proved able to fail on seven mutants**
  `[verified-numerically 2026-09-18]` — both factors of two, a degenerate normal, the edge-on plane,
  and each of the three wiring joins. ⚠️ §6 of that test exists because §§1-5 are arithmetic and would
  all keep passing with the floor never published, parsed or printed — the same reason `frame_v2_test`
  §7 and `jitter_test` §7 exist.
- ⚠️ **REPORTED, NEVER ENFORCED. No clamp was added.** That the wearer's "half under the ground" IS a
  sunken viewpoint rather than a clip is `[hypothesis]` — strongly supported by the geometry,
  unobserved. **Clamping a knob on a hypothesis is how a knob becomes a mystery**, and this project
  has two of those already. **The discriminator is free:** a CLIP shows a hard cut with correct
  content above it; a SUNKEN VIEWPOINT shows the underside of the terrain with the horizon moving the
  wrong way as you look around — and the `ground:` line gives the margin as a number, negative being
  underground.
- ⚠️ Also not established: the illustrative standing/crouched heights. The **lever** is exact and
  comes from the shipped reflection; the 0.80 / 0.10 figures assume plausible body heights and are
  replaced by real ones the moment the line prints.
- **NEXT LAUNCH, no extra trip:** scope up, `cropfollow 1`, read the `ground:` line standing and then
  crouched. A negative margin when crouched answers the row, and the fix is a clamp on `off_u` whose
  exact size that same line already prints.
- Deployed (DLL + `pane.lua`, `.bak-2026-09-18e`) and re-stamped, 28 files. **Fourteen** plugin and
  nine producer suites pass. **NOT RUN.**

### 9aj. THE ONE SECOND OF STOCK GLASS ON A SWITCH BACK WAS A BLIND TIMER, NEVER A MEASUREMENT (2026-09-18, `/pd`, dev PC — STATIC ONLY, THE GAME WAS NOT LAUNCHED)

- **The symptom.** Take the sniper rifle out again after putting it away and the scope shows
  Capcom's dark glass with the orange reticle for about a second before ours appears
  `[reported 2026-09-14, n=1 wearer; screenshot]`. The switch-*away* flash was already fixed by
  `swdelay 1500` `[verified-live 2026-09-17, n=11]`; this is the way back in.
- **The cause, read from `world_tick.cpp`.** The re-bind was scheduled blindly at a hard-coded
  `{ 1000, 5000 }` ms after the rifle returned — two presses, the pattern copied from what
  `bringup` needed `[inferred-static 2026-09-18]`.
- ⚠️ **The useful lesson is not that 1000 was too big, it is that 1000 was never compared with
  anything.** Nothing has ever logged when the bind would actually have succeeded, so shrinking the
  number would swap one guess for a smaller guess — and a press that lands too early fails
  silently, leaving stock glass up until the +5 s press, four seconds worse than the original
  complaint. **A blind timer with a safety net behind it hides its own error, in both directions.**
- **It was also wrong the other way.** Since the 2026-09-16 deferred restore, switching away and
  straight back leaves our glass never taken off — and the old schedule still fired both presses,
  each of which restores the stock texture and re-binds for nothing.
- **Now:** press on the very next tick and keep pressing every ~150 ms until the bind takes or 6 s
  pass, then log the milliseconds and the press count it really needed. The decision is a pure
  function in `src/auto_rebind.h` (same shape as `rebuild_gate.h`); the four numbers are named in
  `rsv.h` as `kAutoRebindFirstMs` / `RetryMs` / `GiveUpMs` / `MaxTries`.
- **Why retrying is safe** (read in `glass_bind.cpp` this session): `bind_scope_glass()` refuses
  outright without the holder, the rifle or the mesh and binds **nothing** when it refuses, so a
  failed attempt costs a log line and leaves `glass_has_binds()` false; it opens with
  `restore_scope_glass()`, so overwrites never stack; and it only ever touches the equipped rifle's
  own mesh with every original saved first `[inferred-static 2026-09-18]`.
- `[compile-verified 2026-09-18]` builds clean; deployed on the dev PC (sha256 `d883b41990035d99…`,
  235,520 bytes), previous build kept as `.bak-2026-09-18f`.
  `[verified-numerically 2026-09-18]` `auto_rebind_test` **45/45**, proved able to fail on **nine**
  mutants of the shipped header, all nine caught, restored and re-run at 45/45.
- ⚠️ **`[hypothesis]` that the glass is bindable sooner at all.** That is what the instrument is
  for. **NOT RUN.** The check: switch away and back, and read
  `auto re-bind: the glass took after N ms, K press(es)`. N well under 1000 answers the row; N near
  1000 means the delay is not the timer and the refusals logged above it say which precondition is
  holding it.

### 9ak. THE SCOPE PICTURE IS BLACK ON THE HOME PC WITH THE HEADSET OFF - AND IT IS NOT A BUILD REGRESSION (2026-09-18, `/lm`, home PC `RTX`, FIVE LAUNCHES, FLAT)

**The first time the home PC ran this project's group-A tests, the thing all of them depend on turned
out to be broken, and it is not what anyone would have guessed.**

With the rifle scoped and `bringup` reporting `DONE`, the scope picture is **pure black** - only our
two green debug markers are drawn on it. The disc sits at ~(963, 522) r~140 in a 1920x1080 capture,
exactly where `dev-archive/tools/scope_metrics.py 963 522 135` expects it, which is how we know the
black disc is our picture and not part of the scope model. `[measured 2026-09-18, n=5 launches]`

**Every indicator says the picture is fine**, which is the trap: `glass_bound=2`, `mirror_latched=1`,
`mirror_hdr=1`, `mirror_ui=1`, `frame:` reports `mirror=1 src_w=1920` at 160-207 fps, `bringup` prints
no `FAILED` and no `WARNING`. `hold 1`'s summary prints `avg=0.0000 max=0.000 spikes=0 holds=0`,
consistent with a constant black source. `[measured 2026-09-18]`

**Ruled out, in order** (evidence: `dev-archive/recon/2026-09-18-flat-scope-picture-is-black/`):

1. **The scene** - turned 180 deg from the Duke's shop to the open village: identical black disc.
2. **The source format** - `src8 1` (8-bit resolve instead of raw HDR) changed nothing.
3. **A stale latch, via the documented recovery.** Every launch prints the ambiguous wave-2 line
   *"rig rebuild #1 at the latched width (1920) and the latch did not change ... if it is frozen or
   wrong, the latched source was never this rig's (a boot latch) - numpad . and rebuild"*. Ran exactly
   that: the re-arm went **PENDING**, no further `MIRROR SOURCE latched` line arrived, picture still
   black. **So that recovery text is wrong, or at least incomplete, for this case.**
4. **A dirty session** - cold relaunch, load, one clean `bringup`, nothing else: black.
5. **Today's build.** Restored the previous deployed plugin (217,600 bytes, 2026-09-17 stamp),
   relaunched, single clean `bringup`: **identical black picture, identical log shape.** Then restored
   today's build and re-stamped. `[measured 2026-09-18, n=1 per build]`

**The diagnostic built for exactly this could not speak.** `holddiag 120` is accepted and echoes
`hold_diag -> 120 frame(s)`, but **not one `holddiag:` line is ever printed**, so none of the four
2026-09-18 verdicts (SS 9ad) was reached. Because the `hold:` summary *does* print, the outer guard at
`present.cpp:604` passes and something inside it stops short - most likely `g.rt_prev_valid` never
becoming true. **Not confirmed.** `[hypothesis]`

WARNING: **SS 9ad's question is therefore still open.** `avg=0.0000` remains unexplained. What is new
is that the picture being measured is black, which makes *"THE MEASURE IS REAL AND THE ANSWER IS
ZERO"* the obvious candidate - but it stays a guess until a `holddiag:` line actually prints.

**THE LEAD, and it would change the board if true:** no confirmation of a working scope picture with
the headset OFF has been found anywhere in our own notes - every confirmation on record is a headset
wear. REFramework did **not** enter VR on any of these launches
(`XR_ERROR_FORM_FACTOR_UNAVAILABLE`, no headset connected), and `re2_fw_config.txt` carries
`VR_ExemptMirrorCameras=true`, `VR_MirrorUsesOriginalCamera=true`, `VR_RenderingTechnique_V2=2`. **If
the buffer our latch waits for is one REFramework only allocates in VR, the picture has never worked
flat and nobody noticed**, because all the judging was done in the headset - and every board row
gated `[FLAT]` that judges the picture (the 1920-vs-1280 sharpness, the `framev 2` / `framevneg`
up-or-down question, the clothing test's visual half) is mis-gated and actually needs `[VR]`.
`[hypothesis]` - handed to a static pass with the five logs and five screenshots.

**Do not tune anything on the picture path until this is settled.** A black picture makes every
visual A/B on this project meaningless, and three separate rows were about to be judged against it.

---

### 9al. WHAT THE HOME PC CONFIRMED THAT THE DEV PC COULD ONLY DERIVE (2026-09-18, `/lm`, home PC `RTX`, FLAT)

The same five launches closed several rows the dev PC had only reasoned about statically.

**The player-body access path is good, and the automatic trigger is real.** `bodyprobe` found
`app.PlayerMeshController` via `get_playerMeshController` (route 2 of three), and read
**`IsAimSniperRifle field=true` while scoped** - so SS 9ac's timed design has a working trigger and
`bodyhide 1` is buildable. Nine mesh fields present (`FaceMesh`, `HairMesh` absent); four drawable
(`UpperBodyMesh`, `LowerBodyMesh`, `LArmMesh`, `RArmMesh`, all `DrawDefault=true`); five shadow
meshes `DrawDefault=false ShadowCast=true`. `bodyhide 2` wrote 7 meshes with no failures.
`[verified-live 2026-09-18, n=1]` WARNING: whether hiding clears the **mirror** is still unknown - it
cannot be judged against a black picture (SS 9ak).

**The aim state does not live on the weapon.** `spreadprobe` run not-aiming and aiming on the same
save, diffed mechanically (75 lines each): **exactly one field differs** -
`<DrawOffByScope>k__BackingField` `false` -> `true`. That is a draw flag, not a spread value, and the
two spread-named fields (`isReduceRecoil=false`, `isRestrictAimShake=true`) are **unchanged** between
the states. So spread cannot be reduced by writing a weapon field; it lives on the player or in the
shot code. `[verified-live 2026-09-18, n=1 pair]`

Two by-products: **`isRestrictAimShake`** is a shipped flag directly relevant to SS 9ah's shake row,
and **`DrawOffByScope`** is a per-weapon "do not draw while scoped" flag relevant to both SS 9ac and
the hide-the-stock-scope idea.

**SS 9ae's settings-permanence fix works.** With `hold 1` and `framev 2` live, a numpad press produced
`settings saved, and 2 harness override(s) were NOT made permanent -- kept the boot value for: hold 0
(live 1), frame_v 1 (live 2).` and the file still read `hold=0` / `frame_v=1` afterwards. The
2026-09-17 `frame_v=2` accident cannot recur. `[verified-live 2026-09-18, n=1]`

**SS 9ah's shake instrument is awake.** Both states produced: `held still` (bore path 0.030 deg,
arrives at the eye as 0.07 deg at 2.4x) and the control `being aimed (smooth)` (bore path 0.177 deg).
`[verified-live 2026-09-18, n=1 each]` WARNING: not a shake test - the rifle was held by a script, not
a hand in a headset.

**SS 9ai's ground reading is healthy standing, and the lever is confirmed live.** `above the floor by
0.65-0.67 m`, `off_u lever -1.99` against the -2.00 derived statically. `[verified-live 2026-09-18]`
WARNING: the **crouched** half was not obtained - see the input gap below.

**The rig-rebuild fallback holds on a fresh `bringup`**: `re-arm pending=0 -- watching ~2 s`, then the
at-the-latched-width branch, never `the latch did NOT follow`. `[verified-live 2026-09-18, n=3]`

**Home-PC frame rate, flat, scope composited: 160-207 fps at 1920x1080.** The dev PC's numbers judge
nothing. `[measured 2026-09-18]`

**WARNING - AN AUTOMATION GAP THAT BLOCKS FOUR ROWS: the `ads` hook leaves the game in gamepad input
mode and does not reliably release it.** After `ads`, synthetic keyboard movement is ignored - `w`,
`c` and `lctrl` produced no change in `cam=` or in the `head` figure of the `ground:` line,
repeatedly, with `ads 0` sent and acknowledged first. The control profile already notes that pad mode
is entered *while held*; what is new is that **it does not come back**. This silently blocks the
crouch half of SS 9ai, the inventory work the stock-scope comparison needs, and SS 9aj's
weapon-switch measurement (`auto re-bind: the glass took after N ms` never printed, because the rifle
could not be brought back). The fix belongs with the `ads` hook: release pad mode properly on
`ads 0`, or drive movement through the pad the hook already owns rather than through `SendInput`.
`[verified-live 2026-09-18, n=several]`

**`LAUNCH-VILLAGE.bat` and `KEEP-LOG.bat` work** - five launches, five logs preserved, Steam started
correctly every time. They had never been run by anybody and their log-copying half had only been
tested against a fake log. `[verified-live 2026-09-18, n=5]`


### 9am. SOLVED, AND PROVEN LIVE: THE BLACK PICTURE WAS A BOOT MIS-LATCH, 1080 vs 1088 (2026-09-18, `/lm` home PC + static pass, CONFIRMED IN GAME)

**SUPERSEDES the `[hypothesis]` in SS 9ak that the mirror source might only be produced in VR.
That is now `[disproved 2026-09-18]`.** Flat has worked many times before, with screenshots, including
on this machine the day before (2026-09-17: *"The picture on the glass looked the same in both
captures"*, flat, no headset). **Do NOT re-gate the flat board rows.**

**The cause.** The mirror latch arms from process start with no "wait until the Lua has rigged" gate,
and its size window accepts heights 1050-1100. About one millisecond after REFramework initialises -
minutes before the scope rig exists - it grabs one of the game's own 1920x1080 render targets, which
satisfies the format test exactly. It then closes and never looks again, so the rig's real buffer is
never examined. **The scope was faithfully showing a buffer nothing draws into.**

**The tell is eight pixels.** The shipped mirror `.rtex` files carry name + 8 rows, so the real mirror
source always allocates padded: 1920x**1088**, 1280x**728**, 2560x**1448** (`rig.lua:125-127`). A latch
at 1920x**1080** is the desktop backbuffer size and by definition is not the mirror. Across every
archived log plus today's: **15 latches at 1088, 5 at 728, 1 at 1448, and a separate anomalous class at
exactly 1080.** `[measured 2026-09-18, n=46 latch lines]`

**What actually regressed.** Boot mis-latches at 1920x1080 are not new - they are in the 09-05 and
09-06 logs too. They used to be survivable because the rig preferred the **1280** target, whose
1280x728 allocation no boot buffer matches, so the re-arm caught it (the archives hold
`REPLACED 1280x728` lines doing exactly that). `rig.lua:122-124` now lists the **1920** target first,
and 1920 collides exactly with a 1080p desktop's own buffers - so the boot latch already looks right,
the re-arm has nothing fresh to catch, and the width-based rebuild check cannot tell them apart.
`[inferred-static 2026-09-18]`

**Why `numpad .` alone could not save it:** once both latches close, `d3d12_hooks.cpp:300`
early-returns on every later allocation, and `sdk.create_resource` then returns the **cached** `.rtex`
for that path - so no allocation ever fires again and the re-arm sits PENDING forever. That is exactly
what was observed. `[inferred-static]`, and the PENDING-forever behaviour is `[verified-live 2026-09-18]`.

### ⭐ THE WORKING RECIPE, PROVEN IN GAME (2026-09-18, home PC, flat, n=1)

**In a FRESH process, with the rifle in hand, in this order:**

```
fn rtex_1280        -- choose the 1280 target (its 1280x728 cannot collide with a boot buffer)
numpad .            -- re-arm BEFORE anything allocates it
bringup
```

Result, verbatim:

```
[hook] MIRROR SOURCE REPLACED on pending re-arm: 1280x728 fmt=29 flags=0x1
[hook] MIRROR SOURCE UPGRADED to raw-HDR allocation: 1280x728 fmt=26
rig rebuild #1: the latch followed (latch gen 3 -> 4, source now 1280 wide) -- not stranded
```

**and a live, correct, magnified picture on the glass.** Evidence:
`dev-archive/recon/2026-09-18-flat-scope-picture-is-black/06-SOLVED-...png`.
`[verified-live 2026-09-18, n=1]`

⚠️ **Order matters and the mod says so itself.** `fn rtex_1280` followed by `bringup` **without** the
re-arm produced `STRANDED LATCH: rig rebuild #1 rigged a 1280-wide target but the latch still holds the
1920-wide source`, and its own recovery text names the fix: *"numpad . BEFORE the first fn p10 on the
wanted width (a target allocates on its first use per process)"*. `[verified-live 2026-09-18, n=1]`

**The real fix, still to write** (no game needed): tighten the height window to the padded sizes only,
and/or do not arm the mirror latch until the Lua has rigged - the scope-target latch already has such a
gate and the mirror latch does not.

### 9an. ⭐⭐⭐ `avg=0.0000` IS A BROKEN READBACK, NOT A PROPERTY OF THE PICTURE (2026-09-18, CONFIRMED LIVE AGAINST A WORKING PICTURE)

**This retires the whole framing of SS 9ad.** With the picture **live and moving**, `hold 1` still
reports `avg=0.0000 max=0.000 spikes=0`, and `holddiag 120` still prints **not one line**.
`[verified-live 2026-09-18, n=1 with a confirmed live picture]`

So the zero was never about the scope image. The failing gate is **`present.cpp:666`,
`if (SUCCEEDED(g.diff_rb->Map(0, &rr, &p)) && p != nullptr)` - that Map is failing.** It is not
`rt_prev_valid`: the `hold:` summary sits downstream of the diag print inside the same
`if (g.rt_prev_valid)` block, so that flag is true and the diff path runs. Proof from the earlier run:
armed at 22:16:36, then 66,600 frames and 37 summaries with **zero** `holddiag:` lines and **zero
decrements**. `[measured 2026-09-18]`

Consequence: `d` keeps its initialiser `0.0f` and `holdm::decide` runs on a number it was never given.
**The flicker measure has never computed anything** - including the 23,400 VR frames on 2026-09-17 that
`holddiag` was built to explain.

⚠️ **The design flaw worth remembering:** holddiag's print is nested *inside the very `Map()` it exists
to test*, so its four verdicts can never include "the readback could not be mapped" - the one thing that
was actually happening. A diagnostic must be able to report the failure of the thing it is diagnosing.

One unverified suspect: the read range is `RowPitch * kDiffH` = 3072 bytes while `GetCopyableFootprints`
sizes the buffer at 2880 - a range past the end of the resource. `[hypothesis]`

### 9ao. UNDER `framev 2`, `framevneg 1` IS THE RIGHT WAY UP (2026-09-18, home PC, flat, SETTLED)

SS 9ag proved the two settings are exact opposites but could not say which was upright, because nothing
readable chose between them. Judged live against a working picture, aiming at the same scene without
moving between captures:

- **`framev 1` (the shipped baseline)** and **`framev 2` + `framevneg 1`** are **the same way up** -
  same roof slope, same sky, same foliage, same layout.
- **`framev 2` + `framevneg 0`** is the vertical mirror of both - **upside down.**

**So `framevneg 1` is the correct default under `framev 2`, and the row closes.** Evidence:
`07-framev1-baseline.png`, `08-framev2-framevneg0-UPSIDE-DOWN.png`,
`09-framev2-framevneg1-CORRECT.png`. `[verified-live 2026-09-18, n=1]`

⚠️ Note this was judged with `frame_vneg` **forced**; the shipped default is `-1` (auto, following
`glass_flip_v`). Whether auto lands on 1 in every configuration was not tested.

### 9ap. THE `DERIVATION error` WARNING IS INDEPENDENT OF ALL OF THIS (2026-09-18)

`crop-follow: the plugin's pane normal is N deg from the Lua's ... it is a DERIVATION error ... do not
tune, fix` fired four times on **2026-09-17 in VR while the picture was working** (3.0, 4.6, 4.3, 4.2
deg) and once today at 7.3 deg. Same pre-existing discrepancy, larger. **A real defect with its own row,
not a lead on the blackness.** `[measured 2026-09-18, n=5 firings across 2 sessions]`


### 9aq. ⭐⭐⭐ THE SMEAR IS THE CROP RUNNING OFF A FRAME DRAWN AT THE **EYE'S** FIELD OF VIEW — AND EXEMPTING THE PASS WOULD MAKE IT WORSE (2026-09-19, `/pd`, dev PC — STATIC ONLY, THE GAME WAS NOT LAUNCHED)

Answers the board's ⭐⭐⭐ `[PD]` row, which asked whether the mirror's field of view is ours to
widen before anything was built. **It is ours** — through the same getter the 2026-09-12 patch
already intercepts (§9l) — **but widening is the wrong fix, and the obvious cheap alternative is
backwards.** Tool: `plugin/tools/mirror_fov_check.cpp`, 20 checks, 0 failed, all four mutants
caught `[verified-numerically 2026-09-19]`. Built on two projection matrices already measured live
on 2026-09-12 (§9k, §9l), so it needed no launch.

**1. The two projections, in degrees.** A REFramework/glm perspective matrix carries the half-extents
in `m00`/`m11` and the off-centre shift in `m20`/`m21`; a point at angle `t` off the camera axis lands
at `NDC x = m00·tan(t) + m20`.

| | horizontal | vertical | off-centre |
| --- | --- | --- | --- |
| **forced** (what the mirror gets today — REFramework's HMD eye projection) | **90.88°** | 81.06° | `x +0.1736`, `y −0.2111` |
| **native** (what it uses when the pass is exempted) | **59.41°** | 51.32° | symmetric |

The native vertical reproduces the 51.3° recorded in §9l to 0.05°, which is the check that the
decomposition convention is right rather than assumed.

**2. ⚠️ THE CORRECTION THAT MATTERS: the mirror's own projection is NARROWER, by 15.73° a side.**
§9l's exemption — built, deployed and proven to fire — restores the native projection. Read as a fix
for the smear it is **exactly backwards**: it would take the half-width from 45.44° down to 29.71°
and make the crop clamp far sooner. The exemption remains right for what it was built for (stopping
a head-pose-dependent projection riding a non-eye view matrix); it is simply not this. `[verified-numerically 2026-09-19]`

**3. Where the crop first clamps — and it is NOT symmetric.** The crop window is small (half-width
0.0372 NDC across, from `lens_w` 240 px / `zoom` 2.4× / backbuffer 2688×2880), so what clamps is the
crop *centre* leaving the frame. Solving `|m00·tan(θ) + m20| = 1 − 0.0372`:

- **+38.71°** to one side, **−49.09°** to the other — **10.38° apart, purely because an HMD eye
  projection is off-centre.**
- **The board measured the bore 20–44° off the gaze while the smear was being seen.** That range
  straddles 38.71° exactly. This is the row's hypothesis turned into a number that could have come
  out wrong and did not.
- ⭐ **NEW, and never looked for: the second eye has the mirrored shift, so it clamps at +49.09° on
  the same side — a 10.38° window in which ONE EYE SMEARS AND THE OTHER DOES NOT.** Worth asking the
  wearer about directly; a stereo mismatch of that kind reads as discomfort long before it is
  identified as a picture fault. `[hypothesis]` — the arithmetic is exact, that it is noticeable is not.

**4. Fix (1) "draw wider" works, and it is not free.** The same render target then covers more angle,
so the scope — which magnifies — loses sharpness in proportion:

| hold the bore to | half-width needed | `m00` | sharpness left |
| --- | --- | --- | --- |
| 44° | 50.74° | 0.8172 | **83 %** |
| 50° | 56.49° | 0.6622 | **67 %** |
| 55° | 61.07° | 0.5526 | **56 %** |

**5. ⭐⭐ Fix (1b), which the row did not consider: STEER the projection instead of widening it.**
An off-centre shift moves *which* cone is drawn without widening it. Setting `m20 = −m00·tan(θ_bore)`
puts the bore at NDC 0.000000 at 0°, 20°, 44° and 60° `[verified-numerically 2026-09-19]`. `m00` is
untouched, so **pixels per degree are unchanged — 100 % of today's sharpness** — and because the crop
then sits at the centre of the frame it **cannot clamp at any angle**. The failure mode is removed
rather than pushed further out, and fix (2) (graceful clamping) becomes unnecessary rather than
cosmetic. Same hook, same patch site, strictly better on every axis measured.

**6. The plugin half is built.** Steering breaks both existing crop candidates — they describe a frame
centred on the gaze — so `crop_follow_math.h` gains **`proj = 2`**: under steering the crop centre *is*
the texture centre, by construction, at every NDC input. Compile-verified, and the existing suites still
pass unchanged (`crop_follow_test` 40 checks 0 failed, `prop_offset_check` 5 passed 0 failed)
`[compile-verified 2026-09-19]`.

**7. What is NOT established, and the real risk.**
- **That the engine will cull correctly against a strongly off-axis frustum.** At 60° the shift is
  `m20 = −1.71`, which puts the whole frustum to one side. Nothing here tests what RE Engine's culling
  does with that; objects popping at the frame edge is the predicted failure. **This is the main risk
  and it needs a launch.** `[hypothesis]`
- **That steering is reachable without a REFramework rebuild.** The change belongs in the fork at the
  site §9l's v2 patch already touches (`VR::on_camera_get_projection_matrix`, inside the mirror
  window: write a steered matrix instead of returning). The build tree exists **only on the home PC**
  — absent from the dev PC, checked 2026-09-19. Raised as `owed/HOME/2026-09-19-re-village-scope-steer-the-mirror-projection…`.
- **That the bore angle is available at that point in the frame.** The plugin already computes it;
  handing it to the REFramework hook is a wiring question nobody has answered. `[hypothesis]`
- The 20–44° range is `[measured 2026-09-19]` from one session; the clamp onsets are exact given the
  matrices, and the matrices are `n=1` `[verified-live 2026-09-12]`.

### 9ar. THE PANE SHOULD BE THE RIFLE'S VERTICAL CENTRE PLANE, AND THE LIVE RUN AGREED (inbox drained 2026-09-19, `/pd`)

Folded from `inbox/2026-09-18-mod-the-mirror-turns-the-picture-by-twice-the-gaze-to-plane-angle.md`,
which carries `Supersedes: ENGINE-DOSSIER.md §9ai (completeness of, not its arithmetic)`.

- **§9ai asked where the viewpoint sits; it never asked where the picture POINTS.** A planar mirror
  reflects direction as well as position, and **turns the view by twice the gaze-to-plane angle**.
  The shipped pose makes the plane **horizontal**, so it is correct only when head and rifle agree in
  pitch and **doubles every degree of disagreement** — §9h measured the hip carry at ~40° off the gaze,
  i.e. 80° of thrown picture. That is the *"picture is coming from above, like the camera is pointing
  down from the sky"* complaint, quantitatively `[reported 2026-09-18, n=1 wearer]`.
- **The pane normal was ALREADY perpendicular to the bore and always has been** (it is the rig's local
  +Y, and a transform's axes are orthonormal) — so "make the normal perpendicular to the barrel" was
  never an available improvement `[verified-numerically 2026-09-18, swept over the full pitch×yaw grid]`.
- **The fix is `pitch 90 / yaw 90`** — normal on the rifle's *right* axis, so the plane is the rifle's
  own vertical centre plane. Pitch mismatch of 0/10/20/30/40° throws the picture 0/20/40/60/80° under
  the shipped pane and **0.00° throughout** under this one `[verified-numerically 2026-09-18]`. With the
  eye on the plane and the gaze in it the reflection is the **identity**: the mirror hands us a second
  render of the player's own forward view, and the crop was always where the zoom came from.
- **Confirmed live the same evening** `[verified-live 2026-09-18, n=1]`: `off_u lever` −1.93 → −0.00,
  viewpoint `y` −34.00 → −33.07 against `head` −33.07 — **exactly at the eye**. Tefa, unprompted:
  *"for a second the picture on the scope showed the right picture with no clothing or anything, then
  turned to this"*. What replaced it is the scope's own tube, since the viewpoint is now at the eye
  looking forward. **`propr 0.20` clears it** — a clean, live, eye-height forward picture
  `[verified-live 2026-09-18, n=1]`, evidence `dev-archive/recon/2026-09-18-bore-plane-pane-pose/90-propr-0.20.png`.
- ⚠️ **Two expectations that would otherwise read as failures:** `IMPROPER` will NOT go away (a
  reflection has determinant −1 by definition) — what changes is that the flip becomes a *constant*
  horizontal one, cancellable once, instead of a vertical flip riding the aim. And **the muzzle remains
  geometrically unreachable**: every plane that delivers the viewpoint to the muzzle turns the picture a
  full 180°, every time `[verified-numerically 2026-09-18]`.
- ⚠️ **Unexplained and still open:** the one-second window where the picture was right before becoming
  the tube. If something re-poses the pane a second after the words land, that is a second bug sitting
  on a working fix.
- **Not withdrawn:** §9f (its disproof is of pane steering as a way to *decouple* from the head — this
  proposal wants the opposite); §9ai's arithmetic; §9g (narrowed to two candidates under this pose only);
  §9ac. Tool: `plugin/tools/bore_plane_check.cpp`, 23 checks, 0 failed, proven able to fail on a mutant.

### 9au. ⭐⭐⭐ THE PROJECTION WRITTEN AT THAT HOOK DOES NOT REACH THE SCOPE PICTURE — AND THE SMEAR IS IN BOTH EYES (2026-09-19, home PC, LIVE, wearer present)

**Supersedes: ENGINE-DOSSIER.md §9at (its "the hook is the right lever" claim only)** — and puts the
**premise of §9aq** in question. Neither section's arithmetic is withdrawn; what is withdrawn is
confidence about what the arithmetic is *about*.

- ⚠️ **The steer was driven to yaw −28.51° / pitch −24.30° — writing `m20` −0.1736 → **+0.5349** and
  `m21` −0.2111 → **+0.5280**, 56,400 times — and the wearer reported the picture did not change.**
  *"manual steer did nothing to the picture"* `[verified-live 2026-09-19, n=1]`. That is most of a
  frame-width of off-centre shift. **The hook fires inside a genuinely mirror-bearing scene layer,
  and what it returns is not what the scope draws with.**
- ⚠️ **Not a sign problem.** `VR_MirrorSteerInvert` flips *which way* the frame would move; it cannot
  turn no movement into movement. §9at's warning about the sign is still true and is now beside the
  point.
- ⭐ **CORROBORATION THAT WAS ALREADY ON DISK, UNREAD:** the 2026-09-12 build is named
  `…mirror-exemption_2026-09-12_TESTED-swing-unchanged-double-eye.dll`. **That patch wrote the same
  getter inside the same window, also fired, and also changed nothing.** Two attempts, two months
  apart, same site, same null result — a pattern that was visible before today's build was made.
- **Two candidates, not separated by this session:** (a) the mirror renders from a projection
  captured elsewhere and already baked by the time the layer draws, so this getter is observational
  for that pass; (b) the calls caught inside the window belong to some other consumer. Both
  `[hypothesis]`. Counters: `Mirror layer windows=1200 get_ProjectionMatrix calls inside=600
  get_ViewMatrix calls inside=600`, camera is `MainCamera` and `camera_is_primary=true`.
- ⚠️ **THE SMEAR IS IN BOTH EYES** — *"smear happens with both eyes"*, seen when first looking in and
  turning far left and far right `[reported 2026-09-19, n=1 wearer]`. §9aq §3 predicted a ~10° band
  where **one eye smears and the other is clean**. **That band was not observed.** §9aq itself said a
  `no` here "is a real problem for it"; it is recorded as one. The band is narrow and n=1, so this is
  not a controlled sweep — but it is the second independent result of the day pointing the same way,
  and the first is not subtle.
- ⭐⭐ **THEREFORE §9aq's PREMISE IS IN QUESTION.** Its argument begins from *"the mirror is drawn at the
  HMD eye's field of view, 90.88°"*, read from **this same getter** `[verified-live 2026-09-12, n=1]`.
  If the mirror does not render with what this getter returns, then that 90.88° describes something
  other than the scope's picture, and the crop-clamp onsets (+38.71° / −49.09°), the sharpness table
  and the match to the measured 20–44° bore range all lose their foundation. **The arithmetic was
  never wrong; what it is arithmetic about is now unclear.** The 20–44° match remains striking and is
  no longer evidence.
- **The decisive test is built and waiting: SHOUT mode** (`VR_MirrorProjectionShout`), which halves
  `m00`/`m11` inside the mirror window and so **doubles the drawn field of view**. Picture visibly
  pulls back → the projection is ours and the failure is narrower (probably the crop); picture
  unchanged → the projection is not ours and this whole approach moves elsewhere. Compile-verified,
  staged as `…mirror-steering-plus-shout_2026-09-19_NOT-YET-TESTED.dll`. ⚠️ Diagnostic only, never
  ship it on.
- **Unrelated but measured the same evening:** the 35 s bring-up is **59 ms of work** (`bringup:
  START` 22:59:35.518 → mirror component created 22:59:35.577) followed by **28 s of waiting** while
  the harness presses `bind` three times at +8 s, +13 s and +28 s, because one press does not
  reliably take `[measured 2026-09-19, n=1]`. Making it check whether the bind took, instead of
  waiting out the worst case every launch, would make a good bring-up effectively instant.
  ⚠️ Not attempted — and the same log shows a bind reporting *"no stable identity for the bound
  texture — the bind-order guard is DISABLED this session"*, which is the very signal that would have
  to be made trustworthy first.
- Field note: `modding-notes/2026-09-19d-the-steering-writes-the-numbers-and-the-picture-ignores-them.md`.

Credit: **praydog** (REFramework), **gmankab** (the `pd-upscaler` fork).

### 9at. THE STEERING FROM §9aq IS WRITTEN AND BUILDS — WHAT IS LEFT IS A FLAT SWEEP, AND THE SIGN IS STILL A GUESS (2026-09-19, home PC — STATIC + A BUILD, THE GAME WAS NOT LAUNCHED)

Carries out step 1 of `owed/HOME/2026-09-19-re-village-scope-steer-the-mirror-projection…`. **Does
not supersede §9aq** — it implements fix (1b) and adds what building it taught.

- **Where it went.** `VR::on_camera_get_projection_matrix`, inside the mirror window, in the fork at
  `D:\RE2 REFramework builds\tools\REFramework-src\` — the site §9l's v2 patch already touches.
  Committed as `dev-archive/reframework-patch/mirror-steering.patch` the day it was written, which
  the v2 patch was not.
- **What it writes.** `m20 = -m00·tan(yaw)`, `m21 = -m11·tan(pitch)`, `m00`/`m11` untouched. Behind
  `VR_SteerMirrorProjection`, **default off**, with manual yaw/pitch sliders (±75°) so it can be
  swept before any bore wiring exists.
- **It builds.** MSBuild `build/RE8.vcxproj`, Release x64: **0 warnings, 0 errors**, 20 s,
  `build/bin/RE8/dinput8.dll` 22.7 MB `[compile-verified 2026-09-19]`. Staged as
  `dinput8_pd-upscaler_76298bd_mirror-steering_2026-09-19_NOT-YET-TESTED.dll`.
- ⭐ **TWO PLACEMENT DECISIONS THAT DECIDE WHETHER THE TEST MEANS ANYTHING.** The branch sits ahead
  of the `is_hmd_active()` early-out **and** ahead of `is_camera_exempt()`. The first lets the sweep
  run **flat, with no headset**. The second matters more: `VR_ExemptMirrorCameras` **defaults to
  on** and returns without touching the matrix, so behind it the steer would never have executed and
  the session would have recorded "steering does nothing" about code that never ran. That is the
  classic "the fix removed the symptom and the failing path with it" trap, caught before it was sprung rather than
  after.
- ⚠️ **THE SIGN OF THE SHIFT IS `[hypothesis]`, NOT MEASURED, AND §9aq SHOULD BE READ THAT WAY TOO.**
  §9aq §1 states `NDC x = m00·tan(t) + m20`. That `+` came from reading a live dump through a Lua
  getter, **not** from RE Engine's clip convention; the opposite convention (`− m20`) is equally
  common in DirectX-style projections. If it is the other way round, steering moves the frame the
  **wrong way** and the crop leaves the edge roughly twice as fast — a dramatic, unmissable failure
  rather than a subtle one. A `VR_MirrorSteerInvert` tick cures it, and the first seconds of the flat
  sweep settle it. **Nothing downstream of §9aq should assume the sign until that sweep is read.**
- **The wiring question §9aq left open is answered.** `dinput8.dll` now exports
  `REF_SetMirrorSteerAngles(float yaw_deg, float pitch_deg)` and `REF_MirrorSteerIsEnabled()`,
  confirmed in the binary with `dumpbin /exports` `[compile-verified 2026-09-19]`. The scope plugin
  reaches them with `GetProcAddress(GetModuleHandleW(L"dinput8.dll"), …)` — same process, no
  REFramework API change either side. ⚠️ **Nothing calls them yet**; the plugin side is unwritten,
  and `VR_MirrorSteerFromPlugin` is off.
- **A diagnostic that separates two failures that would otherwise look identical.**
  `VR_SteerMirrorFromNative` steers the mirror's own 59.41° projection instead of the eye projection
  it is handed. "The steer never reaches the frame" and "it reaches it but the base matrix was the
  wrong one" then give different pictures.
- **Unchanged and still the main risk: culling** (§9aq §7). At 60° the shift is −1.71 and the whole
  frustum sits to one side of what the engine believes it is drawing. Objects popping in and out at
  the frame edges while the angle is swept is the predicted failure; nothing static can see it.
  `[hypothesis]`
- Field note: `modding-notes/2026-09-19b-the-steering-code-is-written-and-builds.md`.
- ⭐⭐ **CONFIRMED LIVE THE SAME EVENING: THE HOOK FIRES AND THE BASE MATRIX IS THE PREDICTED ONE.**
  6,600 projections rewritten inside the real mirror pass in about a minute, reading
  `m00=0.9848 m11=1.1696 m20=-0.1736 m21=-0.2111` — the exact HMD eye projection §9aq built its whole
  argument on `[verified-live 2026-09-19, n=1 launch]`. The plugin's own dump also showed the two eyes
  carrying **mirrored** shifts (`m20 = -0.1736` and `+0.1736`), which is the asymmetry that predicts the
  one-eye smear band. ⚠️ Captured with the sliders at 0, so it proves the hook REACHES the pass; it does
  **not** yet prove the drawn frame moves, and the sign stays `[hypothesis]`.
  Field note: `modding-notes/2026-09-19c-the-steering-hook-fires-live.md`, which also records two ways a
  driving script reported success while doing nothing (`timeout` under redirected stdin; a window title
  that does not exist), and one unresolved contradiction in the mirror-source latch log.

Credit: **praydog** (REFramework), **gmankab** (the `pd-upscaler` fork).

### 9as. THE LEFT-HAND OFFSET IS A VALUE RE8VR STOPS USING — OR THE HANDS WERE NEVER UPDATED AT ALL (inbox drained 2026-09-19, `/pd`)

Folded from `inbox/2026-09-19-mod-anomaly-vr-hand-and-controller-offsets.md`, a static read of
S.T.A.L.K.E.R. Anomaly's AoE VR mod as a reference implementation. **Nothing from that install is
committed here** — only setting names, values and the engine's own help text.

- **Anomaly's model:** every weapon names **two grip sockets** relative to a *named bone of the gun*
  (`secondary_grip_pos/rot`, often on a **moving** bone so the support hand rides the pump or bolt),
  plus one world-space **anti-occlusion offset** applied to the support controller's IK *target* before
  the two-point solve (`vr_secondary_ik_offset_y = −0.04` live here `[measured 2026-09-19]`). So the
  drawn support hand is **at a socket on the gun, not at the controller** — structurally, not as a fudge.
- ⭐ **RE8 already does the same thing, and that is why our lever looked broken.** `update_hand_ik()`
  latches "gripping" when the left hand comes within **10 cm** of where the *animation* says the support
  hand belongs, then executes `lh_pos = lh_grip_position` — **discarding the left controller entirely.**
  `re8vr.left_hand_position_offset` feeds only the branch that line overwrites, so writing it while
  holding the rifle **cannot** move the drawn hand. **It is not a broken binding; it is a value the code
  stops using.** `[inferred-static 2026-09-19]` — consistent with the `[verified-live 2026-09-17, n=3 writes]`
  dead end rather than contradicting it.
- ⚠️ **A second, simpler explanation must be ruled out first.** `update_hand_ik()` returns at the top
  unless `is_using_controllers()`, which is refreshed **only by button, stick and bound-action input —
  not by tracking motion** — against `VR_MotionControlsInactivityTimer=30.0`. **So after 30 s with the
  controllers parked on a shelf, which is the standing unattended-VR condition, no write to any offset
  can move the hand.** Indistinguishable from the above on the evidence we have `[inferred-static 2026-09-19]`.
  **Separate them before building anything** — the drop's §3a does it in one launch, free.
- **What does not transfer:** no per-weapon grip table in RE8 (the socket comes from whatever animation
  is playing) and no finger-pose system. Building a grip table is a project, not a knob.

Credit: **praydog** (REFramework).
