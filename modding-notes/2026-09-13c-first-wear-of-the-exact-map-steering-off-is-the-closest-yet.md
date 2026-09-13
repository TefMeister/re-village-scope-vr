# 2026-09-13c — First wear of the exact map: with steering OFF it is "the closest to what it should be like" (`/ms`, home PC `RTX`, 13:55–14:30, Tefa wearing)

Tefa launched and wore; Claude sent commands through the harness file and read the log. Evidence (six headset
stills): `dev-archive/recon/2026-09-13-exact-map-first-wear/`. Dossier §9x.

## What happened, in order

1. **`bringup` ran cleanly, first use** (13:56:15 → 13:56:36): rig, drive, sliders, armour (2 of 3 parts
   found on the root: `via.physics.Colliders`, `app.HitController`; no `app.ProcDamage`), shrink + silence
   (`Gain 1.0 → 0` read back), mirror latched, glass bound three times, `DONE`. No stock crosshair, no tick
   reported. `[verified-live 2026-09-13, n=1]`
2. **With `steer 1` (model 0) and the exact map on: no better than yesterday.** Tefa: *"still rotating and all
   sorts of angles"*, *"the picture inside it is nonsense, rotating and it is not the picture that i'm aiming
   at."* Log while aiming: the map's centre sat at v ≈ 1.33 (off the bottom of the render); the Lua's steer
   line showed the eye→lens ray 65–90° from the bore. `[verified-live, n=1 wearer]`
3. **The duplex reticle's thick bars: left/right longer than up/down** (still `-20260913-140735.jpg`). That is
   the prediction for a glass that shows the RT's UV square as ~1:1 while the shader assumes 4:3. Set
   `glassaspect 1.0`. `[verified-live, n=1]` — not yet re-judged by eye after the change.
4. **The goat floats full-size in the world and does not ride the rifle** (`-135718.jpg`, `-142908.jpg`), in
   both rigs this launch — the `bringup` one (with armour) AND the 14:09 rebuild (without armour). So armour
   is **not** the cause `[verified-live, n=2 rigs]`. The rig ROOT does ride (`hb rig … rifle …` ~1.2 m apart,
   as last night); the visible goat does not. Last night the goat floated only when the pendulum was disabled;
   tonight it was not. Tefa's description of the working order: *"1. goat appears 2. goat teleports to my
   weapon 3. the scope picture comes on"*. Tonight drive and shrink happen in the same frame as the spawn;
   last night drive was 4 s after and the shrink 20 s after. **Leading suspect: the shrink (or drive) landing
   before the pendulum has picked up its child** `[hypothesis]`.
5. **14:09 rebuild: `fn destroy_rig` → `p10` → `drive_on`, `model 0`, `steer 0`, `glassaspect 1.0`,
   `goat_vanish`, `bind` ×2.** Tefa, verbatim: *"it was upside down, but for the first time this is the closest
   to what it should be like. the picture barely moves with the rifle still and me moving my head and the
   picture moves naturally when aiming with a weapon. aiming left - right is inverted, up and down is normal
   … this is 100% the right direction"* `[verified-live 2026-09-13, n=1 wearer]`.

## What the stills and the log say about the 14:10 state

- **The picture is rotated ~180°, not only flipped.** `-142808.jpg`: the house in the scope has its roof at the
  bottom AND the lantern on the other side of the door. The log agrees in its own terms: `exact-roll` read
  **174–180°** the whole time the rifle was held level (the rotation the sampler would need, measured against
  the flat baseline), stretch ~1.3, skew ~0. So the map is internally consistent and **180° off reality** —
  one sign convention in H (either the v direction of the render or `hmirror`) is wrong. `[inferred, n=1]`
- **The map's centre sat at u ≈ 1.00–1.03** (the right-hand edge of the render) while aiming straight ahead.
  Half of every sample was therefore off the edge of the render — **that is the "glitchy trail that follows my
  head"** (`-142734.jpg` indoors, the smeared lower half): the sampler clamps and smears the edge pixels.
  Consistent with the same wrong sign: mirror u and the centre lands near 0 or 1 depending on the other term.
  `[hypothesis]`
- **"Head movement no longer moves the world in the picture"** — the behaviour the whole project wanted, and
  it arrived the moment the mirror stopped being steered. The steered plane was the source of the spin.
  `[verified-live, n=1]`

## Changed during the session

- `bringup` now boots `steer 0` + `glassaspect 1.0` (was `steer 1`). Deployed + stamped; staging.

## Next, cheapest first

- **[VR] two one-word A/Bs, no rebuild:** `geomhm 1` (flips left/right — should fix the inverted aim and maybe
  the centre), then if still upside down a vertical flip (needs a `geomvflip` knob — not built yet, a `/pd`
  five-minute job), judged on the house or a fence.
