# 2026-09-22 (f) — plan C off holds the picture; the two-shot zero is built (home PC, Fable, Tefa in the headset)

## Plan C off, worn `[verified-live 2026-09-22]`

`PLAN-C-OFF.bat` (the mirror drawn from the headset pose, `VR_MirrorUsesOriginalCamera=false`): Tefa:
*"it's good now, does not move like it did before, but does still move a little - that is a problem for
another day."* Before it (plan C on) head pitch moved the picture *a lot*; the log showed the game's own
camera sitting level with the head for stretches and then 45–53° below it. So the 2026-09-12 experiment
that never helped the swing is now OFF for good, and the drawn pose (kind 2) equals the joint pose.
The small residual head-movement is a parked row.

## Tefa's two asks

1. **The zero** — *"come up with something that with the settings as they are at the moment, the shots
   always land where the scope is showing."*
2. **The prop** — skip the prop-arm creation and the wait; put the good picture on the rifle the moment
   it is drawn, with no Ethan's-clothes phase. Filed as a `[PD]` row (Lua harness work).

## Built: the two-shot zero (`zero_shots.cpp`, `zero_shots_math.h`, `ZERO-BY-TWO-SHOTS.bat`)

A real-scope zeroing, measured in the game with no model of the picture in it:

1. `ZERO-BY-TWO-SHOTS.bat` arms it. Shot 1 at a wall (10–15 m): the bullet leaves along `bore1` (the
   clean ray, exact — dossier 9cc).
2. Without moving the feet, put the crosshair ON THE HOLE and fire: `bore2`. Whatever the picture does,
   the crosshair *showed* `bore1` at that moment.
3. The crosshair shows `bore ⊕ zero ⊕ e` (e = the picture's unknown error). From shot 2:
   `bore2 ⊕ z0 ⊕ e = bore1`, and we want `bore ⊕ z1 ⊕ e = bore`, so
   **`z1 = z0 + (bore2 − bore1)` as seen in the VIEW frame** — the same axes and sign the zero is applied
   in (`crop_follow.cpp`, zero frame VIEW, `sg_zero_bore`; tangent-space components add linearly).
   Check: an exact picture makes the wearer tilt by exactly −z0 and z1 comes out 0; a cross 5° above the
   true bore makes them tilt down 5° and z1_up = −5.
4. The new zero goes through the harness (`zeroup` / `zeroright` appended to `re_scope_cmd.txt`, the
   route every helper uses), is captured as the boot value and saved, so it loads by itself next launch.
5. Shot 3 should land on the cross. A second pair refines (additive).

Guards: pair > 25° apart = the second shot was not on the hole (refused, becomes a new first shot);
walked > 0.5 m between shots = refused; first shot older than 60 s = forgotten; no view frame = refused.
`tools/zero_shots_test.cpp` 7 cases, all pass `[verified-numerically 2026-09-22]`. Plugin built 0/0,
installed, archived.

## Not established

- Whether one pair lands the third shot on the cross (next wear). Distance dependence: do the pair at
  the distance that matters most; `aim-dist` still handles parallax vs distance on top.
