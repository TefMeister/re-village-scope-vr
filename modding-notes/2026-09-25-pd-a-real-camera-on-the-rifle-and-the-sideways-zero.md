# 2026-09-25 late — /pd (Fable, home PC): a real camera on the rifle (probe built), and the zero that drifts as the rifle turns away from the gaze

**The game was not launched and nothing here has been run.** Both jobs came out of the evening's `/ms`
(`2026-09-25-the-lights-follow-the-scope-and-the-layer-order.md`, dossier §9cp) and Tefa's two questions.

## 1. Why a camera of our own is the next move `[inferred-static 2026-09-25]`

- The mirror rig's two Scene layers use the **eyes' own camera objects** (dossier §9l: "same address").
  The engine keeps per-camera state that the last drawer overwrites: the light list (an eye takes the
  list left by the Scene layer drawn just before it — four live orders, fixed by priority) and whatever
  carries the **scope picture into both eyes** when the scope draws after them (proven by pointing the
  scope at one candle; not DLSS, fog, flare, bloom, SSR, nor the after-effects passes).
- praydog's multipass makes a **second camera object** for the right eye and it renders cleanly: its own
  Scene layer, its own lights, no bleed. Recipe (`CameraDuplicator.cpp:154-300`): fresh GameObject,
  `shouldDraw=false` and `shouldUpdate=false` set **before** any component, parented to the main camera's
  transform, components copied except the game's own camera controllers (`app.*`), which "cause the camera
  to become the main one".
- Our 2026-08-25 attempt put a `via.Camera` on the **rifle's** GameObject (draw/update on, the weapon's
  own components beside it) and the engine promoted it to primary — the player's view moved into the
  rifle, and `via.SceneView` has no `set_PrimaryCamera`. `[hypothesis]`: the update-off flag (or the
  absence of the game's controllers) is what keeps praydog's clone off the primary slot.
- `via.render.RenderOutput` beside the camera, `set_RenderTarget(holder)`, is how a view is diverted into a
  texture (2026-08-25, read off Capcom's own MainCamera, which has none because it draws to the screen).

**If it works, most of the rig retires**: no pane, no reflection, no crop-follow, no off-axis maths, no
per-camera cache to fight — and the zero below becomes "is the camera on the bore?".

## 2. What was built `[compile-verified 2026-09-25]`

`scripts/re8_scope_cam_probe.lua` (own file, nothing automatic) + three harness words; stand-in test
`tests/cam_probe_test.lua` (checks the order draw/update-off-before-camera, the wiring id 2 / clipping off /
our holder, the takeover read-out, the +2 s probe, camkill). In `deploy_scripts.py`'s list.

- `camprobe` — read-only: the primary camera, every `via.Camera` alive (type, FOV), every Scene layer with
  its camera address.
- `cammake [fov] [type]` — `ScopeCam`: GameObject (draw off, update off) parented to the **rifle's**
  transform (local identity = at the rifle root, looking down its local Z, ~13° off the muzzle — fine for a
  first look), `via.Camera` (FOV default 20), optional `set_CameraType`, `via.render.RenderOutput` id 2 →
  the rig's holder. Logs the primary before/after; 2 s later lists the Scene layers again.
- `camkill` — destroys it.

**The one launch, and what each outcome means** (`/ms`; the rig must have been built once so the parent
Output layer is reachable; then `camprobe`, `cammake 20`, wait 2 s, read):
1. `primary after … CHANGED: TAKEOVER` → the view is in the rifle; restart; try `cammake 20 6` (Preview),
   then `1` (Debug). All take over → the update-off trick is not what stops it; next is copying praydog's
   exact component set instead of a bare camera.
2. `UNCHANGED` and a new `scene layer … <== OUR CAMERA` → **the engine renders our camera.** Look at the
   glass (numpad `*`) and at the plugin's `MIRROR SOURCE` lines: picture = the mirror rig can go; no
   picture = the plugin's latch wants the mirror's buffer, so point it at the holder (plugin work, `/pd`).
3. `UNCHANGED` and no new layer → a bare Camera + RenderOutput is not enough; copy MainCamera's render
   components as the duplicator does (the +2 s probe prints the list to compare against).

## 3. The zero drifts as the rifle turns away from the gaze `[reported 2026-09-25]`

Tefa, 21:35, head still, rifle turned: *"pointing forward shoots accurately, shooting sideways and the cross
does not show where the bullets go anymore"* — centre shot on the cross, the turned shots a panel off.
`reframework/data/re_scope_shots.log` 21:34: the bullet is straightened along the scope axis on every shot
(`game ray vs scope axis 0.00 deg`), so **the bullet is right and the CROSS is drawn in the wrong place**.
The same lines show the saved zero (−12.3 up / −7.9 right, view frame) re-appearing "as seen" at −13.0/−6.7,
−11.9/−8.6, −13.9/−4.5, −12.7/−7.3 — rotated by roll and the parallax turn, as designed.

**Reading** `[hypothesis]`: the cross sits at the crop centre + zero; the crop centre is where the bore
projects in the mirror frame, through a projection the mapping assumes (§9aq/§9av: the shared, off-centre
eye projection vs the native one). A wrong horizontal/vertical scale in that mapping gives an error
∝ tan(bore-off-gaze): zero when the rifle points where the head looks, growing as it turns — exactly the
sighting. A constant zero cannot absorb it, which is why the zero has "moved" from day to day: it was
measured at different angles.

**Not established**: the sign and size of the scale error — no shot tonight carried its bore-off-gaze
angle (that number lives in the framework log's `crop-follow:` line, and the log was overwritten by the
next launch). **The measurement that decides it** (one `/ms` launch, ~10 shots, `KEEP-LOG.bat` first):
shoot at a wall from one spot at 0°, 15°, 30°, 45° off the gaze (head still), screenshot each; pair each
`shot #n` time in `re_scope_shots.log` with the `crop-follow: … bore X deg off the gaze` line nearest it
in the kept framework log; plot hit-offset (panels) against X. A straight line through zero = the scale
(fix: one number in `crop_follow_math.h`); a curve = the off-centre term. **If §1's camera works first,
this whole row goes away with the crop.**