- **[PD] the goat:** stagger `bringup` (drive after ~2 s, shrink after ~5 s), matching the order that rode last
  night; and `fn goat_pend_dump` on a floating goat to see where the child is.
- **[PD, Fable] Tefa's suggestion:** go back through the old attempts on GitHub knowing what is known now — the
  project moved every time that was done.

## 14:41 — the `geomhm 1` A/B: WORSE, reverted

Tefa: *"still the same as before, only worse as now head turns picture left and right again"*
`[verified-live 2026-09-13, n=1 wearer]`. Log: the map centre jumped from u ≈ 1.02 to u ≈ −0.02 — the other edge
— and `exact-roll` stayed 176–178°. Reverted to `geomhm -1` at once.

**What that settles:** the render IS mirrored in u (`hm = -1` is right; §9w's inference survives its first
test). So the 180° and the edge centre are **not** the left/right sign. With the rifle held level and aimed
ahead, the reflected bore lands at the eye's horizontal edge (|ndc x| ≈ 1.05) under both signs — the eye
geometry fed to H disagrees with the eye the render was drawn from by roughly half a view width. Candidates,
all `[hypothesis]`: the render is one eye of a stereo pair or a wider/offset per-eye projection (the VR eye
projection is asymmetric and the map assumes symmetric); the camera transform read is not the one the mirror
used; or the v direction of the render is the other way (which would give the 180° with a correct u).
Next is desk work: a `geomvflip` knob plus reading the camera's real projection matrix into the map.

## 15:20–15:45 — second wear, on the evening /pd build (Tefa wearing; stills `-152353` … `-154151`)

- **`geomdbg` answered the mirror question:** the rifle root's +X points to the player's LEFT (bore = +Z,
  up = +Y), and accessor axes equal quaternion axes. `sg_rifle_frame` aligned the map's "right" with +X, so
  the map was mirrored (`IMPROPER`). `geomflip 1` → proper, roll ≈ 0, stretch ≈ 1.05 `[verified-live
  2026-09-13, log]`. Code fix for later: rx = d × ry, drop the alignment to +X.
- **Wearer, `flip 1`:** still upside down; **the smeared trail gone**; head movement no longer moves the
  picture, only a small jitter `[verified-live, n=1 wearer]`.
- **The projection matrix alternates eyes every tick** (m20 = ±0.1736): the primary camera is one eye per
  frame, so H is computed for whichever eye that tick is. Likely source of the jitter `[hypothesis]`.
- **Goat, reversed order** (armour + shrink + silence at the spawn, `drive_on` 5 s later — Tefa's idea): all
  three armour parts off (`ProcDamage` found this time), but the goat **still floats**, right way up.
  With `bringup`'s staggered order it rode briefly, then came off and floated upside down, at the world's
  upside-down angle. So the goat leaves the rifle whatever the order `[verified-live, n=3 rigs tonight]`.
- **`geomrot 180` (with flip 1):** Tefa: *"right way up"* — **but aiming inverted left-right AND up-down**,
  the glass shows sky where ground should be (`-153532`: house upside down at the top, sky at the bottom),
  and pointing the rifle far down still gives the trail at the top of the glass. A frame rotation cannot fix
  orientation without inverting aim — they are the same rotation. So the remaining fault is not a frame
  convention: the render's vertical relation to the world is wrong — most likely the baked pane (pitch 180 /
  yaw 90) is reflecting across the wrong plane for this map, or the render's v runs the other way. Desk
  work: derive what the baked pane's normal actually is from the `geomdbg` `n` (read (0.00, −0.99, −0.13) =
  the rifle's −Y, horizontal) and test the map with v reversed at the render, not at the frame.
- **Left in the game:** `geomflip 1`, `geomrot 180`. Next session starts from `bringup` anyway.

## 16:38–16:55 — third wear: THE PICTURE IS A FIXED CAMERA LOOKING BACK AT ETHAN (Tefa wearing)

Build: the late `/pd` (`geomvflip`), `bringup` with `geomflip 1`, then `geomvflip 1`, then `fn goat_pend_off`.

- Tefa, verbatim: *"the picture is 100% coming from a goat that is not riding the weapon. i just saw Ethan walk
  in the scope in real time, move as i moved, like a footage in a stationary security camera."* Stills
  `third-wear-arm-in-scope-a/b.jpg`: the glass shows **Ethan's own arm, hand and rifle barrel seen from
  outside, close range** `[verified-live 2026-09-13, n=1 wearer, 2 stills]`.
