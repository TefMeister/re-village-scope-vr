# 2026-09-22 (a) — Tefa's three asks: a zero that needs no tuning, the stacked grip, the flicker

Home PC, morning, no game running, Fable. Tefa asked for three things on the Village scope, in order:
(1) zeroing that is automatic — the bullet can only go where the cross points; (2) holding the left
controller ABOVE the right one, with the rifle still pointing straight, because every two-handed weapon
in every RE game drifts when the support hand is out in front where the headset cannot see it; (3) the
flicker. The jitter is parked by their call (mild, cherry on top). Everything below is BUILT and
INSTALLED, none of it WORN. Durable version: dossier §9cn.

## 1. The zero — the picture and the crosshair were using two different cameras

**Found, static, no game needed** `[inferred-static 2026-09-22]`: REFramework's VR menu has *"Mirror Uses
Original Camera Pose (plan C)"* and it has been **ON since 2026-09-12** (`re2_fw_config.txt`:
`VR_MirrorUsesOriginalCamera=true`). With it on, the mirror picture is drawn from the **game's own camera
pose** (`m_original_camera_matrix` — the pose the game had before REFramework wrote the headset pose into
the camera joint). The plugin's crosshair maths (`crop_follow.cpp`) reads the camera **joint** on the game
thread — the **headset** pose. Nobody ever handed one to the other, and the angle between them is a
crosshair error that changes with posture: exactly the list in §9cm — eight zeros in one day, "each
restart nudges it", "the world slightly angles".

⚠️ Last night's claim that the ~10° zero *is* the eye's off-centre projection does **not** survive today's
numbers: the projection logged at 20:16 gives 15.0° sideways / 13.0° up (`P20 ±0.2425 / P00 0.9027`,
`P21 −0.1932 / P11 0.8355`) against a fitted 9.2° / 10.9°. Different sessions, different FOV, and the
match was approximate. `[hypothesis]` at best — the view-frame zero it led to is still a good change.

**Built:** the patched REFramework now exports `REF_GetMirrorDrawPose` (the world matrix it drew the mirror
from, which of the two poses it was, and a counter). The plugin (`draw_pose.cpp`) takes it and, with
`reframework/data/re_scope_drawpose.txt` = 1 (now the default), **places the crosshair with the pose the
picture was really drawn from**. Once a second it logs how far apart the two poses are, in the joint's
own right/up terms, so the line reads against the zero the wearer tuned. Built-in check: with plan C off
the two poses are the same joint, and the line must read ~0°. `draw_pose_test` pins the matrix→rotation
maths (84 round trips, 0 failures) `[compile-verified 2026-09-22]`.

**Why this is "automatic zeroing":** the zero was covering a maths mismatch, and the mismatch is now
closed by construction rather than by a number. If the wear confirms it, the zero is 0/0 and stays 0/0
across cant, distance and restarts. The bullet already leaves along the scope axis (the STRAIGHTEN step),
so with the crosshair placed right there is nothing left for a bullet to disagree with.

**The test:** `START-SCOPE`, then `CROSSHAIR-FROM-DRAWN-POSE.bat` (drawn pose in use, zero 0/0, view
frame). Shoot near and far, rifle canted both ways. **Hits on the cross = the zero is gone for good.**
`CROSSHAIR-FROM-JOINT-POSE.bat` puts last night's setting back for comparison. Read the
`draw-pose:` lines: the angle should be of the order of the old zero (~10°) while plan C is on.

## 2. The stacked grip — left controller above the right, rifle still straight

**Read from the code** `[inferred-static 2026-09-22]`: RE8VR takes the two-handed grip only when the left
hand is within 10 cm of the forestock socket, keeps it while the left grip button is held, and then steers
the rifle along the hand-to-hand line. Stacked hands give a line that points at the sky, and the socket
is out of reach, so nothing about the old rule fits the pose Tefa wants.

**Built (`RE8VR.cpp`, same patch file as the grip work):** a **zone above the right controller** — 3 to
35 cm up, within 12 cm sideways (18 cm to let go, so a wobble cannot flicker it) — **takes the grip on its
own and keeps it** while the left controller stays there. While stacked the rifle **follows the right hand
alone** (no steering at all), and the drawn left hand rests on the forestock as it does for any held grip.
Leaving the zone with the grip still held re-bases the ordinary steering so it does not jump. Default ON;
`STACKED-GRIP-OFF.bat` / `-ON.bat` switch it live; `grip_stacked_show` reports. Logs every take and
release with the centimetres. `[compile-verified 2026-09-22]`, `dinput8.dll` `72c19937…` installed
(previous kept as `dinput8.previous.dll`).

Feel questions for the wearer: does the grip take without fuss, does the rifle stay straight, is the
one-controller aim steady enough. If it wants a second anchor for steadiness, averaging the two
controllers' rotations is the next lever — not built, on purpose.

⚠️ Universal: this is the same code shape REFramework uses for RE2/RE3 (`FirstPerson.cpp` carries the
identical 10 cm socket rule), so the Visceral port is the same change in a different file.

## 3. The flicker — one more concrete suspect, and the instrument that decides it

**Read from the code** `[inferred-static 2026-09-22]`: every tick where the bore is not found, the
projection does not read, or the map refuses publishes `h_ok = false`, and present then draws **that frame
with the legacy crop** — a wholly different framing for exactly one frame. That is the wearer's own
description of the flicker. The once-a-second log samples one tick in sixty, so a drop-out every ten
seconds could never show in it. `[hypothesis]` — last night's snapshot fixed the *torn* hand-off, not this.

**Built:** (a) **the last good map is held for up to half a second** over a tick that has none, flagged
`h_held`, counted once a second (`map-hold:` line); (b) **every spike line now says what the map did**
between the previous present and this one — `map: on/OFF/HELD, centre moved (du,dv), H moved x`. So one
wear separates the two families: spikes with the map jumping = our maths (and the hold should have
removed most of them); spikes with the map still = the picture content itself changed, which is upstream
of us (the mirror pass). `[compile-verified 2026-09-22]`, `re_scope_vr.dll` `87b0f32c…` installed
(previous kept as `re_scope_vr.dll.pre-draw-pose-2026-09-22`).

**The test:** `PICTURE-TEST-1-ON`, play a minute or two, count flickers as before, `PICTURE-TEST-3-OFF`.
Read: fewer flickers + `map-hold:` counts about the old spike rate = this was it. Same flickers + spike
lines with `centre moved (+0.0000,+0.0000)` = the content changes upstream, and the next instrument is a
dump of the source frame at a spike.

## NOT established

- None of the three has been worn. Each is a one-launch test; all three ride the same launch.
- Whether plan C is still wanted at all now that the plane lies along the line of sight (the 2026-09-18
  derivation assumed the head pose). With the drawn pose handed over it no longer matters for the zero.
- The stacked zone's numbers (3–35 cm, 12/18 cm) are first guesses, named constants in `RE8VR.hpp`.

## Files

Plugin: `staging/re-village-scope-vr/plugin/src/draw_pose.cpp`, `draw_pose_math.h`, `crop_follow.cpp`,
`present.cpp`, `crop_snap` struct in `rsv.h`; test `plugin/tools/draw_pose_test.cpp`. REFramework:
`dev-archive/reframework-patch/vr-cpp-all-patches.patch` (VR.cpp/.hpp, supersedes applying
`mirror-exemption-v2` + `mirror-steering` separately) and `grip-no-throw.patch` (RE8VR, now with the
stacked grip). Helpers: `mod/helpers/STACKED-GRIP-*.bat`, `CROSSHAIR-FROM-*.bat`.
