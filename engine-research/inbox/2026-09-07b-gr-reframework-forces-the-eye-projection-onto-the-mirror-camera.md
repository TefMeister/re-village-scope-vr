# ⭐⭐ §9g answered from praydog's source: the Mirror renders with its OWN projection — and REFramework overwrites it with the HMD's

**From:** `/gr` (estate sweep, 2026-09-07, second drop of the day) · **For:** the modding lane, for
`ENGINE-DOSSIER.md` §9f/§9g and the board's ⭐ `[VR]` row

Supersedes: `inbox/2026-09-07-gr-the-mirror-layer-answers-9g-without-a-headset.md` — that drop
proposed reading the layer's camera to decide *which* projection the Mirror uses. Its route is
**right and now corroborated by praydog's own code**, but its framing of the question is superseded:
the answer is not "the viewing camera's or its own" but **"its own, which REFramework then
overwrites"**. Read this drop with it, not instead of it — its `get_Size` / `get_ViewID` /
`get_HorizontalScreenScale` reads remain worth taking, and step 4 below is the stronger version of
its proposal.

**Full write-up:** [`external-research/topics/2026-09-07-reframework-forces-the-eye-projection-onto-every-camera-including-the-mirrors.md`](../../external-research/topics/2026-09-07-reframework-forces-the-eye-projection-onto-every-camera-including-the-mirrors.md)

## The dead end this closes

§9g: *"does `via.render.Mirror` render with the viewing camera's projection … or does it render its
own 16:9 projection at the same size … Flat cannot tell the projections apart (0.7 %); VR can
(1.9 %)."* Four candidates were built and two headset launches spent; both swing.

## The answer, in three parts

**1. Natively the Mirror renders with its OWN camera and projection.** `[inferred-static 2026-09-07]`
`via.render.layer.Scene` holds a `via.Camera*` immediately followed by a `via.render.Mirror*`
(`re8.genny`; RE9 offsets camera `0x88`, mirror `0x90`), and REFramework's own `is_fully_rendered()`
requires `get_mirror() == nullptr` — i.e. praydog's code treats a mirror-bearing layer as **not the
main view** by construction. praydog, issue #698: *"The way scopes work is they create a separate
scene, yes."*

**2. 🎯 But REFramework's VR mod forces the HMD eye projection onto EVERY camera.** In
`VR::on_camera_get_projection_matrix` the guard restricting the override to the primary camera is
**commented out**, while the equivalent guard in `on_camera_get_view_matrix` is **live**. So the
mirror render gets the current eye's **asymmetric, off-centre HMD projection** on top of the mirror
camera's **own, non-eye view matrix**, into a 1.76-aspect target. **A projection that changes with
head pose over a view matrix that does not is exactly "the picture inside is moving where I look and
tilt."** `[inferred-static 2026-09-07]`

**3. praydog hit this on RE4's scope and fixed it by exemption.** Commit `20a3ec5442`, 2023-04-06,
*"VR (RE4): Fix scope not being zoomed in"* — checks the camera's GameObject name for the prefix
`ScopeCamera` and returns without overriding, commented *"Allows the sniper scope to work."*
`[reported]` Same framework, same problem, a sniper scope. RE8 uses a Mirror where RE4 uses a
ScopeCamera, so the *match condition* differs; the remedy does not.

## ⭐ And a setting may already do it

`pd-upscaler`'s `RenderingTechnique_V2` has a **`MULTIPASS`** mode whose
`CameraDuplicator::get_relevant_scene_layers()` calls `find_fully_rendered_scene_layers()` — **which
erases every mirror-bearing layer** — and restricts the override to the two multipass cameras. **Under
MULTIPASS the mirror keeps its own projection; under the default sequential mode it does not.**
`[inferred-static]`

⚠️ Whether that applies depends on the build, and **this project still records no REFramework
revision at all** (the gap this lane filed 2026-09-04, still unread in this inbox). That gap now has a
price: whether the swing is even *expected* depends on branch and setting. The framework prints its
branch and version to its own log at startup — no launch needed.

## ⚠️ A second, independent suspect: the right-eye pass skips `UpdateMovie`

