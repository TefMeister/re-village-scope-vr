# REFramework forces the HMD eye projection onto EVERY camera — including the mirror's. And praydog already had to carve an exception for a scope

**Status:** 🆕 new · **Priority:** ⭐⭐ highest on this project — it names a concrete, mechanical cause
for "the picture inside is moving where I look and tilt", it is a `[PD]` fix rather than a headset
sweep, praydog wrote the same fix for RE4's scope three years ago, and RE8 ships Capcom's own VR
sniper-scope component that solves the problem a different way entirely.

## Why this was looked up

Two headset launches have now answered the ⭐ `[VR]` crop-mapping row the same way. Tefa, 2026-09-06
23:15, with the numbers reading correctly at the time: *"it is still acting the same, moving around
the pipe of the scope, and the picture inside is moving where i look and tilt"*
`[verified-live 2026-09-06, n=1 observer, 2 of 4 modes]`.

Dossier §9g's framing is that we do not know **which projection the Mirror renders with**, so four
candidate mappings were built and the headset would pick one. Modes 2 and 0 both swing. This session
asked the question of the public record instead — specifically of **REFramework's own source**.

## ⭐ The answer, and it is not an engine question — it is a framework one

### 1. `via.render.Mirror` natively renders with its OWN camera and its OWN projection

`[inferred-static 2026-09-07]`, from praydog's source:

- `via.render.layer.Scene` holds a `via.Camera*` immediately followed by a `via.render.Mirror*`
  (RE8 `re8.genny`; in the generated RE9 header the offsets are camera `0x88`, mirror `0x90`) — the
  pairing this project found live on 2026-08-30.
- REFramework's own helper treats "has a Mirror" as **"this is not the main view"**:
  `is_fully_rendered()` requires `get_mirror() == nullptr`, and `find_fully_rendered_scene_layers()`
  **erases every Scene layer whose `get_Mirror()` is non-null**.
- praydog states it plainly in issue #698: *"The way scopes work is they create a separate scene,
  yes."* `[reported]`

So §9g's dichotomy resolves to **"its own"** — natively.

### 2. …but REFramework's VR mod overwrites that projection with the HMD's, for every camera

This is the mechanism. In `VR::on_camera_get_projection_matrix`, the guard that would restrict the
override to the primary camera is **commented out**:

- the projection hook is installed on the *inner native* function that `via.Camera.get_ProjectionMatrix`
  calls, with praydog's own comment that it exists *"so we can override the camera's Projection matrix
  with the HMD's Projection matrix (per-eye)"*;
- `VR::on_camera_get_view_matrix`'s equivalent guard is **live** (`if (camera != primary_camera) return;`
  on `master`; on `pd-upscaler`, `if (camera != cameras[0] && camera != cameras[1]) return;`).

**The asymmetry is the bug's shape.** A mirror render in VR therefore gets:

> the current eye's **asymmetric, off-centre HMD projection** (per-eye aspect ≈ 0.93)
> applied on top of the mirror camera's **own, non-eye view matrix**,
> rasterised into a 1.76-aspect target.

A projection that changes with head pose combined with a view matrix that does not is **exactly a
picture that swings as you look and tilt**, and the aspect mismatch is baked in on top. `[inferred-static 2026-09-07]`

### 3. 🎯 praydog hit this exact problem on RE4's scope and fixed it by exemption

Commit `20a3ec5442`, 2023-04-06, message **"VR (RE4): Fix scope not being zoomed in"**: it adds a
block to `on_camera_get_projection_matrix` that checks the camera's owning GameObject name for the
prefix **`ScopeCamera`** and, if it matches, **returns without overriding** — praydog's comment:
*"Allows the sniper scope to work."* `[reported 2026-09-07]`

That is prior art for our fix, written by the framework's author, for a sniper scope, in the same
framework we are running. RE4 reaches its scope through a `ScopeCamera` GameObject where RE8 appears
to use a Mirror, so the *matching condition* differs — but the remedy is the same one line of intent:
**do not apply the eye projection to this camera.**

### 4. And there is a setting that already does it, on the branch family we run

`pd-upscaler` carries a three-way `RenderingTechnique_V2`: `ALTERNATING` (AFR), `SEQUENTIAL_FRAME`,
and **`MULTIPASS`** ("Native stereo rendering, single frame"). In MULTIPASS,
`vrmod::CameraDuplicator::get_relevant_scene_layers()` calls `find_fully_rendered_scene_layers()` —
**which erases every mirror-bearing layer** — and the projection override is restricted to
`m_multipass_cameras[0..1]`. **So under MULTIPASS the mirror layer keeps its own projection; under
the default sequential mode it does not.** `[inferred-static 2026-09-07]`

