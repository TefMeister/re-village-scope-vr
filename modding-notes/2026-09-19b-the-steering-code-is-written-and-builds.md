# The steering code is written, and the patched REFramework builds with it

**2026-09-19, home PC (RTX). Static + a build. The game was NOT launched.**

## In one line

The change that stops the scope smearing is now **written, compiled and sitting in a DLL** — and
none of it has been tried in the game yet.

## What was actually done

1. **Filed the idea waiting in `DUMP.md`** first (Ashes: dismemberment, floating hands, knockback).
2. **Wrote the steering branch into the REFramework fork**, at exactly the site the owed item named:
   `VR::on_camera_get_projection_matrix`, inside the mirror window, in
   `D:\RE2 REFramework builds\tools\REFramework-src\src\mods\VR.cpp` (+ `VR.hpp`).
3. **Built it.** MSBuild against `build/RE8.vcxproj`, Release x64: **0 warnings, 0 errors**,
   `build/bin/RE8/dinput8.dll`, 22.7 MB, 20 s `[compile-verified 2026-09-19]`.
4. **Staged the build** as
   `D:\RE2 REFramework builds\dinput8_pd-upscaler_76298bd_mirror-steering_2026-09-19_NOT-YET-TESTED.dll`,
   alongside the 2026-09-12 exemption builds, under the same naming.
5. **Committed the patch** as `dev-archive/reframework-patch/mirror-steering.patch` — so unlike the
   v2 patch's first three months, this one exists in a repo from the day it was written.

## What the code does

Dossier §9aq, fix (1b). Inside a mirror window it takes the projection the pass would otherwise get
and **writes only the off-centre terms**:

```
m20 = -m00 * tan(yaw)      m21 = -m11 * tan(pitch)      m00, m11 untouched
```

`m00`/`m11` are how *wide* the drawn frame is; `m20`/`m21` are where its *centre* points. So the
same cone of angle is drawn, aimed at the bore instead of at the gaze. Pixels per degree are
unchanged — **100 % of today's sharpness**, against 83 % at 44° and 67 % at 50° for widening — and
the crop now sits at the centre of the frame by construction, so it cannot walk off the edge at any
angle. The failure mode is removed rather than pushed further out.

## Five deliberate decisions, each of which could have gone the other way

- **Off by default** (`VR_SteerMirrorProjection` = false). Nothing about today's behaviour changes
  until the tick goes on.
- **Placed ahead of the `is_hmd_active()` early-out**, so the angle can be swept **flat, with no
  headset on**. That is the cheap test of whether this getter is the lever at all, and it was the
  next step the owed item asked for.
- **Placed ahead of the exemption check too.** `VR_ExemptMirrorCameras` defaults to **on** and
  returns without touching the matrix — it would have swallowed the steer silently, and the session
  would have read "steering does nothing" when steering had never run.
- ⚠️ **An `Invert` tick, because the sign is a guess.** §9aq states the relation as
  `NDC = m00·tan(t) + m20`, which gives the minus signs above. That `+` was read off a live Lua dump,
  **not derived from RE Engine's clip convention**, and the opposite convention is just as common.
  If it is the other way round the frame steers the **wrong way** and the crop runs off the edge
  twice as fast. One tick cures it, and the flat sweep settles it in seconds. `[hypothesis]` until
  then — do not let it read as settled.
- **A "steer the native projection instead" tick**, which tells apart *"the steer never reaches the
  frame"* from *"it reaches it but the eye projection was the wrong base"*. Two very different
  problems that would otherwise look identical.

## The wiring question is answered, cheaply

§9aq left open how the plugin would hand the real bore angle to the REFramework hook. The DLL now
**exports two C functions**, confirmed present with `dumpbin /exports`
`[compile-verified 2026-09-19]`:

| Export | What it does |
| --- | --- |
| `REF_SetMirrorSteerAngles(float yaw_deg, float pitch_deg)` | the angle to steer to |
| `REF_MirrorSteerIsEnabled()` | 1 while steering is on, so the plugin can pick crop mode 2 itself |

`GetProcAddress(GetModuleHandleW(L"dinput8.dll"), …)`. Same process, no REFramework API change on
either side. ⚠️ **Nothing calls them yet** — the plugin side is unwritten.

## What is still NOT known, and why it needs a launch

- **Whether the drawn frame moves at all** when the angle is swept. If it does not, this getter is
  not the lever and everything above is moot. Flat, five minutes, no headset.
- ⚠️ **Culling — the real risk, and the reason this cannot be finished statically.** At 60° the
  shift is `m20 = −1.71`, which puts the whole frustum to one side of where the engine thinks it is.
  Objects popping in and out at the frame edges while the angle is swept is the predicted failure.
  Nothing here tests it. `[hypothesis]`
- **The sign.** See above.
- **The one-eye smear question** (separate owed item) — free, needs only the headset and a minute,
  and a `yes` would corroborate the whole §9aq derivation from the wearer's side.

## Where things are

| | |
| --- | --- |
| Source | `D:\RE2 REFramework builds\tools\REFramework-src\src\mods\VR.cpp`, `VR.hpp` (home PC only) |
| Patch, committed | `dev-archive/reframework-patch/mirror-steering.patch` |
| Built DLL | `D:\RE2 REFramework builds\dinput8_pd-upscaler_76298bd_mirror-steering_2026-09-19_NOT-YET-TESTED.dll` |
| Deploy to | `C:\Steam\steamapps\common\Resident Evil Village BIOHAZARD VILLAGE\dinput8.dll` |
| Menu | REFramework → VR → *Steer Mirror Projection (scope, fix 1b)* |

Credit: **praydog** (REFramework), **gmankab** (the `pd-upscaler` fork this is built on).
