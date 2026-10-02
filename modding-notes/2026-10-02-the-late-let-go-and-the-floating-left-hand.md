# 2026-10-02 afternoon: the late let-go

Tefa: *"the automatic dock radius seemed to be bigger, at least when letting go of the gun, i had to separate my hands
a lot more to get the left hand to come off the gun."* `[reported 2026-10-02]`

## Why (read from the script, no game)

The keep-test in `re8_vrz_begone_grip.lua` (written 00:50 for the bolt swing) kept the grip while ANY of these held:
the button, praydog's own dock, or (the hand's distance from the right hand within 18 cm of the frozen socket's length
AND within 70 deg of the frozen socket line). Two holes:

1. **Sideways did not count.** Distance from the right hand barely changes when the left hand swings around it, and the
   rifle line at the hold already sits 30-36 deg off (the steering), so a sideways pull had to pass ~70 deg.
2. **praydog's dock kept it too,** and his test is made against our already-steered rifle, so it has the same blind spot.

`[inferred-static]`: the in-game log will say which one Tefa met (the let-go line now prints both numbers).

## What changed (staging, deployed to the D: copy only)

- The grip remembers where the left hand was **at the take** (distance from the right hand and angle off the rifle
  line) and lets go when the hand moves **10 cm or 25 deg** from there, whichever comes first (`GRIP_LETGO_M`,
  `GRIP_LETGO_DEG`). praydog's dock only starts a grip now; it no longer keeps one.
- After a let-go the hand must leave the dock zone once before the auto-dock may take it again (else praydog's dock
  re-grabs a hand still close). The grip button always works.
- Live word: `grip letgo <cm> <deg>` (e.g. `grip letgo 8 20`). `grip` prints how far the hand has moved and the limits.
- Log: `grip let go: the left hand moved X cm (limit 10) and Y deg (limit 25) from where it took the grip`.
- Tests: begone grip 31/31 (cases 24-31 new), grip split, panel words 179/179, all others pass `[compile-verified 2026-10-02]`.

## The wear (D: copy, Tefa)

Two-handed hold, then pull the left hand away sideways, then straight back, then forward. Pass: it comes off after a
short pull each way, and firing / the bolt still do NOT drop the grip. Too eager or too late: `grip letgo <cm> <deg>`
live, then the chosen numbers become the defaults.

## 13:47: every weapon's left hand on the rifle's spot (Tefa's two screenshots)

Tefa, in the Steam install (v1.1.0): the left hand floats open, palm up, beside the pistol and the shotgun; *"something
we did yesterday screwed up all weapon left hand grip poses ... is it the frozen poses for the rifle that affect
everything"*. **Yes.** The grip applied the rifle's captured forestock spot (`grip capture`, 37 cm ahead of the right
hand) and its finger pose whenever "the rifle camera exists" (`st.clone_go`). That camera is made once and never
cleared, so after the rifle had been out once, every weapon's docked left hand was put in mid-air on the rifle's spot
`[inferred-static 2026-10-02, matches the screenshots and the log: pistol and shotgun docks at 13:46:46-13:47:11]`.
v1.1.0 HAS THIS FAULT; the Steam install is not the last working build for other weapons.

Fix: the spot and finger pose apply only when the weapon in hand is named `ri3042*` (the sniper rifle), read on each
weapon change and logged: `weapon in hand: <name> (the sniper rifle: ... / not the rifle: ...)`. Tests 32-35.
⚠️ Same assumption elsewhere, not changed: `re8_vrz_scope_sounds_menu.lua` silences the ready/aim clicks "while the
sniper rifle is out" by the same `clone_go` test, so other weapons may have lost those sounds too `[hypothesis]`.

## The D: copy did not start by itself

Started from `D:\RE Village test copy\re8.exe` at 13:44, Steam restarted the game from the Steam folder (log stops after
DLL loading). The RE2 copy carries `steam_appid.txt`; the Village copy now has one too (`1196590`). Not yet tried.

## 13:54-14:00: first run of the D: copy (Tefa)

- The D: copy runs from its own folder now (`steam_appid.txt`) `[verified-live 2026-10-02, n=1]`.
- Tefa: *"hands dock where they should ... the auto docking without LG held now feels like it should"* `[reported 2026-10-02]`.
  The log shows let-goes at ~10 cm and ~25 deg as designed.
- Guns not pointing up this run; Tefa: *"i don't think that is your doing, it just happens sometime"*.
- **The weapon name read `nil` every time,** so the rifle lost its captured spot too (Tefa could not see it). The reader
  now follows `re8_vr.lua`: `get_GameObject`, else the `<owner>` field, then `get_Name`; logs the object type if still nil.
- **Pistol: the left hand on it steered it** (*"i can steer it with left motion controller while left hand is visibly on
  the weapon grip"*). A grip socket under 15 cm from the right hand (pistol ~6 cm; shotgun/rifle 39-46 cm) is now a support
  hand only: drawn on the gun, no steering (`GRIP_STEER_MIN_M`). Tests 36/36. Deployed to the D: copy 14:00, not worn.

## 15:00: the rifle turns in the hand at every shot (shot recorder, 6 shots)

Tefa: only the rifle jumps, in every hold, *"tip goes right"*; pistol and shotgun stay put `[reported 2026-10-02]`.
`re8_vrz_shot_recorder.lua` (probe, D: copy only) logged the barrel line in the right hand target's frame around each
shot. Same one-handed (shots 1-3) and two-handed (4-6): flat to 0.05 deg until ~2 frames before the bullet, then 1.1-1.2
deg, ~3.2-3.5 deg at the shot, then a STEADY ~1.77 deg (1.35 sideways = the tip right, 1.14 down) still there 0.48 s
later; the hand target itself moved 0.4-0.8 deg `[measured 2026-10-02, n=6 shots]`. So: the rifle's own firing
animation turns the gun below the wrist; neither the grip nor praydog's steering causes it.

Built `re8_vrz_rifle_steady.lua` (D: copy, not worn): with the rifle in hand it takes the barrel's line in the hand as a
reference once the rifle has held still 0.5 s after a draw, and on every hand update turns the right hand target by the
difference whenever it is between 0.05 and 6 deg. One frame late by design (the barrel is read from the last drawn
frame), so the first frame of the spike may still flash; the steady 1.8 deg is taken out. Logs per shot what it took out
and what was left. Test `tests/rifle_steady_test.lua` 6/6 `[compile-verified 2026-10-02]`.

## 15:05: worn. Tefa: "rifle stays still now"

`[reported 2026-10-02]`, 6 shots one- and two-handed. The log: reference taken 2.8 s after the draw; it took out up to
3.3-5.6 deg per shot. Its "left after it" figure read 15-17 deg on every shot: that window (0.6 s) runs into the bolt
cycle, which is bigger than the 6 deg limit and left alone on purpose, so the figure measures the bolt, not a fault.
Narrow it to the frames before the bolt if it is ever needed. Next ask from Tefa: *"the scope picture is really dim,
needs a brightness boost quite a bit"* -- the knob is numpad 8 (x1.25 per press, saved at once, `exposure_gt`, now 6.875).

## Shipped

v1.1.1 (14:15): the let-go, every weapon's own left-hand spot, the pistol not steered. v1.1.2 (16:00): the still rifle at
the shot, and the scope following the game's auto-exposure (Tefa: "it's perfect now!", "this build as it is, is ready for a
proper playthrough") `[reported 2026-10-02]`.
