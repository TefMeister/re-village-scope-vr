# What RE4 Remake's working VR scope teaches us — read off the shipped binaries (2026-09-20, static)

Tefa installed **RE4 Remake + Talemann's RE4VR mod** (`-Talemann`, splash dated `14.08.2026`) on the
home PC and asked what transfers to the Village scope and to Visceral. Nothing was launched. Every
claim below comes from string/symbol analysis of files already on this disk:

| File | What it is |
| --- | --- |
| `RESIDENT EVIL 4  BIOHAZARD RE4/dinput8.dll` (55 MB) | Talemann's mod — a **REFramework fork with the whole mod compiled in**. `reframework/autorun/` and `reframework/plugins/` are **empty**: there is no Lua to read. |
| `RESIDENT EVIL 4  BIOHAZARD RE4/reframework/data/re4_vr/*.json` (63 files) | the mod's saved settings, one small file per feature |
| `RESIDENT EVIL 4  BIOHAZARD RE4/re4.exe` (233 MB) | RE4R's own type/field/method names are **plain ASCII in the exe** |
| `Resident Evil Village BIOHAZARD VILLAGE/re8.exe` (215 MB) | same, for Village |
| `RESIDENT EVIL 2  BIOHAZARD RE2/il2cpp_dump.json` (494 MB) | RE2's full reflection dump, already on disk |

⚠️ **Method note, and it is the most reusable thing here: RE Engine ships its managed type names,
field names and method names as raw ASCII inside the game executable.** So a question of the form
"does this game have a class/field called X" is answerable **statically, with no game running, no
REFramework, no dump step** — `grep` the `.exe`. Verified on re4.exe, where `ScopeController`,
`updatableMaterial`, `_IsViaScope` and `HoldOpticalScope` all appear `[measured 2026-09-20]`. This
retires the assumption that type questions need a live dump.

---

## 1. Why RE4R's scope works in VR and ours has to be built by hand — the architectures differ

**RE4R renders its scope picture natively, into the lens, from its own camera.** From `re4.exe`
`[measured 2026-09-20]`:

- the weapon carries `get_ScopeController` / `set_ScopeController` / `<ScopeController>k__BackingField`
- next to that backing field sits **`_ScopeCameraObject`**, and the camera GameObject is named
  **`ScopeCamera`** (6 hits in re4.exe; `ScopeCam` also 6, `ScopeCamA` **0** — see the correction below)
- the controller exposes `_IsActive`, `_ScopeParam`, `_FOVMin`, `_FOVMax`, a child `lens`, and
  `updatableMaterial` (the engine's runtime-writable material handle)
- the player/weapon state carries `get_IsViaScope` / `set_IsViaScope` / `_IsViaScope`, and the motion
  set has `HoldIronSight`, `HoldExtraScope`, `HoldOpticalScope`, `HoldSpecialOpticalScope`, `ViaScope`
- there is a `SpecialScopeColor`, a `ZOOM_STATE`, and a `getScopeTwirl`

So the flat game already draws a real, correct, per-frame picture onto the glass. Talemann's mod does
**not** create that picture — it **re-poses the camera that already exists** and leaves the render path
alone. That is the whole difference in difficulty.

**Village has no scope camera.** `re8.exe`'s complete list of `scope`-bearing strings (66, all of them)
contains **no `ScopeController`, no `_ScopeCameraObject`, no `ScopeCamera`** `[measured 2026-09-20]`.
Village's flat scope is a FOV zoom on the main camera plus a GUI overlay (`isShowScopeGUI`,
`DispScopeRequested`, `DrawOffByScope`, `ChangeSniperScope`, `isChangeSniperScopeSequence`).

⭐ **This independently confirms, from the shipped executable, what §9g's research inferred from a
type DB: our mirror-and-lens machinery is not a workaround we chose, it is the only route Village
leaves open.** The finding was `[inferred-static 2026-09-07]`; the exe now says the same thing
directly `[measured 2026-09-20]`. **No part of RE4R's scope route is portable to Village.** Anyone
who proposes "just use the game's scope camera like RE4 does" can be answered in one grep.

### ⚠️ Correction to a symbol name that would have misled us

