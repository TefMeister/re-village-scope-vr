# 2026-09-21 17:47-17:51 -- the grip take is removed, and the FIRST SHOT after a take still jumps

Home PC, Tefa in the headset, first wear of `grip-no-throw.patch` (dinput8 `3b9cba91...`).

Tefa: *"steering feels good, the weapon still sharply jumps left and down slightly after putting hand
on it. the last 3 shots i did, 1st was with the jump, then i held my hand on the rifle and shot 2 more
and they did not make the gun jump left and down"* `[reported 2026-09-21]`.

`takes-and-shots.txt`, 12 grip takes and 10 shots `[verified-live 2026-09-21]`:

- every take logged 3.3-15.5 deg REMOVED -- so a real ~10 deg throw at the take existed and is gone;
- **every first shot after a take: muzzle moved 4.6-5.1 deg in the 3 ticks before the bullet**
  (shots 1, 2, 3, 4, 5, 7, 8);
- **every shot with the hand kept on since the last shot: 0.6-0.8 deg** (shots 6, 9, 10) -- the last
  three shots are 8, 9, 10, exactly as the wearer described them;
- a fresh take follows ~2 s after most shots: working the bolt counts as a reload, which ends the grip.

The 4.8 deg is the same figure dossier 9cd measured BEFORE the patch, so the patch did not touch it.
Cause and second fix: dossier 9cg.
