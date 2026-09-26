# 2026-09-26 — The "32 ms" was ours: the rifle camera runs at 150+ fps

*Fable, home PC, flat, Claude driving. Evidence: `dev-archive/recon/2026-09-26m-the-32-ms-was-ours/`.*

## The short version

The rifle camera was dropping the game from 180 fps to 26. It was not the engine, not DLSS, not the graphics card. It
was our own script, asking the game to list every mesh in the level **every frame** just to find the rifle again. Find it
once, keep it, and the rifle camera costs about 1.5 ms — **150–160 fps** with the picture following the rifle.

## How the search went (so the method can be reused)

The old notes had a fixed ~32 ms per frame whatever the clone drew, and called it "a wait, not work" with the upscaler as
the suspect. The static reading of the pd-upscaler `TemporalUpscaler.cpp` ruled the upscaler out cleanly: it filters scene
layers by `is_fully_rendered()`, which needs the camera's GameObject to be named `MainCamera*`, so a `ScopeCam2` layer is
ignored — and the log showed no DLSS feature re-creation during the slow runs.

That left measuring. Two tools:

1. **A frame-stage timer in Lua** (`re8_scope_frametime.lua`, word `ftime 1|0`): every `via.ModuleEntry` name gets a
   pre + post hook; it reports ms per frame per stage, split into *inside* the stage and *before* it (the gap since the
   previous stage ended, which is where scripts' pre-hooks run).
2. **The GPU wait in the plugin's frame line** (`fence wait avg/max`): a long wait = the GPU is the bottleneck; a short wait
   with a long frame = the CPU side.

One run: frame 26.9 ms, GPU wait 3.7 ms, and **20.9 ms sitting in the gap before `LockScene`** — where our clone's per-frame
hook runs. `clonepose off` → 7.2 ms instantly. Cause in the code: `body_joint()` called `rig.find_rifle()` every LockScene,
and `find_rifle` snapshots every `via.render.Mesh` and reads each one's GameObject name.

**Lesson worth keeping:** a cost that is *fixed* — the same for bare and full, 1920 and 2560 — is the signature of
something that does not depend on what is drawn. Before suspecting the engine, time our own per-frame hooks. The
`ftime` probe now makes that a one-word check.

## Also done tonight

- **Barrel out of the picture:** the near plane follows the muzzle (`vfx_muzzle` distance + 5 cm, clamped 0.30–1.20 m),
  read every frame from the kept joint. `clonenear <m>` still pins a value; `clonenear auto` hands it back.
- **1920 picture first** (2560 is the fallback).
- **Tests:** `cam_clone_test.lua` grew checks for the muzzle plane (follows, clamps, pin wins); `autostart_test.lua` 36/36.

## Still open

- **The speckle band** at the top of the picture is on the 1920 target too (and with post-processing copying off), so the
  earlier "clean at 1920" was one sighting against another. Not the barrel, not the target size, not post-processing.
- **Outdoors the picture is blown out** (uniform light blue): the brightness / exposure item.
- **VR** not tried yet.

## What is installed on the home PC now

Plugin `7f13b159` (frame line with the fence wait; nothing else changed), the fixed `re8_scope_cam_clone.lua`, the
`re8_scope_frametime.lua` probe, the harness with the `ftime` word. The autostart file is back on the mirror scope (`1`)
for normal play; `1 1920 clone` puts the rifle camera in.
