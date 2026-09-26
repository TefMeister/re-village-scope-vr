# 2026-09-26 (/pd, static, NO LAUNCH) — the RenderOutput has settings our dumps never showed

Follow-up to `../2026-09-26b-rifle-camera-draws-nothing/` (the rifle camera's layers exist but are never drawn).
**The game was not launched; nothing here has been run.** Source: printable strings in `re8.exe` (read-only; the
names are interface metadata, no game content is committed) and praydog's `src/mods/VR.cpp` (fetched 2026-09-26).

## What the exe names that our dumps missed `[inferred-static 2026-09-26]`

Our `camdump` listed only `get_*` properties. The type database also carries plain methods, and next to
`via.render.RenderOutput` it names:

| name | reading |
| --- | --- |
| `via.render.RenderOutput.OutputType` with `getOutputType` | an enum stored beside the values **Default / Composite / CompositeElement** (the neighbouring names interleave with another enum, so the member list is `[inferred-static]`, not read from the TDB) |
| `via.render.RenderOutput.RenderMode` with `getRenderMode` | beside **Default / LightWeight** |
| `set_OutputLowerLimit` / `get_OutputUpperLimit`, `setDrawDynamicShadow`, `setDynamicShadowingEnable`, `setCacheEnable`, `getRegion` | more RenderOutput switches the property dump did not show |
| `via.render.RenderTargetCompositor`, `RenderTargetCompositeElement` | what a "Composite" output would feed |
| `via.render.RenderTargetTextureResource.ResolutionType` = Absolute / Relative | how our `.rtex` target is sized |
| `via.render.CaptureToTexture` (component: `capture`, `set_BlendingTexture`, `get_AngleUpperLimit`) and the `CaptureToTexture` / `CapturePlane` shaders | the engine's own capture-to-texture path; purpose not established |
| `via.SceneManager.getSceneViews` / `get_ActiveSceneView` / `DummySceneView` | several SceneViews can exist; `via.SceneView` carries its own `camera_type` (praydog's RE8 layout, offset 0x6c) |

praydog's `VR.cpp` touches `RenderOutput` only for `set_DistortionType` on the primary camera; RE8's VR is
alternate-eye on ONE camera, so REFramework has no second-camera recipe for this engine build `[inferred-static 2026-09-26]`.

## The next flat run — every step is one command-file line (`camlua` needs no script reset)

Build first, exactly as the 26th: fresh launch → gameplay → numpad `.` → `cammake 20` → `campose 1` → `src8 1`.
Then, one line at a time, glass screenshot + `re8drive.py tail` after each:

```
camlua local o={} for _,m in ipairs(ro:get_type_definition():get_methods()) do o[#o+1]=m:get_name() end return table.concat(o,' ')
camlua return tostring(ro:call('getOutputType'))..' / '..tostring(ro:call('getRenderMode'))
camlua local r=primary:call('get_Chain') return 'MAIN camera output: '..tostring(r:call('getOutputType'))..' / '..tostring(r:call('getRenderMode'))
camlua ro:call('setOutputType', 1) return tostring(ro:call('getOutputType'))
camlua ro:call('setOutputType', 2) return tostring(ro:call('getOutputType'))
camlua ro:call('setOutputType', 0) ro:call('setRenderMode', 1) return tostring(ro:call('getRenderMode'))
camlua cam:call('set_CameraType', 2) return tostring(cam:call('get_CameraType'))
camlua local o={} local sm=sdk.get_native_singleton('via.SceneManager') local v=sdk.call_native_func(sm, sdk.find_type_definition('via.SceneManager'), 'get_SceneViews') return tostring(v)
```

(`get_Chain` on a camera returns its RenderOutput — seen in the 26th's `camdump`. The first line prints the real method names; if `setOutputType` is spelled `set_OutputType`, use that.)

**Reading it:** the glass turning from flat grey to the world at any line names the lever. A flat colour that turns
RED after `set_BackgroundColor(1,0,0)` would mean the layer now runs but draws nothing. Nothing changes on every
line → the missing piece is a SceneView of its own, and the next step is reading `getSceneViews` before building one.
