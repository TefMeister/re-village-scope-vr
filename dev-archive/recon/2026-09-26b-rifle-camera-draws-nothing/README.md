# 2026-09-26 afternoon — the rifle camera's layers exist, but the engine never draws them

Home PC, flat (no headset), Claude driving, **Fable**. Three processes (one reload-heavy, one fresh). Test
tool: `scripts/re8_scope_cam_probe.lua` (staging `09ca806`), words `cammake / campose / camupdate / camcopy /
camlayer / camlayerout / camdump / camlua`, all inert until sent.

## What the glass showed, and what each picture really was

| picture | source | what it is |
| --- | --- | --- |
| `run2-cammake-wrong-copy-brown.png` | plugin default (`src8 0`): the fmt=26 "raw-HDR" allocation the catcher UPGRADES to | **junk memory**: a cloudy blob left, horizontal streaks right; flickers frame to frame (mean pixel change ~24) but does not follow the camera (walk / camera-to-origin change it by the same amount as standing still) `[verified-live 2026-09-26, n=3 shots]` |
| `run2-src8-1-flat-grey.png` | `src8 1`: the 8-bit fmt=29 texture = our own `.rtex` target | **a flat colour** (35,40,48), later (8,7,7) on a 2560 target: the target is cleared and never drawn into |
| `run3-after-camcopy-all-still-flat.png` | same, after every `via.render.*` component of the MainCamera was created on ScopeCam (20 made, no takeover, no crash) | unchanged |
| `run3-background-red-no-change.png` | same, after `set_BackgroundColor(1,0,0)` on the RenderOutput AND on the layer (both read back red) | unchanged: not even the clear colour reaches the glass |
| `run3-2560-hdr-junk*.png` | fresh 2560×1448 target (created by hand so the catcher had a fresh allocation to latch) | the same junk, with the camera on the rifle and at the world origin |

## Facts `[verified-live 2026-09-26]`

- `cammake` gives the engine a camera it registers fully: **two Scene layers of ours** (one plain, one with the scope's Mirror),
  **13 child passes each** (SubScene, PreZforCull, GBuffer, DeferredLighting, Solid, …, PostEffect, Overlay, PrepareOutput),
  sized exactly to our target (1920×1088 / 2560×1448), `Enable=true`, `RenderOutputID=2`, near 0.1 / far 1000, aspect right.
  No takeover of the primary camera in any of ~8 makes.
- **Nothing is ever drawn into either of its buffers.** Pose (origin vs rifle), `UpdateSelf` on/off, walking, 20 extra render
  components, the background colour: none of them change a pixel of what the catcher shows.
- The FOV we ask for (20) is overwritten to **26.23** within 2 s every time (who: unknown `[hypothesis: the VR mod's FOV push]`).
- `get_OutputRenderTarget()` / `get_RenderTarget()` return a fresh wrapper object on every call, so holder addresses cannot be
  compared; the holder type exposes no methods or fields to the TDB.
- The 2026-09-25 VR "flat sky-blue" and today's flat grey are the same thing: an undrawn, cleared target.

## Method lessons (they cost most of the afternoon)

- **A script reset (`Reset scripts`) breaks the rig's layer bookkeeping**: the autostart rebuilds the rig before the layer hooks are
  re-armed, `st.our_layer` then points at a dead layer, and every tool that walks the parent Output layer through it reports
  "no parent". `rerig` re-captures layers, but the 2nd `rerig` in a process re-uses the `.rtex` texture (no fresh allocation), so
  the plugin's catcher stays PENDING and the glass freezes on a dead texture. **Prefer a relaunch to a reset.**
- `camlua <code>` now runs one line of Lua from the command file; every later experiment needs no reset.
- `via.render.layer.Scene.set_Enable(false)` reads back `true` (no effect), as the 09-25 knobs note warned.
- The catcher latches only a FRESH allocation; a `.rtex` path allocates once per process. To re-latch, use a path not used yet
  this process (`movie_2560_1440.rtex` worked after 1280 and 1920 were spent).
- `Reset scripts` in the overlay: Insert → click `ScriptRunner` header (146,658) → click `Reset scripts` (224,691), client
  coordinates at 1920×1440; the header is collapsed in a fresh process.

## What this means

A bare (or fully dressed) `via.Camera` + `via.render.RenderOutput` is not enough to make RE Village's renderer execute a second
view. The engine builds the view's layers but the frame never runs them. praydog's multipass duplicate that the 09-25 plan copied
is from a newer engine build (RE4 era) and could not be found in the current REFramework tree to compare. Open: what does an
RE8-era object that renders a camera into a texture (in-game monitors, security cameras) carry that ours does not.
