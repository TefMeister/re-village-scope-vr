# The next flat run: does our camera have matrices at all? (written 2026-09-26 late by /pd, Fable)

**The reading behind it** `[hypothesis 2026-09-26]`: REFramework's VR code hooks `via.Camera.get_ViewMatrix` / `get_ProjectionMatrix`
and, in multipass, OVERWRITES the result for both of praydog's cameras (`VR.cpp` `on_camera_get_view_matrix` / `_projection_matrix`,
`m_multipass_cameras[0..1]`). Without a headset those hooks return early. So in VR his clone never needs the engine to compute its
matrices; in flat, ours does — and a camera whose GameObject never updates (praydog's `shouldUpdate=false`, which we copied) may hold
zero/garbage matrices, and a renderer handed a degenerate frustum can skip the layer without even clearing it (the junk we see).
Also: the plugin's **numpad `+`** already reads the latched source back (luminance min/max + 8×6 blocks) — an "is the target
written" instrument that needs no glass.

Fresh launch, gameplay, one word per rung, `re8drive.py tail` after each:

| # | words | answers |
| --- | --- | --- |
| 1 | `clonemake rt` (wait 4 s) → `camcmp` | which raw dwords differ main vs clone; **are our View/Projection matrices zero/nil while the main's are not?** |
| 2 | `matscan` | where the main camera keeps its world/view matrix (the row holding its position) — and what ours holds there |
| 3 | numpad `+` twice, 3 s apart (mirror mode, latched on the clone's 2560 target after `.`) | the target's real pixels: unchanged junk / cleared / a scene |
| 4 | `clonekill` → `clonemake rt upd` → `camcmp` → numpad `+` | **UpdateSelf ON from creation**: do the matrices appear, and does the target get written? |
| 5 | if 4 gives matrices but no picture: `camlua` copy the main camera's FOV/near/far/aspect onto ours, `+` again | |
| 6 | if ours has no matrices in 4 either: the next build is a `get_ViewMatrix`/`get_ProjectionMatrix` post-hook from Lua that fills the result for our camera from the main's (reader's hook skeleton in §9cs) — but check first whether the Lua post-hook can write through `retval` (a pointer) | |

**Reading:** matrices present + target written after `upd` = the missing piece was the camera update, and the rifle camera is on.
Matrices present, target still junk = the engine skips the layer for another reason; go to the plugin execution detector. Matrices
absent even with `upd` = a runtime-made GameObject is never updated by the scene; rung 6.
