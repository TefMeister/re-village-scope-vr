# 2026-09-21b — our own distance ray, which says what it hit

`/pd`, home PC (RTX), no launch. **The game was not launched, and nothing here has been run.**

## Where this starts

Dossier §9bw: distance-follow's first live shot missed exactly as if there were no
correction at all. The log said the distance was **0.50 m**, which is not a wall. That
number is RE8VR's crosshair distance. Its ray keeps the **nearest** contact on the Bullet or
Attack layer, with a filter that leaves out only the player. So anything half a metre from
the muzzle catches it. The leading suspect `[hypothesis]` is our own hidden rig prop, parked
at the rifle.

## What was built — `[compile-verified 2026-09-21]` + tests, installed on RTX, NOT RUN

1. **`scripts/re8scope/ray.lua`, our own ray.** It uses the same cast RE8VR's live crosshair
   uses (`castRayAsync`, all hits, nearest first). It is issued in `LockScene`, the scene step
   where RE8VR also updates the muzzle, and read back once `get_Finished` says so. It fires
   from RE8VR's own muzzle position along its muzzle axis. Then it **walks every contact**
   and skips anything nearer than 1 m, and anything whose GameObject is ours (the rig, the
   spawned prop, the rifle) or the player. The first contact left is the distance. It fires
   at most 10 times a second, uses no hooks, and is fully `pcall`-guarded. If it fails once,
   it logs that once, switches off for the launch, and RE8VR's number takes over.
   - ⭐ **It reports itself.** A `[ray]` census line names what was used, the nearest raw
     contact, and up to four skipped contacts with the reason. It prints on the first cast
     and whenever that answer changes, at most every 2 s. **One launch in VR names what sits
     at 0.50 m.**
   - Why async and not the synchronous `castRay`: in `re8_vr.lua` the synchronous call is only
     behind a debug button. The async one runs every frame in the shipping mod, so it is the
     proven path.
2. **`pane.lua` prefers our ray** and falls back to RE8VR's number when ours is older than
   0.5 s or never ran. It now also writes `aim_raw` (the nearest contact, unfiltered) and
   `aim_src` (1 = ours, 0 = RE8VR's, −1 = none).
3. **Every `STRAIGHTENED` shot line** now says:
   `aim 12.3 m (our ray, nearest raw 0.50 m), crop aimed at 50.0 m (distance-follow OFF)`.
4. The far-distance easing moved out of `world_tick.cpp` (which was over the 800-line limit)
   into `far_dist.cpp`. It is a pure move, plus publishing `g_far_m`, and its numbers are now
   named.

**Distance-follow stays OFF.** Nothing the picture uses changes until `SCOPE-DISTANCE-ON.bat`
is clicked. With it off, this only measures and logs.

## Tests

- `scripts/tests/own_ray_test.lua` **15/15** `[verified-numerically 2026-09-21]`. It runs the
  shipped `ray.lua` against a mock engine. It checks that ours and too-close contacts are
  skipped, the nearest over both layers wins, sky reads as unknown, unfinished casts are not
  read, the rate limit holds, stale answers are not served, and a throw switches it off once.
  ⭐ **It caught two real bugs on its first run:** the first census line was being
  suppressed, and `ipairs` over a table with a nil hole silently skipped the rifle and player
  checks.
- `producer_split_check` 52/52 (the new callback pinned last), `producer_globals_check` PASS,
  `shot_frame_test` 59/59. Plugin build clean.

## What is NOT established

- That via.physics.Collidable's owner is reachable as `get_GameObject` / `get_Owner` on this
  build. If neither works, the census shows `?` names and only the 1 m rule filters. That is
  still enough for the 0.50 m case.
- That `Distance` is measured from the ray start. RE8VR assumes so, and the census compared
  against a known wall will show it.
- Whether the 0.50 m object is our prop. The census answers it.

## Next (`VR USER`, rides the same wear as the roll test in the morning note)

In the headset with the rifle, before any shot, read the `[ray]` lines in the log:

| census says | means |
| --- | --- |
| `skipped … 0.50 m …:<our prop name> (ours)` and `used` a sensible wall distance | the suspect is confirmed and the fix works. Distance-follow can be tried again with `SCOPE-DISTANCE-ON` |
| `skipped … 0.50 m …:? (too close)` | something unnamed at 0.5 m; the 1 m rule handles it, and the name has to come another way |
| `used` a distance that matches the wall you are aiming at | the ray is trustworthy |
| the `FAILED` line | our ray is off; RE8VR's number is back, and the error text says why |

Credit: **praydog** (REFramework, RE8VR — the cast shape is his).
