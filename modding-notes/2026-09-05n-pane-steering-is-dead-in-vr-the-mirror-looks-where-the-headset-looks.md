# 2026-09-05n — Pane steering is dead in VR: the mirror looks where the headset looks (`/lm`, home PC, Quest 3, three VR launches)

**Lane:** `/lm village scope`, home PC, 22:51–23:41, Tefa in the headset (rest window waived by Tefa
for tonight, until 00:30). Three VR processes (22:51, 23:22, 23:37), two script reloads, one
settings change. Game left **running** at write-up, steering OFF, `crop_follow=1` in the settings
file (see §5). Evidence: `dev-archive/recon/2026-09-05n-vr-model3-pane-steering-is-dead/` (full log
of the last process, filtered log, three headset screenshots, both splice scripts); the 22:31
process is in `…/2026-09-05m-vr-model2-steering/`.

## 1. Model 3 ("ref") was built and works as designed — and it does not matter

Model 2's premise was false in VR (05m): the eye→anchor ray sat 84° off the bore while the picture
was right. Model 3 captures that ray, in the pane's frame, at the moment steering is switched on
(after Tefa says the picture is right, with a 5 s grace) and steers by the deviation from it.
Identity at capture by construction: `deviation=0.0 → applied 0.0` on every capture, three
captures, three processes `[verified-live 2026-09-05, n=3]`. Harness: `model 3`, `fn steer_ref`.

Second problem found on the first lean: the lens anchor sits practically **at** the VR eye, so a
few centimetres of head lean swung the ray by ~95° (05m had the same number and blamed the gun;
the gun was part of it, the geometry the rest). Fix: `st.anchor_reach = 0.35` — the ray is measured
to a point 35 cm along the bore (the objective end). Lean then reads 26–35° → applied 13–17° at
k=0.5 `[measured 2026-09-05, n=1 run]`. Harness: `reach <m>`.

**Result, three gains, one reference:** k=+0.5 — *"feels a little better, like I have to move my
head more for the scope to start moving around, but the picture inside the scope still moves with
my head"*; k=−0.5 — *"it really is moving with my head"*; **k=−2 (applied −60°)** — *"still looks
and feels the same, like the picture inside the scope is tied to where my HMD is pointed"*
`[verified-live 2026-09-05, n=1 each]`. A 60° pane rotation with no visible effect is not a sign
question. It is the mechanism.

## 2. The mechanism, pinned by two hand-driven rotations, steering OFF

| pane rotation | what the glass did | source |
| --- | --- | --- |
| `dpitch 20` (about the rig's local X) | **rolled** the picture to the right; content the same | Tefa's 23:14:41 screenshot |
| `dyaw 40` (about local Y, the measured mirror normal) | **nothing** ("still the same picture") | 23:34:36 screenshot |
| steering, any model, up to 60° | nothing visible | §1 |

`[verified-live 2026-09-05, n=1 each]`. Together with the flat sweep of 2026-09-05 ("yaw steps
left the picture untouched, pitch steps rolled and swept it"): **`via.render.Mirror` renders the
reflection for the VIEWING camera. The plane's orientation sets the roll of the image and nothing
about its direction; the direction is the camera's.** In flat ADS the camera is on the bore, so the
picture is on the bore and every steering test passed by accident. In VR the camera is the headset,
so the picture is tied to the head — exactly Tefa's words — and **no rotation of the pane can
change that, by construction.** Pane steering, all three models, is `[disproved 2026-09-05]` as a
VR lever. The steering code stays (it is the roll lever and the flat control), but it is not the
road.

Also seen and not new: the "jacket" is the part of the head-camera reflection the fixed crop lands
on when the scope is off the view centre.

## 3. The lever that remains: WHICH PART of the reflection the glass shows

If the mirror shows the head's view, the scope content for a given head pose is a **region** of
that render, not a rotation of it. That is `crop_follow` — built 2026-09-05d for exactly this, never
run in VR. Switched on tonight (settings file, relaunch): Tefa — *"still the same"*. The log says
why `[measured 2026-09-05, n=1 process]`:

- the aim pixel the crop follows is in **eye-projection space, `proj=2688x2880`**, while the mirror
  render is `1920x1088`; the mapping was written on a 1920×1080 flat projection;
- the aim flips to `no-lock … aim=!(0,0)` whenever the joint leaves the eye image, and reads
  negative x (`aim=(-58,1167)`, `(-125,1154)`) when the scope sits at the edge of view — so it is
  off the render half the time and mis-scaled the rest.

So crop-follow is the right idea with a flat-screen mapping. Making it VR-correct is plugin work with
the game closed: project the scope axis into the **mirror's** render (the reflected head camera),
not into the eye projection, and hold the last good crop when the lock drops. New top `[PD]` row.

## 4. Source-latch side notes from the same three processes

- After a **script reload** the rig's holder is recreated and DOES allocate; with `.` pending the
  plugin took it (`REPLACED`) and upgraded — and the glass was **black** (23:15, 1920) — the upgrade
  identified by allocation order grabbed the wrong `fmt=26` after a reload `[verified-live, n=1]`.
  A fresh process fixed it (23:22, 23:37: world in the glass on the first rig, n=2). Rule: **a Lua
  reload costs a relaunch for the source anyway.**
- The **1280 target in VR crops into the sky** (23:20 screenshot, 80 % pale): its crop sits higher
  in the mirror image than 1920's `[verified-live 2026-09-05, n=1]` — same shape as the flat
  "upper two-thirds white" reading of the 1280 rebuild. Exposure was not the cause (GT knob 0.511 →
  0.262 → back). 1920 is the VR target.
- **No boot latch** in any VR process (`latched=0` at `.`), unlike flat `[verified-live, n=3]`.

## 5. State left behind

Game running (fourth process), steering OFF, pane at the baked pose, `model=ref` in harness state.
**`crop_follow=1` is in `reframework/re_scope_vr_settings.txt`** — visibly harmless in VR tonight,
untested in flat since the switch; set it back to 0 before a flat session or leave it for the
crop-follow work. Model 3 + reach are deployed in the producer/harness Lua (backups
`*.pre-model3-backup-2026-09-05n`, `*.pre-anchor-reach-backup-2026-09-05n`) and committed to
`staging`.

**Tefa's aspect note (22:59):** in VR the scope picture is squashed vertically ("too short"), in
flat it was squashed horizontally at the well ("too tall") `[reported, n=1]` — the aspect row is not
one number for both modes.
