# 2026-09-21 19:11-19:20 -- the two-source drift run, and the drift work PARKED by Tefa

Home PC, Tefa in the headset, `dinput8` `4262e542...` (dossier 9cj), scope at 720p.

Tefa: *"once the drift get's a hold of the left hand, it really does just start pointing at whatever
and almost feels like doesn't want to let go either once it starts drifting. i'm getting angles like
this ... just all of a sudden when aiming down the sights. but, that is also something that we will
park, because this is how the game has always been ... it is affected by all sorts of things and actual
hardware, light conditions and so on"* `[reported 2026-09-21]`. Screenshots 01 and 02 are theirs.

`grip-watch.txt`, 1,030 samples at 4 Hz, both steering sources tried live (606 CONTROLLER, 424 HAND POINT)
`[measured 2026-09-21]`:

| asked-for steering | average | maximum | samples over the 25 deg limit |
| --- | --- | --- | --- |
| by HAND POINT (praydog's, 16 cm wrist lever) | 36.1 deg | 135.1 deg | 796 of 1,030 |
| by CONTROLLER (its own position) | 26.6 deg | 116.3 deg | 454 of 1,030 |

During the over-25 samples: left wrist turning 16 deg/s, left hand 14.8 cm/s on average.

**What this does and does not say.** The controller source asks for less, so the wrist lever is a real
amplifier -- but it is not the cause: both are far too large. ⚠️ **An average of 27-36 deg is too big to be
tracking error alone and points at the DESIGN of "steer relative to the take":** the grip is taken the
moment the hand comes within 10 cm, usually while it is still travelling, so the reference direction is
an arbitrary mid-movement one, and settling into the real hold reads as tens of degrees of "steering"
`[hypothesis]`. It also explains *"doesn't want to let go"*: past the limit the applied steering sits
pinned at 25 deg until the hand comes all the way back `[hypothesis]`.

**Where to restart, when Tefa un-parks it:** (1) take the reference once the hand has been still for a
moment (or ease it in over ~0.3 s), not at first contact; (2) ease back from the limit instead of pinning;
(3) only then judge tracking itself. The levers that exist today: `GRIP-FRONT-LOCKED.bat` (immune by
construction), `GRIP-FRONT-HALF.bat`, `GRIP-BY-CONTROLLER.bat`, and `GRIP-SNAP.bat` for praydog's original.
