# 2026-09-12 — Capcom's VR scope is a dead end on PC, and the swing is now a number

Home PC, `/lm re-village-scope-vr`, 11:20 onward. **First session driven with the headset awake on
a stand** (Tefa taped the proximity sensor, Virtual Desktop streaming, nobody wearing it). Three VR
launches, all driven end to end by `re8drive.py`; REFramework opened an OpenXR session on the Quest 3
each time (`OpenXR system Name: Meta Quest 3`) `[verified-live 2026-09-12, n=3]`. A background reader
was set to prepare the REFramework mirror-camera exemption (clone, patch, try a build); its result
is recorded at the end of this note.

## 1. The ⭐⭐ "read Capcom's own VR scope" row — ANSWERED, and the answer is NO

`dev-archive/lua/re8_scope_vrlens_probe.lua` read the type from the live type database:

- `app.VrWeaponSniperScopeLensUpdater : via.Behavior` — fields `DistortionBegin`, `ExpansionRate`,
  `ReticlePosition`, `LensLeftPosition`, `LensRightPosition` (as researched), **plus** `_mesh`
  (`via.render.Mesh`), `_materialIndex` and six material-variable indices: `_lensCenterPosIndex`,
  `_distortionBeginIndex`, `_reticlePosIndex`, `_lensLeftPosIndex`, `_lensRightPosIndex`,
  `_expantionRateIndex`. Methods: `start`, `lateUpdate`, ctor. `[verified-live 2026-09-12, n=1]`
- So it is a **material driver**: every frame it writes per-eye lens positions, a distortion onset
  and an expansion rate into named variables of the lens mesh's material. The optics live in a
  shader, not in this class.
- **Live instances in the loaded scene: 0** (village, rifle equipped) `[verified-live 2026-09-12, n=2 launches]`.
- **The shader it needs is not in the PC build.** The PC rifle (`it02_070_sniperrifle_01.mdf2.19`)
  has two lens materials on `MasterMaterial/Master/Weapon_SniperScopeLens2.mmtr`, whose full
  variable set is `ConvexNormal_CenterPos`, `EyeDistortionRange` (a float4, shipped 0.1/0.3) and the
  `Reticle_*` family — **no lens-centre, no left/right lens, no distortion-begin, no expansion-rate
  variable**. The release file list has exactly one master material with "scope" in its name.
  `[verified-numerically 2026-09-12]` (pulled from the pak with `ree_pak_extract.py`, read with
  `mdf_dump.py --params` and a string scan of the `.mmtr`).

**Verdict: Capcom's VR scope cannot be switched on here.** The component survives in the code, but
the material it drives was cut with the PSVR build. Re-creating it means writing the lens shader
ourselves, which is a bigger job than the mirror route we already have. Row retired.

(Side note for later: the flat lens shader does carry a per-eye term, `EyeDistortionRange` with
`eye_dir`, i.e. the look-through "eye box" of the flat scope. Not a VR mechanism.)

## 2. The 9j claim, measured: every camera hands out the HMD eye projection

The same probe lists every `via.Camera` in the scene once a second with the four projection terms
that only an HMD produces (off-centre `m20`, `m21`; unequal `m00`, `m11`). With the rig up
(`.` → `fn p10` → `fn drive_on` → `*`):

```
'MainCamera'          fov=51.32  m00=0.9848 m11=1.1696 m20=+0.1736 m21=-0.2111
'MainCamera (Clone)'  fov=51.32  m00=0.9848 m11=1.1696 m20=+0.1736 m21=-0.2111
```

Identical, off-centre, every second `[verified-live 2026-09-12, n=1 launch, ~40 samples]`. A camera
that is not an eye should read `m20 = m21 = 0`. This is what the override does to any camera that
asks, exactly as §9j inferred from the source — now a number instead of an inference. Two things it
does **not** show, said plainly: which of the two is the mirror's camera (`findComponents` on
`via.render.Mirror` returned nothing, so the mirror is not a scene component the probe can see),
and the head-motion swing itself (the headset was on a stand; nothing moved). With the exemption
built, this same probe is the pass/fail: the mirror camera's `m20/m21` must go to 0 while
`MainCamera` keeps the eye asymmetry.

Also learned: REFramework hands `get_ProjectionMatrix` back as a sol-bound glm `mat4`; rows index
with `[r]`, components by letter (`row.x`), not `[r][c]`. Cost two relaunches.

## 3. Multipass: startup-only, third log in a row

