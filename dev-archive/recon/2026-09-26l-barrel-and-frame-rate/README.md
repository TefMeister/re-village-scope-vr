# 2026-09-26 evening (/lm, flat, Opus) — the barrel measured, the speckle gone at 1920, and the FRAME RATE problem

Tefa: *"the one thing showing still is the rifle barrel at the top of the scope, that needs to be removed somehow."*

`[verified-live 2026-09-26, n=1]` unless noted.

- **Rifle camera only (no mirror rig) works:** `clone_src` → `MIRROR SOURCE latched: 2560x1448` (latched, nothing before it) →
  `2/2 rifle camera up 0.61 s after the rifle was seen` → glass bind + 3 re-presses → DONE. No P10 / rig lines.
- **The barrel, measured:** the `vfx_muzzle` joint is **0.797 m ahead of the scope camera and 6.3 cm below its line of sight** —
  inside a 20° view. Near plane 0.6 m: a small dark barrel tip above the crosshair; 0.9 m and 1.2 m: gone. **Fix: near plane = muzzle
  distance + 5 cm, computed from `vfx_muzzle` every frame** (it only "sees through" what the barrel itself is poking into). At the door
  (under 1 m away) any near plane ≥ 0.9 m shows through the door into the snow — the same situation.
- **The speckle band is NOT the barrel** (still there at near 1.2 m on the 2560 target) — **and it is ABSENT on the 1920×1088 target**
  (clean wall + gold sconce, full and bare clone). So it belongs to the 2560 path `[hypothesis: the 2560×1448 target / its view]`.
- **⚠️ FRAME RATE:** with the rifle camera rendering, **26 fps** (37.7 ms, very steady); clone killed: **177–182 fps**. Same with
  `clonelook 0`, with a **bare** clone (camera + output only), with `setRenderMode 1`, at 1920 and at 2560. A ~32 ms fixed cost per
  frame, independent of what the clone draws, reads like a WAIT, not rendering work `[hypothesis]`. (The "143 fps at 1280" readings
  were a clone that never rendered: its 1280 target was never allocated/latched.) For comparison the mirror rig ran at 159 fps.
  Suspects: the installed pd-upscaler REFramework's TemporalUpscaler/DLSS handling a second non-VR view; a per-view GPU sync.
