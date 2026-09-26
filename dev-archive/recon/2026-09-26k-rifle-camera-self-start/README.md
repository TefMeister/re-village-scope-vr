# 2026-09-26 night (/lm, flat, Opus) — the rifle camera STARTS BY ITSELF

Plugin `a169a870`, autostart file `1 1920 clone`. `[verified-live 2026-09-26, n=1]`.

- The save came up with the rifle in hand. Log, in order: `autostart: rifle in hand` → 1/3 target 1920 → 2/3 re-arm (taken 0.15 s)
  → 3/3 bringup → `DONE -- rig present 0.21 s after the rifle was seen` → `clone_src #30854 published` → `4/4 rifle camera queued` →
  `MIRROR SOURCE REPLACED … 2560x1448` → **`DONE -- rifle camera on the glass, 0.81 s after the rifle was seen`**; clonepose bore
  looking (−1.000, 0, 0) (straight ahead, along the main camera), FOV 20 and **near 0.60 read back**, 219 post-process values copied.
- **The glass: the door ahead, magnified and sharp; no front sight in view** (the 0.60 m near plane does what the 0.60 m push did,
  without moving the eye).
- **The white speckle band along the top is STILL THERE** with `v=0.4972` (1440 of 1448 rows) applied — so the padding-rows reading
  is `[disproved 2026-09-26]`; its cause is open (candidates: something in the compositor's path for the 8-bit source — sky fill /
  threshold, the flicker ring, the hold — or in the clone's own render near the top of its view) `[hypothesis]`.
- Not tried: holstering and redrawing (the kill/rebuild cycle) — no weapon-switch key is mapped in the control profile yet.
- Incidental: this launch went title → gameplay without the load prompt, and the automation's "confirm" key opened the door in front
  of the player (harmless) — the control profile's route assumes the prompt.
