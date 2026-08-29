# 2026-08-29 (home PC) — THE SPAWN WALL FALLS: prefab instantiation works, and the mirror pane is finally steerable

Session arc: the /gr research topic (external-research `2026-08-29-runtime-mesh-spawning-via-prefab-instantiate.md`)
was turned into the P-series buttons in `re8_scope_m6_mirror_producer.lua` (staging `c4052d3`..`HEAD`) and iterated
live with the user driving, one press per finding. Every result below is log-backed
(`re2_framework_log.txt`, `[m6_mirror]` lines, 10:29–12:00) and/or screenshot-backed.

## The findings, in discovery order

1. **`via.Prefab` → `set_Path` → `get_Exist` → `instantiate(via.vec3, via.Folder)` executes and returns a live
   GameObject** (P1). Overloads reflected live: six `instantiate` variants exist in RE8's TDB.
2. **Spawns from the UI/render thread die at frame 2 with an EMPTY component list** (P5 forensic + death-watch):
   born `Valid=true, Draw=true`, contents never constructed, engine reaps the shell. Folder vs no-folder made
   zero difference (P1 vs P1b — both frame-2 deaths).
3. **Spawning from the GAME THREAD (`UpdateBehavior`) fixes construction** (P6): the rifle prop *drew on screen*
   (user saw it flicker) — the first runtime-spawned geometry this project has ever rendered — then died at
   frame 3: **the item system reaps unregistered item-family props**. Different killer, one frame later.
4. **A NON-item prefab spawned on the game thread SURVIVES INDEFINITELY** (P7: 10,000+ frames, still valid).
   The survivor (`movie/prefab/c22e500_00_mirror.pfb`) turned out to be a cutscene **movie player**
   (`via.movie.Movie` + `app.MovieApp`) — the research note's "Capcom-assembled mirror" guess is **falsified**
   (P8 census) — but it proved the survival recipe.
5. **The goat totem (`sm80_382_totemeveryware_00_swing.pfb`) spawns, survives, and RENDERS**
   (P9 candidate cycle; screenshot `105641`). Recipe: **shipped prefab + game thread + non-item family.**
   The M18–M26 "runtime meshes will not draw in RE8" wall is down.
6. **The goat adopted as the rig hosts the mirror, and THE PANE FOLLOWS IT** (P10 one-press rig; screenshots
   `111734`/`111740`: the mirror, parked ahead of the barrel, photographs the rifle's own scope tube —
   proof the pane sits where our host sits). **Pitch/yaw slider changes CHANGE THE IMAGE** (user-driven) —
   the pane is steerable, which was this project's named linchpin. Position sliders move the goat but barely
   change the image — correct planar-mirror behavior (orientation dominates).
7. **User-found working angles: pitch 90°, yaw 135°** (lake/periscope geometry: pane flat along the sight
   line, yaw walking the reflected view onto the aim line). Baked as P10 defaults same session.
8. **Screenshot `110604`**: mirror content on the glass at PiP-level quality (user's own judgement) with the
   clip-plane grey half visible — the compositor grading + mirror source, live in gameplay.

## Failures and lessons (same session)

- **Shooting the host kills the pane** (screenshots `115559`/`115606`): the goat prefab carries real game
  logic; the user's accidental shot ran its shatter code, the pane died, and the glass degraded to a stale
  viewer-dependent reflection that "glitched out in all sorts of ways" when moving. Lesson: **the mirror host
  must be inert or hidden** — never something the game invites the player to destroy. (Open question flagged:
  whether the destruction ticked the goat-challenge counter; per-location-flag tracking would mean no, a plain
  counter would mean +1. User to check the records screen.)
- **Runaway scan fixed** (staging, this session): with the rifle holstered and drive on, `rig_pose_once`
  retried `find_rifle` every frame — a full 941-mesh snapshot scan ~140×/s. Retry now throttled to 2s.
- **F10 vs P10 confusion**: the P-series are MENU BUTTONS, not keys; F10 is the native plugin's flat-overlay
  toggle and got pressed by mistake. Standing numpad-only hotkey rule vindicated again; F9/F10 are legacy
  holdouts in the plugin and should migrate to numpad.

## Open problems (ranked)

1. **Grading**: the mirror renders raw pre-tonemap HDR; darks look right, brights blow out. Plan: reflect the
   live exposure values off MainCamera's own post-process components per frame and feed them to the
   compositor shader (same read-the-live-object method as everything else). Numpad 8/2 is the interim knob.
2. **Host of record**: replace/hide the goat — try `rig_mesh_draw(false)` on the goat (does the RT survive a
   hidden host? inherited M18 question), and/or hunt an inert non-item prefab.
3. **Zeroing**: with the pane steerable, park the clip plane behind the scope and bore-sight the view.
