# The next flat run: the rifle camera ONLY — no mirror rig (built 2026-09-26 by /pd, Opus)

Autostart `1 1920 clone` (already set on RTX) now means **rifle camera only**: `clonescope 20` → `glassaspect 1.0` + numpad `*`
with re-presses at +1/+5/+20 s; no rtex, no numpad `.`, no bringup, no Mirror. `clonerig` keeps the verified rig-first way.
The re-draw now checks the clone, not the rig. `[compile-verified 2026-09-26]` (autostart test 36/36), nothing run.

1. Launch → gameplay (the save has the rifle in hand). Expect: `rifle in hand -- starting the rifle camera (no mirror rig)`,
   `clone_src #N`, **`MIRROR SOURCE latched: 2560x1448 fmt=29`** (latched, not REPLACED — nothing else was latched first),
   `2/2 rifle camera up`, the plugin's `glass: material[..]` bind lines, `DONE -- rifle camera on the glass, no mirror rig`.
   **No `P10` / `m6_mirror` rig lines.** Glass: the magnified view down the rifle.
2. **The re-draw:** switch weapon and back (keyboard `1`/`2` quick slots in `re8drive.py`; screenshot to confirm the pistol, then
   the rifle): `rifle camera removed`, then a fresh `clone_src`, `DONE`, and `auto re-bind: the glass took`. The glass live again.
3. **The speckle band** (still open; not the padding rows): with the clone up, one `camlua` per step, glass screenshot after each:
   `clonelook 0` (stop copying post-process) → then disable the clone's components one at a time by type, e.g.
   `camlua for _,c in ipairs(...) do ... set_Enabled(false)` on `via.render.SSRControl`, `SSAOControl`, `SoftBloom`, `MotionBlur`,
   `FakeLensflare`. Whichever removes the dots is the cause (SSR / temporal effects without last-frame matrices are the suspects).
   If none: the compositor — `src8 0/1`, `hold 0`.
4. Frame time with and without the mirror: the plugin's `frame:` line (fps) vs the 2026-09-26 run's 159 fps.