⚠️ This is a lead, not a recipe. It depends on which build we actually run, and **this project has
recorded no REFramework revision at all** — the open gap this lane filed on 2026-09-04 and which is
still unread in `engine-research/inbox/`. That gap now has a concrete cost: *whether the swing is
even expected depends on the branch and the rendering-technique setting.* Read the framework's
startup log first; it is one line and needs no launch.

## ⚠️ 5. A second, independent suspect: the right-eye pass skips `UpdateMovie`

In the default (non-AFR) mode REFramework replays the engine's `WaitRendering`→`EndRendering` chain
a second time inside the same frame to produce the right eye, having **erased** a specific list of
entries from the replay. That list includes **`UpdateMovie`**, with praydog's comment *"Causes movies
to play twice as fast if ran again"*. Everything not on the list runs twice per frame.
`[inferred-static 2026-09-07]`

**Our scope target is a `movie/rtex` target.** If anything on its refresh path is driven under
`UpdateMovie`, then **the right eye sees a stale image** — which would present as a lag that tracks
head motion, i.e. as swing. `[hypothesis]` This is cheap to separate from cause (2): log the target's
contents or a frame counter on both passes and see whether they differ.

Also erased from the right-eye replay, for the record: `WaitRendering`,
`UpdatePhysicsCharacterController`, `UpdateTelemetry`, `UpdateSpeedTree`, `UpdateHansoft`,
`UpdatePuppet`, `BeginRenderingDynamics`, `BeginDynamics`, `EndRenderingDynamics`, `EndDynamics`,
`EndPhysics`, `RenderDynamics`, `DevelopRenderer`, `DrawWidget` (and `RenderLandscape` when TDB < 73).

**One engine fact worth pinning up beside the crop maths**, from praydog's comment in
`on_camera_get_view_matrix`: *"the game **always** uses the main camera when calling this function,
even though it's rendering the other camera"* — so **the camera object a pass calls a getter on is
not a reliable indicator of which camera that pass is rendering.** Any instrumentation that assumes
otherwise will mislead.

## ⭐⭐ 6. RE8 ships Capcom's own VR sniper-scope component — and it does NOT do what we are doing

`app.VrWeaponSniperScopeLensUpdater` (hash `e6d05808`, CRC `654a7ac3`) is present in RE8's type
database, with these serialized fields `[reported 2026-09-07]`:

| field | type |
| --- | --- |
| `v0` | native 1-byte (the conventional enable flag) |
| `DistortionBegin` | `System.Single` |
| `ExpansionRate` | `System.Single` |
| `ReticlePosition` | `via.GameObjectRef` |
| **`LensLeftPosition`** | `via.GameObjectRef` |
| **`LensRightPosition`** | `via.GameObjectRef` |

**Separate left- and right-eye lens position anchors, a distortion onset, and an expansion rate.**
Capcom's VR scope does not reproject the render target per eye at all — it **moves and scales the
lens quad per eye against a fixed rendered image**, with a radial distortion/expansion term.

That is a shipped, first-party answer to the precise problem this project has spent two headset
launches on, and it is a **different strategy from every one of our four candidates**. It also
matches Tefa's *two* symptoms rather than one: *"moving around the pipe of the scope"* (the lens/eye
relationship) **and** *"the picture inside is moving where i look"* (the projection). Our four
candidates only ever addressed the second.

RE8 has **no** `_ScopeCameraObject`-style field, unlike RE4 — consistent with RE8 using a Mirror
where RE4 uses a ScopeCamera, and with Capcom handling the eyes at the *lens*, not at the render.

## 7. `via.render.Mirror` carries only two authored fields — confirming our latch

Its complete serialized (RSZ) field set in RE8 is **an enable byte and a
`via.render.RenderTargetTextureResourceHolder`** — i.e. "am I on" and "which `.rtex` do I render
into" `[reported 2026-09-07]`. **No plane, no normal, no offset, no render flags.**

Two consequences: our `.rtex` latch is working on the only authored surface the component has; and
any mirror *plane* must come from the GameObject transform, not from the component — which is
consistent with §9's baked-pane finding and with the `via.vec4 clip_plane` that RE Engine's
`SceneInfo` carries. Whether it is a true planar reflection or an arbitrary secondary camera remains
**`[hypothesis]`** — no public source states it either way.

