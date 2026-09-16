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

## The two patches

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

⚠️ **Not verified by this session:** the patches were copied and read, **not re-applied and not
rebuilt**. `[inferred-static 2026-09-16]` — the recipe above is reconstructed from the fork's own
`build_vs2022_noautogen.bat` and the source tree's state on disk. First person to rebuild should
confirm both `git apply` steps go on cleanly at `76298bd` and correct this line.
