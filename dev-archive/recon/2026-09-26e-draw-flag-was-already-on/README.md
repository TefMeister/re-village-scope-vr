# 2026-09-26 night (/lm, flat, Opus) — the draw flag was never off; the glass is still empty

One launch, Claude driving, staging `e2fb2ff` installed (cammake ends with `draw_on()`).

- **The GameObject flag bytes, read before `draw_on` touched them:** `Update=255 Draw=1 UpdateSelf=0 DrawSelf=1`;
  managed `get_Draw=true`, `get_DrawSelf=true` `[verified-live 2026-09-26, n=1]`. Our `set_Draw(false)` in `make()` never
  took, so **§9cs's "our draw flag was left off" is disproved** — the draw switch is not why the layer never runs.
- Camera `+0x48` already reads `0xFFFFFFFF` (-1, praydog's "never primary") on our camera; the main camera's is 185301.
- Glass: HDR source = the same junk (98,51,24), 8-bit source = flat grey (35,40,48), unchanged after `campri -1` and walking.

The reader's leads for next time (its file: `engine-research/inbox/2026-09-26-reader-primary-camera-hook-in-lua.md`):
1. build the camera inside `on_pre_application_entry("LockScene")`, praydog's moment, not from `re.on_frame` `[hypothesis]`;
2. **do not call `set_RenderTarget`** — praydog never does; his clone renders to its default output (ID 3) and VR.cpp copies the
   picture out of the clone layer's `PrepareOutput` state. Our custom target may be what diverts the layer `[hypothesis]`;
3. never create `ExperimentalRayTrace` (praydog blacklists it; our `camcopy all` made one);
4. copy MainCamera's components in its own order.
