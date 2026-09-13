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
