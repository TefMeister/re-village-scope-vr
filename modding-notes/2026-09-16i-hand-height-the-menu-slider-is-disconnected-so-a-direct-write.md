# 2026-09-16i — hand height: the VR menu's hand-offset slider most likely does nothing, so the harness writes the offset directly (`/pd`, dev PC, Opus, NO LAUNCH)

**The game was not launched and nothing here has been run.**

## 1. The row

*Offset one hand slightly higher in real life than shown in game*, so one hand stops covering the
other motion controller; the hidden controller loses tracking and "the left hand drifts at silly
angles" `[reported 2026-09-14]`.

## 2. What the files say `[inferred-static 2026-09-16]`

- REFramework's VR module reads the hand offsets from a table called `re8vr`: the strings
  `left_hand_position_offset` and `right_hand_position_offset` are inside the installed `dinput8.dll`,
  and no Lua file defines that table, so it comes from the DLL.
- praydog's `re8_vr.lua` sets both offsets **once**, at load (OpenXR values: left −0.037 / 0.070 /
  0.018, right +0.037 / 0.070 / 0.018).
- Its REFramework menu has "Left/Right Hand Position Offset" sliders, but they write a **local copy**
  in the script and nothing copies that back into `re8vr`. The only code that writes `re8vr`'s offsets
  afterwards is a debug stick-adjust mode. So dragging those sliders most likely changes nothing in the
  headset. Not checked live.

## 3. What was built (Lua compiles, stubbed tests pass, deployed on the dev PC, NOT run)

- **`handhigher L|R <m>`** (harness). Hold that controller `<m>` metres higher in real life than its
  hand is drawn. It writes `re8vr.<side>_hand_position_offset` with its up value lowered by `<m>`,
  reads it back and logs both. The first use remembers the original, so `handhigher L 0` restores it.
  Clamped to ±0.3 m. Refuses and says so if `re8vr` is not there.
- `scripts/tests/hand_higher_test.py` stubs `re8vr` and checks the arithmetic, the restore, that the
  other hand is untouched and the missing-table guard: 5/5 `[verified-numerically 2026-09-16]`.
- Lua compiles; stubbed bring-up 29/29. Dev-PC install re-stamped 14/14.

## 4. What is NOT established

- **That the offset's "up" is the controller's up.** If the hand moves the wrong way, use a negative
  value; if it moves sideways or forwards, the axis is different and the note says which to try.
- That a changed offset takes effect without a reload. The C++ side may copy it once.
- That the home PC's patched REFramework build exposes the same two names. It is built from the same
  line of source, so very likely `[hypothesis]`.
- Which hand should move. The report says the left hand drifts. Try left first.
- The value does not persist between launches yet. If it helps, the next `/pd` adds it to `bringup`.

**The diagnostic that would show the derivation is wrong:** the log reads the new value back, but the
drawn hand does not move at all. Then the VR module read the offset once at start-up, and the value
has to be set before it does. That means the change belongs in praydog's script's start-up lines,
which is a file we deploy but did not write.

## 5. NEXT (headset, home PC)

1. Rifle up, as when the drift happens. `handhigher L 0.05`. Did the drawn left hand move down
   relative to the controller? Raise the real controller until the hands line up again.
2. Does the drift stop? Try 0.03 to 0.08. `handhigher L 0` restores.
3. If it is the other hand that hides: `handhigher R 0.05`.
