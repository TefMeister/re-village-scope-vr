# 2026-09-13g — The crate as the rig host: invisible walls, and a spare rifle at the world origin

Home PC `RTX`, `/ms`, 20:43–21:10, Tefa wearing. Continued straight after the PC blue-screened at
20:13 (`CLOCK_WATCHDOG_TIMEOUT`, first bugcheck in the System log since 2026-07-23; the crashed
session's claim was taken over with `--force`).

## Tefa's ask

Put a box on the rifle instead of the goat, **visible**, to see whether enemies can break it.
And a standing rule for this project from now on: **no goat.** *"it is an item that adds to a
secret-found counter"* — the goat totem is a Goat of Warding collectible. Every rig host must be
something other than `sm80_382_totemeveryware`.

## What happened

1. `pfb 3` + `bringup` spawned the **goat** anyway: `bringup` called `fn pfb_goat` unconditionally
   and then hid the host with `goat_matoff`. Fixed: `bringup` keeps a `pfb <n>` choice and hides only
   the goat `[compile-verified 2026-09-13; bringup_sequence_test 23/23]`.
2. Built by hand with candidate 3 (`sm83_015_physicswoodbox_00_itemspawnbreak`). Tefa: *"it's not
   riding the rifle still."*
3. `fn host_census` (new, `re8_scope_host_follow.lua`) showed the crate's shape
   `[verified-live 2026-09-13, n=1]`:
   - the root carries no mesh (`app.PropsBreakItemBoxParam`, `app.PropsUpdater`, a behaviour tree);
   - the visible crate is a **child** of the root with its own `via.physics.Colliders`,
     `via.dynamics.RigidBodySet` and `app.PhysicsRigidbody` — sitting at the spawn point, 89.9 m
     from the root;
   - ten more `_Break` pieces (the shards, with the same physics) sit at the world origin.
4. **The real bug: the rig was riding the wrong rifle.** `find_rifle` took the first `ri3042*` mesh,
   and three exist; the one it took sits at the world origin among the pooled `ri5xxx` item models
   (heartbeat `rifle=(0.00,0.00,0.00)` while the plugin's own joint read (−91, −10, −18))
   `[verified-live 2026-09-13, n=1]`. Fixed: take the copy nearest the camera. After the fix the
   heartbeat read the real rifle (0.36 m from the camera) and the rig root followed it
   `[verified-live 2026-09-13, n=1]`.
   - ⚠️ This may have been true at other times too: any "the goat floats" report is suspect until
     the heartbeat's `rifle=` is checked. `[hypothesis]`
5. With `fn host_follow` (every piece set onto the root's pose twice a frame), the log read all 11
   pieces at 0.00 m from the root, and the root travelled with the rifle.
   **But in the headset:** *"the movement got weird, like i got stuck in one place and there were
   invisible walls. the box did not land on the rifle though it was just floating up in the air."*
   Tefa closed the game. `[verified-live 2026-09-13, n=1 wearer]`
   - The walls are the crate's (and its ten shards') colliders being dragged along with the player
     `[inferred-static]` — so **any host with its own physics body cannot ride this way.**
   - "Floating up in the air" fits the rig's parked spot (fwd 1.0 / up −0.2 / right −0.715 off the
     bore, roughly an arm's length away) rather than a failure to follow `[hypothesis]`.

## What is and is not established

- Established: the crate's visible part is a physics child; the rig followed a spare rifle at the
  origin until today's fix; dragging a physics prop with the player makes invisible walls.
- Not established: whether enemies can break a riding host (never got that far); whether the scope
  picture worked on the crate (not looked at).

## The host shortlist (for Tefa's pick)

The community file list names only ~20 non-item prop prefabs. Item models (`*_detailsearch`,
`*_inventory`, ~690) are reaped by the item system at frame 3 (2026-08-29), so they are out unless
that is solved. Most non-item props are breakable boxes with physics — the crate's problem.

## 21:11–21:20 — THE HAND IS THE HOST. Tefa: *"it's perfect!"*

Tefa picked `sm08_045_madterritoryhand` from the shortlist.

- The plain path gave `get_Exist = false`; the file list names it only under `natives/stm/_ge/`,
  and **`_ge/environment/props/prefab/dynamic/sm0x/sm08_045/madterritoryhand/sm08_045_madterritoryhand.pfb`
  resolves** (candidate 15) `[verified-live 2026-09-13, n=1]`. So expansion-folder prefabs spawn
  with the `_ge/` prefix.
- Census: the mesh is on the root itself; components `via.Transform, via.render.Mesh,
  app.ObjectDefinition, via.motion.Motion, via.motion.MotionFsm2, app.MotionController,
  app.MadTerritoryHand` (+ our Mirror). **No colliders, no rigid body, no hit/damage parts, no
  children** `[verified-live 2026-09-13, n=1]`. So enemies have nothing to break `[inferred-static]`.
- Its own script hid it within 5 frames (`draw=false`, moved to the origin). `drive_on` + `fn goat_show`
  brought it back; the death-watch then read it alive, drawn and travelling with the rifle
  (heartbeat rig ~1 m from the real rifle across a walk) `[verified-live 2026-09-13, n=1]`.
- Worn with the usual sliders and two glass binds. Asked: hand visible / moves with the rifle /
  walking normal / scope picture. Answer: *"it's perfect!"* — taken as yes to all four
  `[verified-live 2026-09-13, n=1 wearer]`. Not asked separately, so the scope picture in particular
  deserves a second look next launch.
- `bringup` now defaults to candidate 15 and shows the host after `drive_on` (staging; test 29/29;
  deployed once the game is closed). `host_follow` is not needed for the hand.

## 21:21 — the hand made invisible, the scope still works

`fn goat_matoff` on the hand (2 materials on its 1 mesh off). Asked: hand gone / scope picture still
working. Tefa: *"like it should."* `[verified-live 2026-09-13, n=1 wearer]`. `bringup` now hides every
host again (staging, 29/29). **Not deployed at write-up: the game was still running** — copy
`staging/re-village-scope-vr/scripts/re8_scope_harness.lua` into the game's `reframework/autorun/`
before the next launch (the deployed producer and `re8_scope_host_follow.lua` already match staging).

The winning state now: hand host (candidate 15) + drive + the "this is the one" sliders + materials
off + glass binds. Left on the board: the slight shake (jitter) and the one-frame rifle flicker.

## 21:34–22:20 — zeroing the scope, and a save reload that broke the picture

- Tefa: *"the crosshair is pointing down and left from the actual muzzle direction."* Built `zeroup` /
  `zeroright` (plugin `g_zero_*`, `sg_zero_bore`: tilts the bore the exact map shows; + = crosshair up /
  right as seen). geom_test 124/124 `[compile-verified 2026-09-13]`; deployed and stamped.
- Door-ruler measurements from Tefa's circled screenshots, same spot, ~10–15 steps
  `[verified-live 2026-09-13, n=1 wearer each]`: zero 0/0 → hole +164 px right, −325 px up; zero 6/3 →
  +152, −173; zero 13/6.5 (new spot, slightly farther) → +60, −75. So `zeroup` moves the hole
  ~25 px/deg in the right direction; `zeroright` 3° barely moved it (+12 px) — unexplained.
  Setting at write-up: **13 up / 6.5 right** ("better"). The bullets fly ~13–16° above and ~6–9° right
  of the muzzle joint's axis `[inferred from the above]` — why is open (Fable).
- Tefa ran out of bullets and **reloaded a save**. After it: `rig pose: no transform` every ~8 s (the
  old hand died with the scene), `fn destroy_rig` + `bringup` rebuilt it, the heartbeat rode the rifle,
  mirror still latched at 1920 wide, the same Lua holder reused (no `rig rebuild #2` line). But the
  glass now showed a **grey wash over the top ~45–70% and Ethan's clothing**, worst turning right —
  none of it at the same zero before the reload (Tefa's screenshot 22:03, and *"it was not present at
  all"*) `[verified-live 2026-09-13, n=1 wearer]`.
- I chased it as a mirror-coverage limit (pane `pitch 186`/`196`, `yaw 96`: less wash, not gone). Tefa
  called it: *"i got this feeling that we are chasing the wrong thing."* The reload is the variable
  that changed, not the angle. Suspect `[hypothesis]`: Lua state that outlives a scene reload — the
  captured scene layers / layer camera (`st.scene_layers`, `st.layer_cam`) or the reused holder — now
  pointing at the old scene's objects. Test: Reset Scripts after the reload, then a clean `bringup`.

## 22:24–23:10 — the reload cause pinned, the scope zeroed, and what un-binds the glass

- **Save reload = "the security camera".** With the correction OFF the wash stayed; Tefa: *"it's because
  the hand is not riding the weapon. it's the security camera again"*, then with the hand made visible:
  *"the hand was riding the gun, but the picture in the scope was not moving with me"*
  `[verified-live 2026-09-13, n=1 wearer]`. Reset Scripts after the reload did NOT fix it; a full game
  relaunch did (*"the scope is fine again"*). Plugin lines: fresh launch → `rig rebuild #1: the latch
  followed (gen 1 -> 2)`; after the reload → `at the latched width (1920) and the latch did not change`.
  So after a save reload the plugin keeps reading the old mirror's pooled buffer while the new rig
  renders elsewhere `[inferred-static from those lines + the wearer]`. The grey wash and clothing
  were that stale picture, not the zero angle — the pane-tilt chase (`pitch 186/196`, `yaw 96`) was
  the wrong thing, as Tefa said.
- **Zeroing, fresh launches, circled screenshots:** 13/6.5 → +64 px right, −40 up (porch post);
  14.5/9 → +7, −46; 16.3/9 → +27, +14 (overshot); 15.8/10 crouched + aim button, 3 shots → a little low
  and left; 15.0/9.7 → a little left, ~3× that low (wall); **14.4/9.5 → Tefa played it "for real":
  *"the values are accurate"*** `[verified-live 2026-09-13, n=1 wearer, several spots]`. Now the
  `bringup` default; deployed + stamped.
- **The glass reverts to stock whenever the rifle leaves the hands and comes back** — weapon switch
  (log: `weapon changed: scoped=0` → `glass: restored 2/2` → `scoped=1 … press NUMPAD *`), and per Tefa
  also when grabbed by an enemy, maybe when hit `[verified-live 2026-09-13 for the switch, n=1;
  grab/hit reported]`. `bind` fixes it each time. Wanted: re-bind automatically on `scoped=1`.
- Tefa on the lag: the game gets laggier the longer it runs in VR, *"that has always been the case"*.
  Frame lines held 62–70 fps across 21:47–22:25 and private memory was flat over 30 s — not
  reproduced in the log `[measured 2026-09-13, one launch]`; worth a start/end memory reading on a long
  session.
- Tefa, at the end: *"finally got it to a point where i really think that now there is just tweaking
  and polishing work to be done."*