An earlier read of Talemann's DLL found the string **`ScopeCamA`** at `0x90686b` and I took it for the
camera's GameObject name. It is not: that offset sits in a code region, and `re4.exe` contains
`ScopeCamera` and **zero** occurrences of `ScopeCamA` `[measured 2026-09-20]`. `ScopeCamA` is the
compiler splitting an inlined `"ScopeCamera"` comparison across registers. **The name is
`ScopeCamera`** — which matters, because that is exactly the name praydog's REFramework exemption
matches (commit `20a3ec5442`, *"VR (RE4): Fix scope not being zoomed in"*, already in
`external-research`). So the working mod and upstream REFramework agree on the name, and our
external-research note on that commit is correct as written.

---

## 2. What DOES transfer to Village: per-weapon tuning, exactly as we built it

`reframework/data/re4_vr/re4_vr_scoped_index.json` is Talemann's shipped scope tuning, and the shape
is worth seeing because it is a working mod's answer to the same problem our zeroing rows solve:

- keyed by **weapon ID** (`4202`, `4400`, `4401`, `4402`, `6105`, `6114`) — six scoped weapons
- per weapon: `pos_offset`, `rot_offset`, `scope_pos_offset`, `scope_rot_offset`, `scope_cam_pos`,
  `scope_cam_rot`, `scope_fov_min`, `scope_fov_max`, `scope_lerp_speed`
- two file-level bounds for the tuning UI: `slider_range_pos 1.0`, `slider_range_rot 130.0`
- the shipped tuned values are **not** identity: `scope_cam_pos.z = 3.5` on every weapon, and
  `scope_cam_rot.yaw = -13.2` on five of six — the crossbow (`4401`) needing its own
  `pitch 5.5 / yaw -22.4`
- `scope_lerp_speed = 8.0` — the pose is **eased toward**, not snapped

⭐ **The lesson is a negative one and it is reassuring: even with the engine handing you a correct
scope camera, a working mod still needs a per-weapon offset table, bounded sliders and a save file.**
Our zeroing work (14.4 up / 9.5 right) is not a symptom of our approach being wrong; it is the
irreducible part. And `scope_lerp_speed` is a knob we do not have.

**The one structural idea worth stealing:** RE4R's picture cannot shake when the head moves, because
the camera producing it is **parented to the gun**. Our picture is derived from a head-referenced
mirror, which is why rows "the picture shakes on the glass when the head moves" and "the crop runs off
the edge" exist at all. We cannot copy the fix, but it names the class of the fault precisely: *our
picture's source is attached to the wrong thing, and every crop/shake symptom follows from that.*

---

## 3. NEW, and aimed straight at two open Village rows: Village has native sway and spread levers

None of these names appear anywhere in this repo. All from `re8.exe` `[measured 2026-09-20]`:

