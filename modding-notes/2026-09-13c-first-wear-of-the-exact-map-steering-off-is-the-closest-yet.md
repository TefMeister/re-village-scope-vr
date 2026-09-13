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