- After `goat_pend_off` (read back false): *"picture is exactly the same … it does change based on where the gun
  is pointed … but this camera picture also depends on where Ethan is, and when i'm away from the goat, then the
  picture becomes a mess of things disappearing from the world"* (`-165015.jpg`); *"looking up and down now
  moves the picture inside the scope, but looking left and right doesn't."* Goat still floating.
- **What this reframes.** Every orientation fix today (flip, half-turn, v-flip) was tuning the view of a mirror
  that shows the PLAYER, not the scene ahead. Two separable facts, both `[hypothesis]` until measured:
  (1) the reflection's viewpoint/plane is such that it looks back at Ethan — a plane below and beside the
  rifle, reflecting the eye, sees the arm and rifle, not the world down the bore; (2) something the mirror
  draws is still anchored at the spawn (the "mess away from the goat" = the 2026-09-13 00:50 row, now seen
  directly). The log's `hb rig … rifle …` "riding" reads back our own write and is **not** proof the mirror
  moves.
- **Stopped here** on purpose: this is a design question (what the engine's mirror actually renders from, and
  whether a mirror can ever show the view down a hand-held bore in VR), not another knob. Desk work, Fable.

## 17:05 — re-read with Tefa's push ("the goat is still hanging in the air — fix that"): THE ARMOUR DETACHES THE GOAT (`/pd`, Fable, no launch)

The 15:20 wear said it plainly and I read past it: *"the goat got spawned then jumped to the weapon and the next
step after that, came off the weapon again."* In that `bringup`, the step after `drive_on` was **`goat_armour`**
(then `goat_vanish` in the same second). The 15:33 rig had armour BEFORE drive and never rode; 16:38 had armour
and floated. Last night's rig (rode, tiny, silent) had shrink and `Gain 0` but **no armour** — and the 22:26
"strip", which also switched off the colliders, was the first floating goat. So: **switching off
`via.physics.Colliders` / `app.HitController` / `app.ProcDamage` detaches the visible goat** `[verified-live
2026-09-13, n=1 direct observation + 3 consistent rigs]`, and the "pendulum off = float" reading of 2026-09-12
was the same effect seen through the strip. The security-camera picture follows: a mirror on a goat that is
not on the rifle IS a fixed camera. So today's "design question" row is premature — the mirror was never
given a chance to ride.

**Changed:** `bringup` no longer applies armour (`fn goat_armour` stays as a hand command with a warning).
**Added:** `goat-watch` — every ~5 s, and `fn goat_watch` on demand, the log prints where every
`TotemEveryware` mesh object ACTUALLY is, its scale, its distance to the rifle, and whether it is the root we
move. This is the first "riding" measurement that is not our own write read back. Deployed + stamped; the
game must be relaunched to load it. Test 26/26.

**Next wear:** relaunch, `bringup`, watch the goat; read `goat-watch:` lines (dist-to-rifle should be ~1 m and
the scale 0.001 on our root); then look through the scope while walking — the picture should finally move
with you. Only then judge `geomvflip`.

## 17:20 — Tefa: "use something that is not interactable" — the props list, scanned

`RE8_STM_Release.list`: 2,670 `.pfb` under `environment/props/prefab/`, of which 2,283 are `dynamic` (every
folder is a behaviour: break 313, detailsearch 295, swing 42, push, open, keylock, puzzle, event…), 622
`item`, 67 `template`, **1 `static`**: `sm0x/sm00_189_plocc_00occ.pfb`, an occlusion blocker — the only
plain, spawnable, non-interactive thing in the list. Plain scenery is baked into the levels, not a prefab.
Added as candidate 5 (`fn pfb_occ`). Whether it spawns and whether a `via.render.Mirror` produces on it
(it is probably invisible — no render mesh) is `[hypothesis]`; the goat was chosen in August because it
*drew*, which the host no longer needs to do.

## 17:01–17:10 — fourth wear: THE GOAT RIDES AND THE PICTURE IS RIGHT (bar upside down) — "very clearly a win now"

