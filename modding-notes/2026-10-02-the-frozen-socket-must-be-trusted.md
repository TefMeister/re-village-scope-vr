# 2026-10-02 (midday): the frozen grip spot is only taken from a hand that can be trusted

*Home PC, no game running. Tefa picked this from the morning list ("1,2 and 6 please"). The grip script lives in
the BeG0nE repo (`occlusion-drift/games/re-village/reframework/autorun/re8_vrz_begone_grip.lua`); this note sits
here because the fault was seen with the scope mod's rifle and the wear uses this project's install.*

## What went wrong at 01:10

After a relaunch the rifle pointed far right at strange angles (Tefa). The log
(`dev-archive/recon/2026-10-01-startup-crash-again-same-address/re2_framework_log-2026-10-02-0110-rifle-far-right-after-relaunch.txt`)
shows why:

- the first auto-dock of the session froze the socket at `(0.100, -0.437, 0.176)` in the right hand's frame. That
  is 48 cm from the right hand and mostly straight down, and the very next two passes logged it moving 1.9 and
  3.3 degrees: the draw animation's hand, still travelling, not the rifle's grip at `(-0.367, -0.142, -0.001)`;
- every grip after that re-took within three seconds of letting go, so the "keep the earlier frozen socket" rule
  (written at 00:45 for the bolt swing) kept the wrong spot, and each re-take logged the animation's socket
  82 degrees off it. The steering turned the rifle to put that wrong spot on the real hand: far right.

So the 00:45 rule was right for the bolt swing and wrong for a first dock mid-animation. Nothing checked whether the
first frozen socket deserved to be kept.

## What was built

Three rules in the grip script, 644 lines, under the 800-line soft limit:

1. **A socket is frozen only when it can be trusted.** Trusted means it has held still for 0.3 s (strayed less than
   1 cm from where the wait began), or it sits within 10 cm of the captured rifle spot (the one in
   `re_scope_left_grip.txt`). Until then praydog's own live-socket steering stays as it is, and the log says once a
   second: `praydog docked, but the socket (…) is not trusted yet: still for 0.03 s (needs 0.3), 48.1 cm from the
   captured rifle spot (needs 10) -- praydog steers until it settles`. The take line now says which test passed:
   `grip taken #1 by itself (auto-dock): socket frozen at (…) (near the captured rifle spot)` or `(held still 0.31 s)`.
2. **A weapon change forgets the frozen spot** (praydog's `re8vr.weapon`, compared by address; none counts as a
   change too): `frozen socket forgotten: the weapon changed`.
3. **Five seconds without any grip forgets it** as well: `frozen socket forgotten: 5.2 s without a grip`. The
   bolt-swing re-take rule still works inside its three seconds.

Plus the word `grip forget`, which drops the frozen spot live, and a third state line under `grip` that prints the
frozen spot, how long ago it was released, and the trust rule's numbers.

The trust test is a pure function (`socket_trusted`), exported with the maths, and the test file
`staging/re-village-scope-vr/scripts/tests/begone_grip_fixes_test.lua` grew from 14 to 23 cases. Case 16 is last
night's exact numbers: the draw animation's socket against the rifle spot, 0.03 s still, must NOT be trusted.
`[compile-verified 2026-10-02, 23/23]`

## What is installed on the home PC

The new grip script (sha256 `5ec0b6dd…`), `re8_vrz_scope_sounds_menu.lua` and the new harness are in the VR
install's `reframework/autorun/`; v1.0.2's `re8_vrz_scope_left_grip.lua` is taken out, with a copy and a manifest in
`D:\RE Village REFramework builds\deploy-backups\_archive-2026-10-02-v102-grip-set-before-trust-wear\`. The install
record was re-stamped (50 files match). **v1.0.2 stays the shipped build** (Tefa, 01:10); nothing goes into a
download until the wear passes.

## The wear that decides it (Tefa, headset)

Hip fire two-handed with the left grip on the forestock, then holster, swap weapons, relaunch, draw again. Pass:

- the first dock after a draw logs `grip taken #1 … (near the captured rifle spot)` or `(held still …)`, never a
  socket 40+ cm from the hand;
- no `the ANIMATION has moved the socket 8x deg` lines; a few degrees at the shot is the firing pose, as before;
- `frozen socket forgotten: the weapon changed` on a swap, and the rifle points where the hands do after a relaunch;
- hip fire with the left hand on the forestock as still as aim-button-plus-left-hand (Tefa's requirement, 01:25).

If the rifle misbehaves in the headset: `grip forget` first; `grip button 0` and `grip freeze 0` put praydog's own
behaviour back live without a relaunch.

`[hypothesis]` until worn: the three rules remove the far-right rifle. The maths that steers is unchanged since the
00:20–01:00 wear, so the still shot measured then should carry over.
