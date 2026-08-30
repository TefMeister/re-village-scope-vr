# 2026-08-26 — Two findings that close old questions: the mesh list evaporates, and the lens is painted

Home PC, morning session. One live game process (08:35–onwards), buttons S6–S9 and
T1–T2, all read-only except T2 which is reversible and runtime-only. No file on
disk was modified by any test; no save was touched.

Two independent findings landed. The first invalidates a class of past results
across the whole project. The second explains, in one dump, why the scope work
had been stuck since 2026-08-22.

---

## 1. `findComponents` returns a list that decays while you iterate it

### How it surfaced

S6 (find lens meshes by material) and S7 (every mesh within a radius of the
camera) were run nine seconds apart on the same scene. They disagreed: S7 put
`ri3042_Inventory` 0.35 m from the camera, drawing, carrying both lens
materials. S6 did not list it at all. Both reported scanning the same 4114
meshes.

The first explanation offered was "the rifle was not equipped yet at the earlier
press". **The user refuted that directly — the weapon was in hand throughout.**
Worth recording: that guess should not have been offered as the likely reading
when a one-button diagnostic could settle it.

### What settled it

S8 ran *both* filters in a single pass over *one* snapshot, recording what every
call actually returned:

```
get_Count at start = 4114, at end = 0   (*** MUTATED MID-PASS ***)
get_Item nil = 1105
get_MaterialNum nil = 0    getMaterialName nil = 0    non-string name = 0
material filter matched 5;  distance filter (<=2.50m) matched 0
every ri3042* in this snapshot: NONE
```

The three suspected causes were all wrong. `get_MaterialNum` never failed;
`getMaterialName` never failed; no call returned a managed object in place of a
string. **The calls were fine — the items were gone.** 4114 − 1105 = 3009 items
read before the list went out from under us. The player, the hands and the rifle
all live past that point, and `safe()` turned each vanished item into a silent
skip with no error raised anywhere.

### The fix, and proof it works

Copy the list into a Lua table *first*, then work from the copy. S9 measured it:

```
method = tight copy   asked for 4321   got 4321   nils = 0
```

Full truth for the first time in this project:

| | before (live list) | after (snapshot) |
|---|---|---|
| lens-bearing meshes | 5 | **11** |
| `ri3042*` found | 0 (S6/S8), 1 (S7) | **exactly 1** |
| `SniperRifleCartridge` meshes | never seen | **5** (idx 4246–4250) |

`ri3042_Inventory` sits at **index 4232 of 4321** — the last 2% of the list,
deep inside the stretch that evaporates. That is the whole explanation for why
scan after scan "proved" it was not there.

### What this costs elsewhere — read this before trusting an old census

Every scene-wide scan in this project walked that same list. Any conclusion of
the form *"we searched the whole scene and found only X"* is void until re-run
on a snapshot. Specifically:

- **`find_rifle()`** was hunting index 4232 on a live list and rarely got there,
  so it was silently falling through to the `PropsManager → Player →
  PlayerUpdater → playerGun` chain without ever saying so. Anywhere the logs
  looked like that chain was the normal path, this bug is why.
- **S4's "exactly one `ri3042`" (2026-08-25)** was never a finding. It happened
  to be correct, but it was luck.

Rewired onto one shared `snapshot_components()` helper: `find_rifle()` and
`nearest_lens_mesh()`. The helper logs an error when it loses an item instead of
swallowing it, and `nearest_lens_mesh()` now **refuses to name a "nearest" from
a lossy scan** rather than confidently pointing at the wrong object. The
remaining M3–M13 scanners still walk the live list and are flagged unreliable by
construction; they were left alone deliberately, since rewriting six functions
we no longer use would risk breaking something for no gain.

**Generalised lesson, alongside the two already in the ledger:** *a search that
finds nothing must prove it actually looked.*

---

## 2. The scope lens is a painted illusion — there is no scene-image slot

### T2: the first proven control over what the player sees

`setMaterialsEnable(idx, false)` on `it02_070_Sniperrifle_01_Lens_Mat` and
`..._Lens2_Mat` removed the glass outright. Both read back `false`. The player
was left **looking down an empty tube and out through the far end** —
screenshotted. Reversible, and runtime-only.

This is the first positively-identified, reversible control this project has had
over what is actually in front of the player's eye. Turn it off, it goes away.
Not inferred, not attributed.

### T1: the dump that explains everything