Fresh launch (16:58, the no-armour scripts loaded; the blocker prefab not yet). Manual: `fn p10` → +4 s
`fn drive_on` → `bind` ×2 → `geomflip 1`, `steer 0`, `model 0`, `glassaspect 1.0`. **No armour, no shrink,
no mute** — the goat full-size beside the rifle, ticking. `goat-watch:` (the mesh object's own transform):
`dist-to-rifle 1.25 m, scale 1.000` throughout `[measured 2026-09-13]`.

Tefa, verbatim: *"the picture in it is upside down, but it very clearly a win now! … picture does not move
when i move my head and the weapon is still, and moves the right way up, down, left and right. and it rides
along the rifle where i walk. this is really getting good now."* Also: slider tweaks in the REFramework UI
snap back — the picture stays put on the scope. `[verified-live 2026-09-13, n=1 wearer]`

**So, settled:** the exact map + baked pane + `geomflip 1` + glass aspect 1.0 gives a head-stable,
rifle-steered, correctly-aiming picture that travels with the player. **The armour was the whole goat
problem** (`[verified-live, n=2 launches: with = floats, without = rides]`). Left: upside down — `geomvflip 1`
sent at 17:10 for the first honest judgement of it.

**The winning state, for bringup:** as today's bringup minus armour (already), and the shrink/mute are now
the only untested-in-this-state steps (both rode on 2026-09-12 with the goat; the blocker prefab may
retire them entirely).

## 17:20 — "THIS IS THE ONE!!!" — rot 180 + flip 0 on the riding goat

Sequence of looks on the riding goat (all `[verified-live 2026-09-13, n=1 wearer]`):
- `geomvflip 1`: **sideways, and head pitch moves the picture** — wrong on both counts, reverted for good
  (still `fourth-wear-vflip1-sideways.jpg`).
- `geomrot 180` + `geomflip 1`: right way up, head-stable, **left/right aim inverted**.
- `geomrot 180` + `geomflip 0`: **right way up, head-stable, aims right in all four directions, travels with
  the player.** Tefa: *"this is the one!!! … it really is the scope now, showing on the scope glass."*

So the working frame is a half-turn of my assumed glass frame with no mirror — i.e. the glass's U runs along
the rifle's −X and V along −Y relative to what `sg_rifle_frame` assumed. (The map's own "IMPROPER" flag reads
this state as improper, so the flag's baseline is what is wrong, not the picture; note for the header.)
**Locked in:** plugin defaults `geom_rot 180`, `geom_flip 0`; `bringup` sends them; the settings file carries
them. Left, in Tefa's words: a white flicker for a millisecond now and then, a slight shake (the per-eye
projection alternating, `eye moved`), and the goat itself — the invisible blocker next, or hide it.

## 17:40 — the "white flicker" is the RIFLE, for exactly one frame (Tefa filmed it)

Tefa recorded the headset and stepped the video frame by frame: world, **the rifle itself inside the scope for
one frame**, world again (six stills with the editor's frame counter, `flicker-frames/`)
`[verified-live 2026-09-13, n=1 video]`. Reading: `rig_pose_once` runs from `re.on_frame` (present time), after
the frame's scene is built, so the mirror plane is always a frame behind the rifle; a quick rifle move lets the
lagging plane see the rifle `[hypothesis]`. Built: `posehook 1` also copies the pose at
`on_pre_application_entry("BeginRendering")`, default off, logs its first copy. The shake may be the same lag
`[hypothesis]`. Also installed: the plugin with the worn frame (rot 180 / flip 0) as its built-in default.

## 17:41–18:02 — fifth launch: the SHRINK detaches the goat; the timing hook does not fix the flicker; the blocker hides the world

- **`bringup` with shrink + mute (no armour):** goat-watch said our root was 1.25 m from the rifle at scale
  0.001 — and Tefa saw the goat floating and the security-camera picture. `fn goat_unshrink`: still floating.
  A fresh rig with **no shrink, no mute, no armour** (`p10` → +4 s `drive_on` → `bind` ×2): *"yep all working
  now"* `[verified-live 2026-09-13, n=2 launches]`. **So the shrink cuts the visible goat loose, not (only) the
  armour**; the 22:26/22:38 floats of 2026-09-12 and every float today had one of the two. `bringup` no longer
  shrinks (deployed; test 25/25). ⚠️ `goat-watch` matched only the root, which rides either way — the visible
  goat is not a separate `via.render.Mesh` object it can see; the watch is not the detector it was meant to be.
- **`posehook 1`:** Tefa filmed again — the one-frame intrusions are now **Ethan's clothes** and **the fence**
  (near geometry), the picture *"not steadier, still jittery"* (`flicker-frames-posehook-on/`)
  `[verified-live, n=1]`. The pose lag is not the cause; turned off.
- **The invisible blocker (`fn pfb_occ`):** spawns (`sm00_189_Plocc_00occ`, has a mesh component), takes the
  mirror, latches, rides (`hb` 1.2 m). But **the world disappears around the player** and the blocker shows as
  a **black rectangle** (`blocker-180115/180126/180130.jpg`) — it is an occlusion blocker, so the renderer culls
  everything behind it `[verified-live 2026-09-13, n=1]`. The scope was not checked. Next try, not run: `fn
  goat_strip` on it (switch off every component except transform/mesh/mirror/camera — the occluder part
  should be among them) and `fn goat_hide`. The game was closed before the command landed.
