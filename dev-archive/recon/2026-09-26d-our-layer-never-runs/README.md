# 2026-09-26 evening (/lm, flat, Opus) — our camera's Scene layer never runs, whatever it holds

One launch, Claude driving. Tools: `camopts`, `camset`, `camlua` (staging `8131ebe`).

| step | result |
| --- | --- |
| `camopts` | the real names are **`getOutputType`/`setOutputType`**, **`getRenderMode`/`setRenderMode`** (no `get_`/`set_`); ours and MainCamera's both read **0 / 0** `[verified-live 2026-09-26, n=1]` |
| `setOutputType` 1, 2, 0 (read back 1, 2, 0) | glass unchanged (flat grey 35,40,48) |
| `setRenderMode` 1, 0 (read back) | unchanged |
| `set_CameraType` 2, 6, 0 (read back) | unchanged |
| `set_RenderOutputID 3` (praydog's clone uses 3 = "Tertiary") | unchanged |
| **`set_Camera(MainCamera)` on OUR plain Scene layer** (read back = main camera) | **unchanged** |

**The load-bearing result** `[verified-live 2026-09-26, n=1]`: with the game's own main camera on our layer, the
target still never gets a pixel. So the fault is not our camera object, its components, pose, type or output
settings: **the Scene layer that the engine builds for a camera of ours is never executed.** The parent
`via.render.layer.Output` exposes only `get_SceneView` / `get_Viewport` to the TDB; the `registerScene` /
`isRegisteredScene` names the reader found in `re8.exe` are not reachable from Lua (`isRegisteredScene` → nil).

⚠️ Method lesson: an REFramework `obj:call()` of a method that does not exist returns **nil with no error**, so
`camset`'s "try set_X then setX" reported success on a name that did not exist. Read the method list first.

The reader's report (praydog's `CameraDuplicator.cpp` on branch `pd-upscaler`, guarded `TDB_VER >= 69`, output id 3,
draw flag, copied components) is in `engine-research/inbox/2026-09-26-reader-sceneview-for-a-second-camera.md`.
What is left is native: how that duplicator gets its clone's layer executed — read on that branch, then decide
whether a plugin-side registration is worth it against the mirror rig that already works.