`ri3042_Inventory` at 0.35 m — `draw=true`, `Viewable=false`, `ReadyToDraw=true`,
`MaterialReady=true`, `MaterialsUpdatable=true`, `updatableMaterial()=false`,
`MaterialLinked=true`, `getMaterialsEnableCount()=256`.

The lens material has exactly **two** texture slots, and neither is a scene image:

```
tex[0] FakeSpecularMap        -- a painted highlight
tex[1] Reticle_BaseAlphaMap   -- the crosshair
```

Its 25 shader variables name the trick outright:

| Variable | What it is |
|---|---|
| `FrontHole_PosUV_Rad_Blur`, `FrontHole_Color_Inner`, `FrontHole_Color_Outer`, `FrontHole_Height` | a **painted dark circle faking a tube** |
| `ConvexNormal_CenterPos`, `ConvexNormal_Intenisty` *(Capcom's own typo)* | fake lens curvature |
| `EyeDistortionRange`, `TransparentColor`, `AlphaValue`, `Metallic`, `Roughness`, `Translucency` | blending |
| `Reticle_*` ×11 (`UV_Scale_Offset`, `VariableScale[_Min/_Max]`, `Depth_Min/Max`, `DepthCurve[_StartRange/_EndRange]`, `Emissive`) | reticle placement, depth response, brightness |
| `FakeSpecular_AddColor`, `FakeSpecular_Height`, `FakeSpecular_RangeLimit` | the painted highlight's controls |

**RE Village's scope glass does not render the world and never did.** Flat
gameplay gets its magnification from the *camera's FOV zoom*. The glass is a
transparent quad wearing a painted highlight, a painted hole and a reticle.

### What this retro-explains

- **Slot 0 writes changed nothing (2026-08-25)** — it is a subtle additive
  highlight gated behind `FakeSpecular_AddColor` / `RangeLimit`. Rifle-metal
  albedo written there would not show.
- **Slot 1 writes moved the reticle (F9, 2026-08-24)** — because it *is* the
  reticle. The observation was always real; only the conclusion drawn from it
  was wrong.
- **The "environment reflection" photographed all evening on 2026-08-25** was
  `FrontHole` + `FakeSpecular`. That is exactly why it ignored our camera's FOV,
  aspect, type and near/far — it was paint, not a broken render.

### Where this leaves the project

The road this project has been walking — *put our render target on the existing
glass* — is closed. Not blocked: closed. There is no slot for the image to
arrive through.

What survives is real, though: **slot 1 is still the one surface proven to put
our pixels in front of the player's eye.** It is a reticle slot, not a scope
image slot, but it is a display, and we now hold its controls. Whether it can be
stretched to fill the lens is the open question, and it is a different and much
more tractable question than the one we were stuck on.

---

## Instrumentation added this session (all in staging `main`)

| Button | What it does | Writes? |
|---|---|---|
| **S7** `dump_near_meshes` | every mesh within a radius of the camera, nearest first, all material names — assumes nothing about naming | no |
| **S8** `diff_filters` | both filters, one pass, one snapshot; prints the disagreement and every call's return | no |
| **S9** `rescan_snapshot` | snapshot first, then filter; reports asked/got/nils/first_nil/last_nil so the fix proves itself | no |
| **T1** `dump_lens_material_detail` | every texture slot, shader variable name and type, enable flag | no |
| **T2** `toggle_lens_materials` | switch the lens material(s) off/on | yes, reversible |
| **T3** `dump_lens_var_values` | current *value* of every shader variable (T1 gave names and types only) | no |
| **T4** live sliders | every float knob on the lens materials, with save/restore | yes, reversible |

`snapshot_components(typename)` is the shared helper; use it for any new
scene-wide scan in this or any other RE Engine project.

## Next session starts here

**Reset Scripts → T3**, then T4's sliders. The question T3/T4 answer: can slot 1
be made to fill the glass? Turn `FrontHole_*` down so the painted hole stops
darkening it, push `Reticle_UV_Scale_Offset` and `Reticle_Emissive`, and watch.

If it can fill the lens, we have a display surface and the problem becomes *what
do we draw into it* — a completely different problem from the one that stalled
this project for four days.

## Clean state

All material writes are runtime-only: `setMaterialTexture`, `setMaterialsEnable`
and `setMaterialFloat` touch loaded material instances in memory, so everything
this session did — T2's disabled lens included — is gone the moment the process
exits. Nothing on disk was modified, no save was touched, and nothing auto-binds
or auto-attaches on next launch. The native plugin remains parked as
`reframework/plugins/re_scope_vr.dll.off-for-m8`.
