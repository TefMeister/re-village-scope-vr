# 2026-09-26 evening (Fable, home PC, flat, Claude driving) — THE "32 ms" WAS OUR OWN CODE

Tefa: *"please find the 32 ms slowdown"* (the rifle camera ran at 26 fps against 180 without it, dossier 9cx).

`[verified-live 2026-09-26, n=1]` unless noted. Log lines in `log-extract.txt`.

## How it was found

Two measuring tools, built first:

- **`re8_scope_frametime.lua`** (word `ftime 1|0`): hooks every entry of the engine's frame (`via.ModuleEntry`, 382 names)
  with a pre and a post callback and prints, every 2 s, the stages that cost the most as ms per frame — *inside* (post − pre)
  and *before* (this pre − the previous post, i.e. whatever ran in between: other scripts' hooks, REFramework, engine glue).
- **The plugin's frame line** now carries the end-of-present fence wait (`fence wait avg/max`), i.e. how long the GPU still
  had outstanding when we presented. Build 7f13b159.

With the rifle camera up: **frame 26.9 ms; `LockScene 0.1 / 20.9`** — 20.9 ms per frame in the gap *before* LockScene,
fence wait 3.7 ms. So the time was on the **game thread**, not the GPU, and not inside any engine stage: in the hooks that
run before LockScene. Ours runs there. `clonepose off` → **7.2 ms (139 fps)** at once; `clonepose bore` → 27 ms again.

**Cause:** `body_joint()` in `re8_scope_cam_clone.lua` called `rig.find_rifle()` **every LockScene** — a snapshot of every
`via.render.Mesh` in the scene plus a `get_GameObject` + `get_Name` on each (thousands of reflection calls) and a log line.
The earlier "fixed ~32 ms whatever the clone draws" (bare, LightWeight, 1920, 2560 all the same) fits exactly: the scan does
not depend on what the camera draws, and the bare clone still had the bore pose set.

## The fix

The rifle is found **once per clone** and kept (`st.clone_rifle_tf`); it is looked for again only when the kept joint stops
answering, never more than twice a second (`RIFLE_REFIND_S = 0.5`); `clonekill` forgets it. Also stops the log filling with
`find_rifle` lines (at the title screen the scan ran every 8 ms).

| state | frame | fps |
| --- | --- | --- |
| no clone (same spot) | 5.45 ms | 183 |
| clone, pose off | 7.2 ms | 139 |
| clone, bore pose, **before** | 27.0 ms | 37 |
| clone, bore pose, **after** (2560 target) | 6.7 ms | 150 |
| clone, bore pose, after (1920 target) | 6.3 ms | 158 |

So a real second view costs about **1.3–1.8 ms** here. The frame-stage probe after the fix: `LockScene 0.0 / 0.3`.

## Two more things done in the same run

- **The barrel:** the near plane now follows `vfx_muzzle` — muzzle distance along the view axis + 0.05 m, clamped
  0.30..1.20 — measured every frame from the kept joint (`clonenear auto`; `clonenear <m>` pins a value). Live:
  *"muzzle now 0.797 m ahead, plane 0.85"*. The barrel tip is not in `3-1920-muzzle-near-strafed.png`. At the door (under
  1 m away) the plane cuts the door and the glass shows the snow behind it (`4-…at-the-door.png`) — the known trade:
  the camera "sees through" whatever the barrel is poking into.
- **1920 first** (`CLONE_RTEX` order): the 1920×1088 target is taken first, 2560 is the fallback.

## Open, and one claim withdrawn

- **The speckle band is on the 1920 target too** (`3-`, `5-`), at the top ~25 % of the picture, with `clonelook 0` as well.
  The 9cx line "absent on the 1920×1088 target" was n=1 and is contradicted by this n=1 — treat it as **open**, not
  size-bound. Not the barrel (near 1.2 m did not move it, run 11), not post-processing (`clonelook 0`).
- **Outdoors the picture is blown out** (uniform light blue, `5-`): the exposure / brightness item, unchanged.
- Not measured: VR.
