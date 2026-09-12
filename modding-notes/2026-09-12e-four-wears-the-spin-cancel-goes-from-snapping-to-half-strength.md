# Four wears in one evening: the spin cancel goes from "spins and snaps" to "half strength, no snaps, one steady tilt left" (2026-09-12 evening, home PC `RTX`, `/lm`, Tefa wearing)

Tefa launched (three times, all in VR) and wore; Claude drove everything else from the two
command files and rebuilt the plugin twice between wears. Evidence and both roll traces:
`dev-archive/recon/2026-09-12-mroll-first-wear-and-the-spin-trace/`.

The picture at the end of the day: **placement fixed this afternoon; the gun steers the picture;
the spin is half-cancelled, no longer snaps, and what remains is a constant tilt plus a warp.**
Tefa, on the v2 build: *"honest feel of it is like aiming down a scope now. just needs to be
right, but it feels good."*

---

## 1. v1 (built this afternoon, never worn until now) — spins AND snaps

`mrollk 1`: *"the picture inside the scope rotates and sometimes snaps to another angle."*
`mrollk 0`: *"better, no snapping"* — still rotating. `[verified-live 2026-09-12, n=1 wearer]`

⇒ **The snapping was entirely the new term.** A ten-second trace with cropfollow briefly on showed
the computed roll sitting near **−134°** while still and jumping 26° in one second when the pane
moved (`mroll-trace.txt`). v1 measured the reflected up against **world up, about the reflected
forward** — and with the head 40° off the bore the reflected forward points steeply down, so that
reference is ill-conditioned. Wrong axis, wrong reference.

**The crosshair test settled where the roll lives.** Our crosshair is drawn upright in the render
target, so: *"the crosshair just sits there without moving at all"* while the picture behind it
turns `[verified-live 2026-09-12, n=1 wearer]` ⇒ the roll is in the **mirror image** — the right
thing to cancel, measured wrongly. (A headset frame from this wear shows the crosshair tilted
~35° *with* the scenery; that is the rifle rolled in the hands, which a real scope also does.)

Also seen: the **goat rig prop visibly turning on the side of the rifle** as the pane steers —
cosmetic, hide the mesh. And **the goat is visible through the lens when the rifle is turned far
right** — the reflected view does drift off the bore at extreme angles.

## 2. v2 — bore axis, rifle up, baked-pane baseline

`mirror_roll_math.h` v2: signed angle **about the bore**, from the **rifle's up**, as the **excess
over the baked pane** computed at the same instant (zero by construction when steered = baked, no
state to go stale). Test: 98/98 `[verified-numerically 2026-09-12]`, including the case v1 got
wrong — pitching the pane toward the eye produces no roll — and the whole rifle rolled 35° giving
0. The first run swept pitch to ±60° and read −180° there: correct geometry (past 45° the
reflection points behind the rifle), not a roll to cancel; the sweep is bounded at ±40°.

Worn (`mrollk 1`): *"still snapping and spinning but less, sometimes even not rotating at all with
my head just turning left and right."* Then **`mrollk -1`: "we are headed in the right direction…
moving the weapon or my head starts rotating the picture, but then it snaps back to being the
right way around, like refusing to rotate upside down."** `[verified-live 2026-09-12, n=1 wearer]`

⇒ **−1 is the sign** (it restores upright), and "rotates, then snaps back" is **lag**: the plugin
was reading the steered normal from the Lua's pane file (~2 Hz publish, ~4 Hz read), so the
cancel caught up in visible steps. The maths was steady (±1° while still).

Also reported on this wear, for the content line, verbatim: *"moving my head is inverted left and
right in game, moving my head up and down causes the picture inside the scope to snap to where
it is pointing"* — the mirror's aim itself updates in steps, and yaw is mirrored. Separate row.

## 3. v3 — the steered normal computed every frame in the plugin

`mrollsrc 1`: the plugin recomputes the Lua "eye" model's normal each tick —
`v = normalize(anchor − eye)`, `d = bore`, `n = normalize(v − d)` — with the plugin's own joint
as the anchor and the **verified muzzle axis** as the bore (also now the roll axis, instead of the
root's +Z). Test extended to 176/176: for eyes all round the rifle the normal reflects the eye
ray onto the bore, and the roll is even in the sign of `n` `[verified-numerically 2026-09-12]`.

Worn: the value reads **−7° to −37°** as the head moves (was −140°). `mrollk -1`: *"rotating again,
not as bad as it was at first, but still like rotating and stretching and warping the picture
while it is rotating"* — **no snapping** any more. `mrollk -0.5`: *"less I think, the picture is at
a wrong angle more persistently."* `[verified-live 2026-09-12, n=1 wearer]`

⇒ Two separate residuals:
- a **moving part**, over-corrected at −1 and under at −0.5 — the right strength is in between,
  or the computed magnitude is off by a factor (the normal the plugin recomputes may not be the
  one the Lua actually applies: anchor vs joint, and the Lua's `flip_d`);
- a **constant tilt** the term cannot see, because "excess over the baked pane" is zero by
  construction whatever the baked picture's own tilt is. Needs its own offset knob.
- the **warp/stretch** while rotating is the mirror itself: a planar mirror tilted obliquely
  reprojects the scene, and rotating a rectangular crop of a 16:9 render does not undo that.
  Not a roll problem.

**Shipped default: `mrollk -0.5`, `mrollsrc 1`, `mrollmode 1`.** Deployed and stamped.

## 4. Built and NOT run

Nothing this time — everything built tonight was worn. The v3 DLL with the −0.5 default is the
one installed (md5 `8cb612d6…`), backups beside it for v2 and v3-at-−1.

## 5. What is NOT established

- The right **strength** (between −0.5 and −1, or a magnitude error in the recomputed normal).
- The source of the **constant tilt** — the baked picture's own roll (the afternoon's "tilts in
  the headset" with the baked pane), or the rifle-roll term (`roll_k`, still 0), or a fixed offset
  between the compositor's frame and the glass. One static knob decides it.
- Whether `mrollmode 0` (real camera up) changes anything — never tried.
- Why the mirror's **aim** steps and mirrors yaw (content line).

## 6. Automation

Self-launch: Tefa launched all three VR runs by choice (`/lm i launch` shape); the 18:49 launch
was Claude's, unattended, and reached gameplay on the recorded route with the log as the oracle.
Menu→gameplay ✅ (log-verified, twice). Commands ✅ (two files). Character+camera: not needed.
Self-close ✅ (WM_CLOSE route, three times). No reader started — the game had no `[PD]` rows and
the user was watching usage; said so rather than starting one for form's sake.