`EyeDistortionRange` returns **zero GitHub-wide hits** — but that search cannot see files over
~384 KB, which excludes every RSZ template and every il2cpp dump, so this is **not** evidence of
absence. The route to the real runtime method list is first-party: REFramework dev mode → Object
Explorer → **Dump SDK** writes an `il2cpp_dump.json` into the game folder; search
`via.render.Mirror` in it. praydog never reversed the struct himself — REFramework's own regenny
header for it is an empty `Size: 0x0` stub.

**Nobody has publicly used `via.render.Mirror` in a mod.** An exact-string search across GitHub
returns 17 hits, **all** of them type metadata (praydog's `.genny` files and forks; kagenocookie's
`rsz_patch.json` for re8/re3/re2/re2rt/re3rt/dmc5). Zero mod code, zero Lua — against a control of
810 indexed Lua files containing `sdk.find_type_definition`, so the Lua corpus **is** indexed and the
absence is genuine. We are still the only ones doing this.

## 8. The `.rtex` descriptor is publicly documented — and it names two fields we left unnamed

kagenocookie's RE-Engine-Lib (`RTexFile.cs`) documents the format `[reported 2026-09-07]`. Compared
against our own `rtex_author.py` decode `[verified-numerically 2026-09-06, n=6 files]`:

**Agrees:** magic `RTEX`, version at `0x04`, **format at `0x0C` is a raw `DxgiFormat` enum** (so our
`29` = `R8G8B8A8_UNORM_SRGB` is confirmed by an independent parser, not an engine-private value),
width `0x10`, height `0x14`.

⭐ **Adds:** for **version ≥ 5**, the two trailing floats at `0x34` and `0x38` — which our decode
records as unnamed `f32 1.0` values — are **`widthRate` and `heightRate`**, and the library warns if
either is ≤ 0. These read as resolution **scale rates**. If an allocated target ever turns out not to
be the literal width/height in the file, **these two floats are where that discrepancy lives.**

⚠️ **Disagrees, and neither side is confirmed:** we read `0x18` depth/array `=1`, `0x1C` `=0`,
`0x20` `=0`, `0x24` mip count `=1`. The library reads `0x18` depth, `0x1C` **mipCount**, `0x20`
**arraySize**, `0x24` ukn1. Both fit the observed bytes; ours implies mip 1 / array 1, theirs implies
mip 0 / array 0. **Our naming of `0x18`–`0x24` is a plausible guess that happens to fit, not a
measurement** — worth downgrading in the tool's docstring until something distinguishes them.

⚠️ Also: the library records **RE2's `.rtex` version as 4** while RE8's is 5 — but the sibling
project's Record-system asset is `pl1000_body.rtex.**5**`. Either RE2RT differs from RE2, or the
version table needs a caveat. Flagged to that project.

The **"stored height = name's height + 8"** quirk (1920×1080 → 1088) is **not documented publicly**;
`ukn0`/`ukn1`/`ukn2`/`ukn3` are still unknown to the community library. Alignment padding to a
multiple of 8 is consistent but unsourced `[hypothesis]`.

For a worked precedent of manipulating these at runtime from a native REFramework plugin — swapping
`via.render.RenderTargetTextureResource` instances inside a `RenderTargetTextureResourceHolder` (the
resource pointer sits at holder + `0x10`) to redirect a capture to a different-resolution `.rtex` —
see hcdd0304's MHWilds photo mod.

## The concrete next steps this unlocks — all `[PD]`, none needing the headset

In order of cost:

1. **Read the REFramework revision off its startup log** and determine the branch and the
   `RenderingTechnique` setting in force. One line, no launch. This decides whether cause (2) is even
   active, and it closes the 2026-09-04 gap this lane has been flagging.
2. **If we are on `pd-upscaler`: try `MULTIPASS`.** It already exempts mirror-bearing layers from the
   projection override. A settings change, not a code change.
3. **Otherwise, carve the exemption ourselves**, the way praydog did for `ScopeCamera`: identify our
   mirror's camera and skip the eye-projection override for it.
4. **Read the matrices the engine actually used, rather than deriving them.** Take the Scene layer
   where `get_Mirror() != nullptr` and read its `SceneInfo` — `view_projection_matrix`, `view_matrix`,
   `projection_matrix`, their inverses, and `screen_size`. `screen_size` answers the aspect question
   numerically; `projection_matrix` says immediately whether it is the eye projection (asymmetric —
   `[2][0]`/`[2][1]` non-zero) or the mirror's own. **This converts §9g from a guess into a one-frame
   measurement** and supersedes the four-candidate sweep as the way to answer it.
