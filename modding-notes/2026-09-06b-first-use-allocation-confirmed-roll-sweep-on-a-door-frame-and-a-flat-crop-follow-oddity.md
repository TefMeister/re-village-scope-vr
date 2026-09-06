# 2026-09-06b — first-use allocation confirmed, the roll sweep on a door frame, and a crop-follow oddity visible flat (hands-on, home PC, ONE FLAT LAUNCH, Tefa aiming)

**Lane:** hands-on modding session, home PC, 14:50–15:25. Tefa launched flat (headset charging),
reached the village outdoor spot and aimed; Claude drove the harness from
`dev-archive/tools/re8drive.py` and released the forced aim after every capture (Tefa's standing
request from this session: hold `ads 1` only for a capture, never leave it on). Evidence:
`dev-archive/recon/2026-09-06-sharpness-and-stranded-latch/` (captures, roll-sweep montage,
filtered log). New tools: `dev-archive/tools/scope_metrics.py` (edge energy + edge orientation
inside the glass circle), `dev-archive/tools/roll_sweep.py` (13-step pitch/yaw sweep with a
capture per step, aim released in a `finally`). The session ended early: usage quota.

## 1. The cold-order recipe works, and a width allocates once per process `[verified-live 2026-09-06, n=1]`

- `.` → `fn p10` (1920 first) → `REPLACED` (1920×1088 fmt=29) → `UPGRADED` (fmt=26). Live world.
- `.` → `fn destroy_rig` → `fn rtex_1280` → `fn p10` → `REPLACED` (1280×728) → `UPGRADED`. Live world.
- `.` → destroy → `fn rtex_1920` → `fn p10` → **no allocation**. The stranded-latch detector
  (built last night, never run) fired on its own: `STRANDED LATCH: rig rebuild #3 rigged a
  1920-wide target but the latch still holds the 1280-wide source`, tab amber, recipe printed.
  The glass showed the old buffer's frozen frame (capture mean 57, the jacket value).
- Recovery: destroy → `fn rtex_1280` → `fn p10` → watcher: "same width, latch did not change";
  Tefa: *"moving, the scope moves with me"* — live, the pooled buffer, as the 05l note predicted.

So the 05l `[hypothesis]` — an allocation per width happens on FIRST use in a process and never
again — is now `[verified-live 2026-09-06, n=1]`, and the detector is proven live once.

**Watcher quirk to fix `[PD]`:** on the two GOOD rigs the watcher printed "rig rebuild #N at the
latched width and the latch did not change" AFTER the `REPLACED`/`UPGRADED` lines. The allocation
lands inside `fn p10` before the producer publishes the rebuild counter, so the watch starts after
the latch already moved and reads "unchanged". Harmless (it says live = pooled buffer), but the
verdict is wrong on a successful rig. Fix: compare against the latch generation sampled at the
producer's *previous* publish, or accept a latch change within ~1 s BEFORE the counter bump.

## 2. Sharpness 1920 vs 1280 — STILL not made, now n=4 launches, and this time it was the pose

Both halves allocated and were live (§1), which is what the last three launches lacked. But the
aim moved between them (statue → sky → fountain rim), so the captures show different scenes and
the edge-energy numbers are not evidence; they are not quoted. **The recipe is now known-good;
the missing ingredient is one held pose for ~40 s.** Next launch: Tefa aims at the statue and
holds; Claude takes 1920 then 1280 within a minute, releases aim, runs `scope_metrics.py`.

## 3. Roll sweep on a straight edge (the door frame / roofline with a torch bowl) `[verified-live 2026-09-06, n=1 scene, 5 steps each way]`

13 captures, montage in the recon folder. **Yaw 90→115: nothing changes** (edge orientation
89–90° at coherence 0.4–0.7 with the reticle masked, identical pictures). **Pitch 180→205: the
picture rolls clockwise AND pans/zooms** — the roof edge tilts step by step and the torch bowl
grows across the glass. A sky-to-roof line fit gives roll ≈ +2°, +10°, +23°, +19°, +23° at
+5…+25° pitch (Theil–Sen; noisy from +15° on because the pan carries the edge off-centre and
perspective changes its apparent angle). By eye the roll is about **1:1 with pitch over the
first 15°**, not 2:1. `[measured 2026-09-06, n=1]` on the first three steps; beyond that the
confound wins and the number is not pinned.

## 4. ⚠️ The `[FLAT]` roll-law row cannot test `roll_k` — a reading of the code `[inferred-static 2026-09-06]`

`roll_k` multiplies `g_roll_rad` = the RIFLE's roll about its bore relative to the camera's up
(Plugin.cpp ~2380–2396, from the rifle transform + camera; baseline-subtracted). The harness
`pitch`/`yaw` rotate the **Lua pane**, not the rifle; and on a flat screen the rifle never rolls
relative to the camera. So during a flat sweep `g_roll_rad ≈ 0` and `roll_k` does nothing —
the plugin does not log the roll, so this is static reading, not a measurement. The row as
written ("pin the law flat, then set `roll_k`") conflates two rotations.

**What makes it flat-testable — `[PD]` build:** (a) a harness `roll <deg>` command rotating the
pane about the rig's local Z (the bore); (b) a `roll_sim` field in `re_scope_vr_pane.txt` that
the plugin feeds into `g_roll_rad` when present. Then one flat sweep of `roll 0…20` pins the
true law (mirror physics predicts the reflected image rolls 2× the pane's roll about the view
axis — `[hypothesis]`, and the sign depends on flip_h/flip_v), and a second sweep with
`roll_k` set shows whether the compositor nulls it. Same `k` applies in VR: the lens rolls with
the rifle there, but the required correction is still −2θ relative to the lens.

## 5. Crop-follow looks wrong in FLAT ADS — free evidence from the log `[measured 2026-09-06]`

Before any rig, with Tefa aiming (fov 51.3), every `crop-follow:` line read
`bore 39–41 deg off the gaze` and all four candidates at **u ≈ 0.003–0.03** (the LEFT EDGE),
e.g. `refl/shared -> (0.008,0.377)`; `world[]` `aim=(14,390)` of `proj=1920x1080`. In flat ADS the
camera looks down the bore, so the bore's far point must project near the centre (u ≈ 0.5) and
the angle off the gaze near 0°. Yesterday's VR log had the same 40° and the 06a note explained it
as "rifle held across the body" — **that explanation does not survive a flat repeat**: the
40° is there with the rifle on-axis. Reading `[hypothesis]`: the bore direction used by
crop-follow is the wrong local axis of the rifle transform (or the wrong sign), so the
projection lands off-image and the crop clamps to the edge. **This is testable and fixable with
no VR** — a `[PD]` derivation against the flat log, then one flat launch to see the crop centre
read ~0.5 in ADS. Note the 09-05c measurement "the plugin's own aim px is the view centre in
flat ADS" was on a different code path (pre crop-follow); which axis each uses should be
compared first.

## 6. Also seen

- Tefa's aim anchor read `local=(0.13,-0.13,-0.15)` at fov 51.3 — the crouched-aim values from
  the deferred row, while standing. The crouch row's anchor discriminator may be weaker than
  recorded `[n=1]`.
- The "wash over the lens" Tefa saw while lining up the door frame: not investigated (quota).
  Candidate causes: the game's lens glare, or our GT grading on a bright sky source. Ask first.

**GATE: PD** — three static rows are now open (harness `roll` + `roll_sim`; the crop-follow
bore axis; the watcher ordering). The game was left running at Tefa's end.
