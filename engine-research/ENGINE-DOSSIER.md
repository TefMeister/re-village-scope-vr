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
- **`crop_follow`** (settings key, default 0) makes the mirror crop centre the aim pixel, with
  `mir_cx`/`mir_cy` re-read as a delta from 0.5. The sampled window is clamped inside the source
  unconditionally, so a wrong frame mis-aims but cannot sample out of bounds.
- **Practical trap worth keeping:** a deployed script diffed against its repo copy can differ on
  **every line** and still be content-identical — CRLF versus LF. That is also what a lost-work
  collision looks like, and the two are one `tr -d ''` apart. Normalise before concluding.

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
