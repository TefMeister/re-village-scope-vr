# 2026-10-01 (evening): the two grip fixes come back, in Dr.BeGonE's script, not in a patched loader

*Home PC, no game running, at Tefa's request: "integrate the 2 fixes into our re village plugin to make the gun
not jump left when shooting two handed and also make the gun only grippable by LG".*

## What was wrong

The v1.0.0 and v1.0.1 releases run on praydog's stock REFramework. The two grip rules Tefa wore and liked on
2026-09-21/22 lived in our patched loader (`dev-archive/reframework-patch/grip-no-throw.patch`), so they were lost
when the loader went back to stock, and Tefa saw both faults again on 2026-10-01 at 00:10:

- the rifle jerks left on the first shot after the left hand goes on (praydog steers the rifle against the grip
  socket the animation gives him each frame, and the firing pose moves that socket by about five degrees);
- the rifle docks into the left hand the moment it comes within 10 cm, with no button held.

Tefa's decision at 00:20 was option 2: the rules go into our own code and the release stays on stock REFramework.

## What was done

Both rules now live in Dr.BeGonE's `re8_vrz_begone_grip.lua` (BeG0nE repo, `occlusion-drift/games/re-village/`),
where the grip moved earlier today. They run right after each of praydog's three hand updates per frame, using only
REFramework's public Lua API:

1. the controller poses are computed again exactly the way praydog's C++ does it (same camera matrix, HMD transform,
   controller transforms and hand offsets);
2. the grip decision is remade: no left grip button, no grip (fix 2) — a dock praydog made without the button is
   undone and both hands go back to the controllers;
3. while gripped with the button, the rifle is steered against the socket **frozen at the take** (fix 1); the
   animation may move its hand, the gun does not follow. Steering is the shortest turn from the frozen socket line
   to the real hand line, so no roll is invented. In the stacked zone there is no steering at all, as before.
4. both hands' IK targets are set once more.

**Why Lua and not a native hook from `re_scope_vr.dll`:** `RE8VR::update_hand_ik` is not exported, so a native
hook would need a byte-pattern scan of praydog's loader and would break on every REFramework build. The Lua pass
needs nothing from inside the loader and gives the same result: stock REFramework, only our files added.

**It proves itself.** Praydog's own right-hand position is compared with our recomputed one on every pass (and its
rotation whenever he is not steering). After 300 agreeing passes the log says `pose check: … the recompute is
right`; if they ever disagree by more than 3 mm or half a degree it says `POSE CHECK FAILED` and the state line
reads `pose check FAILING`. `grip button 0` and `grip freeze 0` put praydog's behaviour back live for an A/B.

## Verified without the game

- `luac -p` clean; `tests/grip_split_test.lua` 8/8; new `tests/begone_grip_fixes_test.lua` 14/14 (loads, the
  three registrations, the words, the steering maths) `[compile-verified 2026-10-01]`.
- The maths and the pose recompute are `[inferred-static 2026-10-01]` against praydog's `RE8VR.cpp` at
  `a24c3459`; the in-game pose check is what turns that into verified.

## Installed on the home PC (21:53), not worn

- `reframework/autorun/re8_vrz_begone_grip.lua` (sha256 `5e348600…`), `re8_vrz_scope_sounds_menu.lua` and the
  updated `re8_scope_harness.lua` (the 2026-10-01 split from the dev PC, first time on this PC).
- `re8_vrz_scope_left_grip.lua` taken out of the game folder; copy in
  `D:\RE Village REFramework builds\deploy-backups\_archive-2026-10-01-grip-split\` and in staging
  `scripts/archive/`.

## Read after the first wear

- `pose check: N passes within X mm / Y deg … the recompute is right` once, soon after the rifle is out.
- `grip taken #N with the button: socket frozen at …` on each left-grip press near the rifle.
- `the ANIMATION has moved the socket X deg under the held grip -- IGNORED` on the first shot after a take.
- `docked the left hand without the left grip button -- undone` when the hand strays near the rifle with the
  button up.
- Tefa judges: no left jerk on the first shot, no dock without the button, the stacked grip still takes, the hand
  stays in its captured spot. `[hypothesis]` that the shortest-turn steering feels like the 2026-09-22 build.

## Still to do

- Send praydog the grip patch upstream (Tefa's decision, no waiting on it).
- Dr.BeGonE still needs the scope's rifle camera to exist, so it only acts with the sniper rifle; standing alone
  for every long weapon is its own next step.
