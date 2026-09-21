# The patched REFramework — source patch and build recipe

**Why this folder exists.** The scope mod needs a REFramework built from patched source, not the
stock release. Until 2026-09-16 that patch and the `dinput8.dll` built from it existed **only on the
home PC's `D:` drive and in no repo at all** — the exact pattern that lost the XIII mod's source in
August. The patch is committed here; **the binary deliberately is not** (22 MB, and it rebuilds from
this in one command).

Rescued from `D:\RE2 REFramework builds\tools\REFramework-src\` on 2026-09-16 (home PC `RTX`).
⚠️ `mirror-exemption.patch` and `mirror-exemption-v2.patch` on that drive are **byte-identical**
(checked), so only one copy is kept here, under the v2 name the board uses.

## What it applies to

| | |
| --- | --- |
| Fork | `gmankab/reframework-pd-upscaler-build` |
| Branch | `pd-upscaler` |
| Commit | **`76298bd`** (`Merge branch 'master' into pd-upscaler`) |
| Plugin API | 1.15.0 |

That is the same REFramework build Visceral RE2 uses — see `claude-memory/status/re-village-scope-vr.md`,
the 2026-09-04 inbox-drain entry.

## The three patches

- **`mirror-exemption-v2.patch`** — the real change, all in `src/mods/VR.cpp`.
  1. **The mirror-camera exemption.** RE Village's scope mirror layer renders with the *same camera
     object* as the main pass, so REFramework's usual test — which camera is this? — cannot tell the
     two apart, and the scope picture ends up carrying the headset's pose. This adds a *window*
     instead: a thread-local flag set while a scene layer carrying a `via.render.Mirror` is inside
     its `update()`/`draw()`, so the getters know they are in the mirror pass. praydog's own RE4
     `ScopeCamera` exemption keys on the camera's object name, which only works when the scope has a
     camera of its own; Village's does not.
  2. **"Plan C"** — inside that window, hand the mirror layer the view matrix of the game's *own*
     camera pose rather than the HMD-adjusted one. Exposed as a REFramework menu toggle
     (*Mirror Uses Original Camera Pose (plan C)*) with live counters, so it can be turned off in
     the headset without a rebuild.

- **`mirror-steering.patch`** — added 2026-09-19 (home PC). ⚠️ **`[disproved 2026-09-19]` THE SAME EVENING — do not build on this.** The SHOUT diagnostic shipped in it halved the drawn field of view inside the mirror window and the wearer saw **no change at all**, so the projection this patch writes is not what the scope picture is drawn with. Kept because it is the evidence for that finding and because SHOUT is a reusable way to ask the same question of any future candidate site. Dossier §9av; note `modding-notes/2026-09-19e-disproved-that-hook-does-not-draw-the-scope.md`. ⚠️ Never ship SHOUT on. Applies **on top of**
  `mirror-exemption-v2.patch`, same file, same hook site. Gives the mirror pass a **steered**
  projection instead of the eye projection it is handed today: `m00`/`m11` (how wide the frame is)
  are left exactly as they are, and only the off-centre terms `m20`/`m21` are written, so the cone
  that gets drawn is **moved onto the bore rather than widened**. Pixels per degree are therefore
  unchanged — the scope loses no sharpness — and the plugin's crop sits at the centre of the frame at
  every angle, which is why it can no longer run off the edge and smear. Reasoning and the numbers:
  `engine-research/ENGINE-DOSSIER.md` §9aq, fix (1b).

  Exposed as **`Steer Mirror Projection (scope, fix 1b)`** in REFramework's VR menu, **off by
  default**, with: a manual yaw and pitch slider (±75°) for sweeping it with no headset on; an
  **Invert** tick, because the sign of the shift is `[hypothesis]` and not measured; a **steer from
  the plugin** tick, fed by the two exported functions below; and a **steer the native projection
  instead** tick, which separates "the steer never reaches the frame" from "it reaches it but the
  base matrix was wrong".

  It also exports two C functions from `dinput8.dll`, so the scope plugin can hand over the real
  bore angle it already computes without either side needing a REFramework API change:

  | Export | What it does |
  | --- | --- |
  | `void REF_SetMirrorSteerAngles(float yaw_deg, float pitch_deg)` | the angle to steer to, camera-relative, +yaw right / +pitch up. Ignored unless *steer from the plugin* is ticked. |
  | `int REF_MirrorSteerIsEnabled()` | 1 while steering is on, so the plugin can switch its crop to mode 2 by itself instead of the same fact being written into two config files that can disagree. |

  Reach them with `GetProcAddress(GetModuleHandleW(L"dinput8.dll"), "REF_SetMirrorSteerAngles")`.
  ⚠️ The exports exist in the built DLL `[compile-verified 2026-09-19]`; **nothing has called them yet.**

- **`grip-no-throw.patch`** — added 2026-09-21 (home PC). `src/mods/vr/games/RE8VR.cpp` + `.hpp`.
  Taking the two-handed grip no longer re-aims the gun at once: the rotation present at the moment
  the grip is taken is remembered in the gun's frame and removed afterwards. Logs every take with the
  angle it removed. `re8vr.grip_relative = false` restores the original. Reasoning: dossier §9cf.
  `[compile-verified 2026-09-21]`, not yet worn. Independent of the two mirror patches (different file).

- **`build-local-no-csharp.patch`** — build convenience only, no behaviour change: drops `CSharp`
  from the project's languages in `cmake.toml` so the build does not need the C# toolchain.

## Rebuilding it

```
git clone https://github.com/gmankab/reframework-pd-upscaler-build
cd reframework-pd-upscaler-build
git checkout 76298bd
git submodule update --init --recursive
git apply /path/to/build-local-no-csharp.patch
git apply /path/to/mirror-exemption-v2.patch
mkdir build && cd build
cmake .. -G "Visual Studio 17 2022" -A x64 -DDEVELOPER_MODE=ON -DCMKR_SKIP_GENERATION=ON
cmake --build . --config Release
```

The file that matters comes out at **`build/bin/RE8/dinput8.dll`** and is copied into
`C:\Steam\steamapps\common\Resident Evil Village BIOHAZARD VILLAGE\` on the home PC.

✅ **The build itself now works, and was run.** On 2026-09-19 (home PC) the tree at
`D:\RE2 REFramework builds\tools\REFramework-src\` — which already carried the v2 patch and then
took the steering change — was rebuilt with MSBuild against `build/RE8.vcxproj`:
**0 warnings, 0 errors**, `build/bin/RE8/dinput8.dll` produced, and both new exports confirmed
present in it with `dumpbin /exports` `[compile-verified 2026-09-19]`.

⚠️ **Still NOT verified:** that the three `.patch` files apply cleanly to a *fresh* clone at
`76298bd` in the order listed. The 2026-09-19 build was made from the working tree that already had
the changes in it, not by re-applying them, so the `git apply` steps above remain
`[inferred-static 2026-09-16]`. First person to rebuild from scratch should confirm and correct
this line.