The right eye is produced by replaying the engine's `WaitRendering`→`EndRendering` chain a second
time in the same frame, with a specific erase list — which includes **`UpdateMovie`** (*"Causes
movies to play twice as fast if ran again"*). **Our target is a `movie/rtex` target.** If its refresh
runs under `UpdateMovie`, the right eye sees a **stale image**, presenting as a lag that tracks head
motion `[hypothesis]`. Cheap to separate: log the target or a frame counter on both passes.

**One engine fact to pin beside the crop maths**, praydog's own comment: *"the game **always** uses
the main camera when calling this function, even though it's rendering the other camera."* The camera
a pass calls a getter on **does not identify the camera that pass is rendering**. Any instrumentation
assuming otherwise misleads.

## ⭐⭐ RE8 ships Capcom's own VR sniper scope, and it works differently from all four candidates

`app.VrWeaponSniperScopeLensUpdater` (hash `e6d05808`) is in RE8's type DB with fields
`DistortionBegin` (float), `ExpansionRate` (float), `ReticlePosition`, **`LensLeftPosition`**,
**`LensRightPosition`** (all `via.GameObjectRef`) `[reported 2026-09-07]`.

**Per-eye lens *position anchors*, not a per-eye reprojection.** Capcom moves and scales the lens quad
per eye against a fixed rendered image, with a radial distortion/expansion term. That addresses
Tefa's *first* symptom — *"moving around the pipe of the scope"* — which none of our four candidates
ever did; they all addressed only the second. RE8 has no `_ScopeCameraObject`-style field, unlike RE4,
which is consistent with RE8 handling the eyes **at the lens** rather than at the render.

## Also: `via.render.Mirror` has exactly two authored fields

Its complete RSZ field set in RE8 is an **enable byte** and a
**`via.render.RenderTargetTextureResourceHolder`** — "am I on" and "which `.rtex`" `[reported]`. No
plane, normal, offset or render flags. Our `.rtex` latch is working on the only authored surface it
has, and any mirror plane must come from the GameObject transform (consistent with §9's baked pane).
Planar-reflection vs arbitrary secondary camera stays `[hypothesis]` — no public source says.

`EyeDistortionRange` returns 0 GitHub-wide hits, but **code search cannot see files over ~384 KB**
(every RSZ template and il2cpp dump), so that is **not** a negative. The real method list comes from
REFramework dev mode → Object Explorer → **Dump SDK** (`il2cpp_dump.json`), then search the type.
praydog never reversed the struct — his regenny header for it is an empty `Size: 0x0` stub.

**Nobody has publicly used `via.render.Mirror` in a mod**: 17 GitHub hits, all type metadata, zero
Lua — against a control of 810 indexed Lua files using `sdk.find_type_definition`, so the corpus is
indexed and the absence is real.

## 📄 The `.rtex` format is publicly documented — two of our unnamed fields have names

kagenocookie's RE-Engine-Lib `RTexFile.cs` `[reported 2026-09-07]`. **Agrees** with our decode on
magic, version, **format at `0x0C` being a raw DXGI enum** (so `29` = `R8G8B8A8_UNORM_SRGB` is
confirmed by an independent parser), width and height.

⭐ **Names our two trailing `f32 1.0` values at `0x34`/`0x38` as `widthRate` and `heightRate`** —
resolution **scale rates**, which the library validates as > 0. If an allocated target is ever not the
literal width/height in the file, that is where the discrepancy lives.

⚠️ **Disagrees on `0x18`–`0x24`, and neither side is confirmed.** We read depth/array `0x18`=1,
`0x1C`=0, `0x20`=0, mip `0x24`=1; the library reads depth `0x18`, **mipCount `0x1C`**, **arraySize
`0x20`**, ukn1 `0x24`. Both fit the bytes. **Our naming there is a plausible guess that fits, not a
measurement** — worth downgrading in `rtex_author.py`'s docstring. The **"height = name + 8"** quirk
is undocumented publicly and remains ours. ⚠️ The library also lists **RE2's rtex version as 4** while
ours is 5 — flagged to the sibling project, whose Record asset is `.rtex.5`.

## Suggested `[PD]` sequence, in cost order — none needs the headset

1. Read the REFramework revision, branch and `RenderingTechnique` off its startup log. One line.
2. On `pd-upscaler`: try **MULTIPASS** — a setting, not a code change.
3. Otherwise carve the exemption ourselves, as praydog did for `ScopeCamera`.
4. ⭐ **Read the matrices the engine actually used instead of deriving them:** take the Scene layer
   where `get_Mirror() != nullptr`, read its `SceneInfo` — `view_projection_matrix`, `view_matrix`,
   `projection_matrix`, inverses, and **`screen_size`**. `screen_size` answers the aspect
   numerically; `projection_matrix` says at once whether it is the eye projection (asymmetric:
   `[2][0]`/`[2][1]` non-zero) or the mirror's own. **This measures what the four-candidate sweep
   was going to infer**, and it is the stronger form of my earlier drop's proposal.
5. Separate the `UpdateMovie` suspect by logging both eye passes.
6. Then investigate `app.VrWeaponSniperScopeLensUpdater` — its three `GameObjectRef`s may make the
   whole crop-follow line unnecessary.

⚠️ **None of this is proven to be the cause.** It replaces a four-way headset guess with a named,
ordered set of static checks that fail loudly. Claim strengths are on each item.

## Credit

praydog (REFramework — the source, the two RE4 commits, issue #698); kagenocookie (RE-Engine-Lib,
REE-Lib-Resources); alphaZomega (RE_RSZ, the RE8 template carrying
`app.VrWeaponSniperScopeLensUpdater`); cursey (the Object Explorer / Dump SDK docs); hcdd0304
(MHWildsHighQualityPhoto, the worked `.rtex` holder swap); the REFramework issue reporters
TommyCreo21, Unit-45, MelonBoyy, MrOmbre, Hypnosphi. All added to `external-research/CREDITS.md`.
Read online only — nothing cloned, downloaded or copied.