8 `Multipass textures are not setup correctly` warnings per launch, all inside the first ~25 s
(boot and title), none after gameplay begins `[verified-live 2026-09-12, n=2 launches]` — same
shape as 2026-09-06. Whether the setup later *succeeds* or silently falls back for good is still not
decided by a log alone; the exemption makes the question moot for the scope.

## 4. `rtex_3840` allocates and latches; frame cost still unmeasured

`fn destroy_rig` → `fn rtex_3840` → `.` → `fn p10` → `fn drive_on` → `*`: `mirror RT: using
movie/rtex/movie_3840_2160.rtex (3840x2168)`, `MIRROR SOURCE REPLACED … 3840x2168 fmt=29`,
`UPGRADED to raw-HDR … fmt=26`, `rig rebuild #2 … not stranded` `[verified-live 2026-09-12, n=1]`.
The frame-time half of that row is not answered: nothing logs a frame time. That needs a readout
(one log line from the plugin, or REFramework's stats) before anyone can say what 2560 or 3840 costs.

## 4b. Frame cost, finally a number

The plugin now logs one line a second (`[re-scope-vr] frame: N presents … avg ms … max ms`,
staging `86ae02b`). VR, village save, standing still, Virtual Desktop capped at 72 fps
`[verified-live 2026-09-12, n=1 launch, ~8 samples per row]`:

| scope target | avg frame | fps |
| --- | --- | --- |
| no rig | 13.9 ms | 72 (cap) |
| 1280 wide | 15.0 ms | 66 |
| 1920 wide | 15.5 ms | 64 |
| 2560 wide | 16.1 ms | 62 |
| 3840 wide | 18.0 ms | 56 |

So the second scene render costs about 1 ms at 1280 and 4 ms at 3840, and only 3840 drops the
headset below its 72 → ~60 comfort band. 2560 is affordable.

## 5. What the reader returned — and it WORKS

The reader cloned the exact fork the home PC runs (`gmankab/reframework-pd-upscaler-build`
`76298bd`, v1.5.9.1 + 671 commits), read the hooks, and found the thing the plan had missed: **the
mirror layer's camera IS the main camera, same address** (our own 2026-08-30 note said so), so no
name or address test inside the getter hooks can tell the mirror pass from the main pass. Its patch
(`D:\RE2 REFramework builds\tools\REFramework-src\mirror-exemption.patch`) therefore exempts by
**pass window**: a thread-local flag set while a mirror-bearing `via.render.layer.Scene` is inside
its `update`/`draw`, during which both getter hooks return without overriding; plus address and
name-prefix fallbacks, a toggle `VR_ExemptMirrorCameras` (default on), a UI checkbox, and counters
that log whether the getters are even called inside that window — the one hypothesis the fix rested
on. Build: target `RE8`, Release, 0 errors, 2 min 55 s, 22,745,600 B
`[verified-numerically 2026-09-12]`. Details: `engine-research/inbox/2026-09-12-reader-reframework-mirror-exemption-patch.md`
(drained into dossier §9k).

**Deployed 11:46** (installed `dinput8.dll` backed up beside it as
`dinput8.dll.pre-mirror-exemption-backup-2026-09-12`; note its MD5 `41af4484…` is NOT the labelled
`DLSS-capable` copy in `D:\RE2 REFramework builds\` (`e0c306df…`), so that backup is the only copy of
what was actually running) and **run in VR with the rig up, 11:49:**

```
[VR] Mirror-bearing scene layer seen (update): … camera_is_primary=true camera_go="MainCamera" exempt_enabled=true
[VR] Mirror layer windows=1200 get_ProjectionMatrix calls inside=600 get_ViewMatrix calls inside=600
     exempted proj=48101 view=48101 (by window=1200 camera=95002 name=0) hmd_active=true
```

**The getters ARE called inside the mirror window and ARE exempted** `[verified-live 2026-09-12, n=1]`.
And the probe's pass criterion from §2 is met on the same run:

```
'MainCamera (Clone)'  m00=1.7527 m11=2.0815 m20=0.0000 m21=0.0000    (its own symmetric 51.3° projection)
'MainCamera'          m00=0.9848 m11=1.1696 m20=+0.1736 m21=-0.2111  (the HMD eye, as before)
```

`[verified-live 2026-09-12, n=1]`. Frame cost with the 1920 target under the patched build: 15.5 ms.

**What is NOT established:** whether the picture in the scope has stopped swinging with the head.
Nobody wore the headset. The game was left running in VR with the rig up for exactly that look.