5. **Separate the `UpdateMovie` suspect** by logging the target or a frame counter on both eye passes.
6. **Then look hard at `app.VrWeaponSniperScopeLensUpdater`** — locate the component and its three
   `GameObjectRef`s at runtime. If Capcom's approach is per-eye lens placement against a fixed image,
   our whole crop-follow line may be solving a problem the shipped design avoids.

⚠️ **What this does not do:** it does not prove any of these is *the* cause. It replaces "pick one of
four mappings in the headset" with a named, ordered set of static checks, each of which fails loudly.
Step 4 in particular is strictly better than the sweep: it measures what the sweep was going to infer.

## Sources and credit

Read online via each repository's own web viewer and GitHub's API; nothing cloned, nothing downloaded,
no code copied.

- **praydog — REFramework**: `shared/sdk/Renderer.hpp` / `.cpp` (`is_fully_rendered`,
  `find_fully_rendered_scene_layers`), `src/mods/VR.cpp` on `master` and `pd-upscaler`
  (`on_camera_get_projection_matrix`, `on_camera_get_view_matrix`, `on_end_rendering`),
  `src/mods/Hooks.cpp`, `src/mods/vr/CameraDuplicator.cpp`, `reversing/re8.genny`, the RE9 regenny
  `Scene.hpp`. Commit [`20a3ec5442`](https://github.com/praydog/REFramework/commit/20a3ec5442)
  ("VR (RE4): Fix scope not being zoomed in") and
  [`50f46296`](https://github.com/praydog/REFramework/commit/50f46296dc117c8fa12d99fcd3a4bf2b071b0ca7)
  ("Graphics (RE4): Add Scope Tweaks"); [issue #698](https://github.com/praydog/REFramework/issues/698).
- **kagenocookie** — RE-Engine-Lib (`RTexFile.cs`, the `.rtex` format), REE-Lib-Resources
  (`rsz_patch.json`, `il2cpp_cache.json`, `file_extensions.json`), RszTool, REasy, ReachForGodot.
  <https://github.com/kagenocookie>
- **alphaZomega (alphazolam)** — RE_RSZ, the RE8 RSZ template carrying every field name, including
  `app.VrWeaponSniperScopeLensUpdater`. <https://github.com/alphazolam/RE_RSZ>
- **cursey** — the REFramework book / Object Explorer documentation (the Dump SDK route).
- **hcdd0304** — MHWildsHighQualityPhoto, the worked `.rtex` / `RenderTargetTextureResourceHolder`
  swap. <https://github.com/hcdd0304/MHWildsHighQualityPhoto>
- **TommyCreo21, Unit-45, MelonBoyy, MrOmbre, Hypnosphi** — REFramework issue reporters whose threads
  (#698, #1243, #439, #509, #1615) established the scope/secondary-render behaviour.

## What came back empty, and how far to trust it

- **`EyeDistortionRange`: 0 hits GitHub-wide.** The same interface returned 17 for
  `"via.render.Mirror"`, 142 for `"render.Mirror"` and 810 Lua files for `sdk.find_type_definition`,
  so the index is live — **but GitHub code search does not index files over ~384 KB**, which excludes
  every RSZ template (RE8's is 25 MB) and every il2cpp dump. Not evidence of absence. This is exactly
  research rule 7, and it is why the RSZ and il2cpp files above were streamed and grepped directly
  rather than searched.
- **No public `il2cpp_dump.json` for RE8 exists**; dumps are generated locally by design.
- **`via.render.Mirror`'s runtime method list is not published anywhere.** praydog's own regenny stub
  is empty.
- **Whether RE8's house mirror or RE2R's bathroom mirror is a `via.render.Mirror` is unanswered**
  `[hypothesis]` — the type is in the RSZ tables of RE8, RE2, RE3, RE2RT, RE3RT, DMC5 *and* RE4, but
  presence in a type database is not proof of placement, and RE4 demonstrably uses a `ScopeCamera`
  instead. Settling it needs a `.scn`/`.pfb` inspection, which is outside a web-only pass.
- **Web search was consistently weak here**, returning SourceForge REFramework mirrors and Unity
  planar-reflection pages. Every substantive finding above came from source code.
