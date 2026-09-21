# 2026-09-21c — the roll idea is dead; the two-handed miss is a snap just before the shot

Tefa in the headset, then `/pd` on the home PC. The game was still running when this was
written, and the fix below is **built but not yet installed**.

## What Tefa saw `[reported 2026-09-21, n=10 shots]`

- **One-handed, 5 shots:** every shot in the same place, off to the **right and up**. The
  group is tight, so this is a zeroing issue, not scatter.
- **Two-handed, 5 shots, re-gripping between each:** *"every time the gun teleports the muzzle
  a little to the left and that's where the shot lands, so the janking of the gun must happen
  a frame before the bullet flies out."*
- **The grey-blue wash is back** on the right of the glass, and it looks like sky
  (`dev-archive/recon/2026-09-21-roll-disproved-two-hand-snap/grey-wash-right-side.jpg`).

## What the log says `[verified-live 2026-09-21, n=10]`

- **§9ca's roll hypothesis is DISPROVED** `[disproved 2026-09-21]`. Across all ten shots the
  roll went from +1.2° to +5.7°, and the zero as seen moved under 1° (−15.7/−10.7 →
  −15.1/−11.5). The one-handed and two-handed groups differ by about 3° of roll. A 19°
  correction turned by 3° moves about 1°, which is nowhere near the miss. `RIGHT-FLIPPED` sat
  on every shot: it is a fixed sign convention, not a jump.
- The bullet again left along the scope axis at the shot (0.00°, n=10). Tefa's sighting is
  what explains this: the axis at the shot is the one **after** the snap, while the crosshair
  they aimed with was the one **before** it.
- **Our own distance ray works** `[verified-live 2026-09-21]`. It read the aimed-at walls at
  13.0 m and 22.5 m, and object names come through (the owner accessor exists). In 76 census
  lines **our own scope parts never appeared**. The only too-close contacts were world
  objects when standing next to them (a signboard at 0.27–0.62 m, a door at 0.92 m). So
  §9bw's 0.50 m was most likely the world, not our prop `[inferred-static 2026-09-21]`, and
  the 1 m rule covers it either way.
- **One-handed right-and-up at 13 m:** the reference zero was set from afar, and parallax at
  13 m pushes right by about 1.3° (§9bw). Distance-follow exists to cancel exactly that, and
  its distance source is now trustworthy.

## Built — `[compile-verified 2026-09-21]`, NOT INSTALLED (the game was running)

- **The bullet takes the scope axis from 2 ticks before the shot** (`bore_history.h`, a
  16-tick ring filled at the start of each world tick). The file `re_scope_prejump.txt` sets
  it: 0 = the old behaviour, 2 = default, up to 8. The helpers are `TWO-HAND-FIX-ON.bat` and
  `-OFF.bat`.
- ⭐ **It proves itself.** Every shot line now adds
  `axis 2 tick(s) back USED, X deg from the axis at the shot | muzzle moved over the last 4 ticks: a b c d deg`.
  One-handed should read about 0 everywhere. Two-handed should show the snap as a step, and
  **which** tick it lands on says whether 2 is right.
- `bore_history_test` 10/10 on the shipped ring. `shot_frame_test` still 59/59.
- **Also fixed:** the session log opened with `fopen_s` and could not be read while the game
  ran. It now opens shared (`_fsopen`, `_SH_DENYNO`).

⚠️ **Not established:** that the snap lands inside 2 ticks. The four-tick movement list decides
it. It is also not established that one-handed aiming is unaffected; the same list shows it.

## The grey wash — not diagnosed

At 13:05:56 the crop sat at u ≈ 0.55–0.60, and the pane's normal was about 11° off square to the
bore. The straight vertical edge in the capture looks like a clip boundary, not a texture fault
`[hypothesis]`. Two candidates: the mirror's own clip plane (the pane), or the crop reaching
past the rendered area. **Not settled here.** It has resisted several sessions before, so the
next look should be a deliberate one.