**Aim wander ("twirl" is RE Engine's word for it):**
`HorizontalTwirlSpeed`, `VerticalTwirlSpeed` — with **setters** `set_HorizontalTwirlSpeed`,
`set_VerticalTwirlSpeed`, `set_horizontalTwirlSpeed`, `set_verticalTwirlSpeed`, plus
`updateTwirlSpeed` and `updateDampingTwirlSpeed`. RE4 links the same word to the scope
(`getScopeTwirl`), so these are very likely the scope/aim wander `[inferred-static 2026-09-20]`.

**Recoil hand shake:**
`enableRecoilHandShake` / `isEnableRecoilHandShake` / `get_enableRecoilHandShake`,
`executeRecoilHandShake` / `isExecuteRecoilHandShake`, `updateRecoilHandShake`,
`requestResetRecoilHandShake` / `isResetRecoilHandShake`, `RecoilHandShakeAdjustTimer`,
`RecoilHandShakeResetTimer`, `RecoilHandShakeWaitResetTimer`, `updateHandShake`,
and the animation set `HandShake_1` / `HandShake_2` / `HandShake_3`.

**Spread — beyond the `DiffusionRadius` we already found on the 17th:**
`set_isDiffusion` (a **setter**, i.e. spread can be switched off rather than measured),
`IsDiffusion`, `isDiffusion`, `get_isDiffusion`, `DiffusionNum`, `DiffusionAddNum`,
`DiffusionRadius`, `DiffusionRadiusRate`, `IsDiffusionPowerUp`, `setupDiffusion`.

⭐ **Why this matters:** two open rows — *"bullet spread to 0 and accurate without holding the aim
button"* and *"the picture shakes on the glass"* — are currently framed as things to measure and
compensate. These symbols say the engine may let us simply **command** them off. ⚠️ **Unverified:**
the symbols exist; whether the setters are reachable through REFramework reflection and whether
writing them survives the game's own per-frame update is **not known**. Treat as a cheap `[PD]`
reflection read followed by one flat write test, not as a fix.

---

## 4. Village ships more of Capcom's PSVR2 VR mode than we had recorded

The dossier records `app.VrWeaponSniperScopeLensUpdater` (hash `e6d05808`) and its per-eye lens
fields. The PC executable carries a **much wider** VR surface, and none of these other names appear in
this repo `[measured 2026-09-20]`:

`VrManager`, `VrCamera`, `VrEventManager`, `VrDeviceManager`, `VrDeviceType`, `VrDeviceName`,
`VrDeviceRequirement`, `VrSdkType`, `VrSystemStatus`, `VrModeStatus` (+ `VrModeStatusChange`,
`VrModeStatusCheckLevel`, `VrModeStatusCheckTiming`, `VrModeStatusWaitingFrame`), `VrEnable`,
`VrOn` / `VrOff`, `VrEye`, `VrPose`, `VrFieldOfView`, `VrHandRole`, `VrPositionReset`,
`VrPoseResetRequested`, `VrTracker` (+ `VrTrackerDeviceType`, `VrTrackerPose`, `VrTrackerEnable`,
`VrTrackerStarted`, `VrTrackerResultData`), `VrVideoMode`, `VrVideoModeEnabled`, `VrPlaytimeSec`,
`VrServiceDialog`, `VrGUICaptionPositionConfig`, **`VrGUIHandWorldMap`**, **`VrGUIHandMapIcon`**,
**`VrGUIHandMapMask`**.

⭐ `VrGUIHandWorldMap` / `VrGUIHandMapIcon` / `VrGUIHandMapMask` is Capcom's **map-in-the-hand** UI —
a shipped, engine-side answer to a problem every VR mod of this game has. Worth a look on its own
merits, separately from the scope.

⚠️ **Nothing here says any of it can be switched on.** The PSVR2 mode is very likely gated behind
`VrDeviceRequirement` / `VrSdkType` on a platform this build is not. The value of the list is that it
names the classes to read, and it is reachable with the same one-grep method as everything above.

---

## 5. RE4R's scope is cheap on purpose — a data point about how RE Engine draws scopes

Talemann's fork exposes, in its graphics menu, **`ScopeTweaks` → `ScopeInterlacedRendering` +
`ScopeImageQuality`** ("Enable Scope Tweaks", "Enable Interlaced Rendering", "Scope Image Quality"),
sitting beside REFramework's own Ultrawide/FOV, `ForceRenderResToWindow` and ray-tracing tweaks. So
**RE4R's native scope render is interlaced and quality-limited by default, and it is worth a toggle**
`[measured 2026-09-20]`. Village's REFramework (`dinput8.dll`, 22 MB, 2026-09-19) contains
`Ultrawide`, `RayTracingTweaks`, `ShaderPlayground` and `ForceRenderResToWindow` but **zero**
occurrences of any `Scope*` tweak — as expected, since Village has no scope render to tweak.

This pairs with the `/gr` finding on RE9 (`_LensImageDefaultScale` / `_LensImageZoomRate`): across
three generations, Capcom's scopes magnify by **scaling a cheap lens image**, never by rendering a
full-resolution second view. Our mirror renders at 2560×1448 and upgrades to raw-HDR — i.e. **our
scope is more expensive than any scope Capcom has shipped.** Not a problem today; worth knowing when
frame time becomes the argument.

Also present in the German-language mod menu: `Scope-Test (Weg A): Waffen-Mesh im Scope
skalieren/versetzen` — "Route A: scale/offset the weapon mesh inside the scope" — with
`re4_vr_scope_proto.json` (`scale`, `ox`, `oy`, `oz`, all at identity). Talemann kept a
scale-the-mesh experiment in the shipped build and it is switched off. Recorded so we do not read it
as a recommendation.

---

## What was checked and found to be nothing

- **No Lua.** Talemann ships no readable script; the mod is one compiled DLL. Nothing to study line
  by line even if we wanted to.
- **`ScopeCamA` is not a name** (see §1 correction).
- **`vr_scope_active` / `vr_scope_aim_pos` / `vr_scope_aim_dir`** in the mod DLL sit among
  laser-sight symbols (`SightEmitJoint`, `set_DepthTest`, `get_PlayerLineEmissiveMaterialParam`), so
  they are the mod's own internal keys, not engine fields `[inferred-static 2026-09-20]`.

Credit: **Talemann** (RE4VR mod, read statically, no code copied), **praydog** (REFramework),
**alphaZomega** (RE_RSZ, which is how we first knew the Village lens class existed).
