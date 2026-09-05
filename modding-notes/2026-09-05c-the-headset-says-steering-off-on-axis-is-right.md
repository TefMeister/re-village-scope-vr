Supersedes: the imaging-model framing in `2026-09-05b-the-axis-is-measured-not-searched-and-the-roll-is-now-a-knob.md` §2 ("n = normalize(v − d)" vs "normalize(f − d)" — the headset disproved BOTH), and the `[VR]` row of `claude-memory/status/re-village-scope-vr.md` dated 2026-09-05 12:05

# The headset says: steering OFF and on-axis is right — the shots land

`/lm re village scope`, home PC, Quest 3 via Virtual Desktop, 2026-09-05 15:16–15:50. Two launches.
Tefa in the headset, describing what the glass shows; Claude driving the cold order and the
harness from outside. Evidence: `dev-archive/recon/2026-09-05-vr-model-test/` (both headset
screenshots Tefa sent, the filtered steer/bind/harness lines, the full REFramework log of launch 2).

## 1. The one result that matters

**With steering OFF and the scope held on-axis in the centre of the view (eye behind the
eyepiece, exactly like flat ADS), the glass shows the scene ahead, the right way up, and the
shots land close to where the reticle points.** `[verified-live 2026-09-05, n=1 scene, Tefa]`

Tefa's words: *"it's pointing the right way now and right way up, and even the shots land pretty
close to where the scope is pointing!!!"*

So the flat-tuned rig pose (pitch 180 / yaw 90, the 2026-08-30 pane offsets) and the 2026-09-04
zeroing **carry into VR unchanged** for the on-axis geometry. Nothing about the plane needs
re-deriving for that case. Everything that was wrong in the headset today came from what we ADDED
on top of it, or from the eye leaving the axis.

## 2. What was disproved, in order

| step | steer | model | eye | what the glass showed |
| --- | --- | --- | --- | --- |
| 1 | ON | eye→mirror (deployed this morning) | wherever the head was | picture follows the head; Ethan's jacket; the visible hole shrinks and slides (`headset-152349.jpg`) |
| 2 | OFF | — | off-axis | same: follows the head, jacket visible "most of the time" (`headset-153045.jpg`) |
| 3 | ON | camera FORWARD (built + deployed this session as `model 1`) | off-axis | jacket still there, and now the rig visibly turns with the head — "rotating in weird and wrong ways" |
| 4 | ON | eye→mirror | **on-axis, centred** | jacket and obstructions GONE, but upside down and pointing somewhere else |
| 5 | **OFF** | — | **on-axis, centred** | **right way, right way up, shots land** |
| 6 | OFF | — | leaning sideways off-axis, rifle still | the picture content shifts left/right with the eye |

All `[verified-live 2026-09-05, n=1, Tefa's report]`.

Readings:

- **Both imaging models are disproved** `[disproved 2026-09-05, n=1 each]`. Not "wrong sign" or
  "wrong axis": step 4 vs step 5 is the same eye, the same rifle, the same pose, and the only
  difference is the steering being applied. On-axis, `n = normalize(v − d)` has v ≈ d, so n is a
  small-difference vector roughly PERPENDICULAR to the bore — it swings a working plane by a large
  angle exactly where no correction is needed. The forward model does the same thing with f. The
  mistake was upstream of both: they derive the plane from scratch every frame, when the baked
  pose is already the right answer for the on-axis case and only a DEVIATION from it needs
  handling.
- **The picture IS eye-dependent** (step 6, and step 2's jacket), so some steering is still
  needed. It must be a correction that is the identity on-axis and grows with the eye's angular
  offset from the bore. `[inferred-static 2026-09-05]` — see §4.
- **Off-axis, the jacket has a second cause the plane cannot fix: the crop.** The compositor
  cuts the picture from a FIXED spot of the mirror render (`mir_cx`/`mir_cy` = 0.5/0.6). The
  plugin's own aim pixel says where the scope actually sits in the view: in flat ADS it is
  `aim=(960,541)` — the exact centre of 1920×1080 — in 15 of the flat-sweep samples
  `[measured 2026-09-05, launch2-cold-order-sweep.txt]`; in the headset it ranged from
  `(302,1188)` to `(1400,1007)` while Tefa moved `[measured 2026-09-05, launch2 log]`. The crop
  never followed it. Step 4 (bring the scope to the centre → the jacket clears) is the direct
  test of this: when the scope is at the crop point, the crop is right.

## 3. The material's eye-box (separate, not ours)

`headset-152349.jpg`: a small bright oval inside a grey disc, and Tefa: *"if I move the rifle
forward the image moves deeper into the scope … leaning also produces that effect of going deeper
into the pipe"*. In `headset-153045.jpg` the same glass, viewed from a different angle, is full,
with the reticle drawn large and off-centre.

Reading `[hypothesis]`: the game's lens material simulates a real scope's exit pupil — the visible
disc shrinks and slides as the eye leaves the axis, and the slot-1 texture (where our picture goes)
is shifted and scaled with the view angle. In flat ADS the eye is always on-axis, so this never
showed. The plugin already tries to zero the material's parallax terms and one of them refuses
every write: `EyeDistortionRange -> 0.000 reads back 0.100 <-- STILL FAILS UNDER EVERY ENCODING`
(both lens materials, both launches). Whether the effect was already present on 2026-09-04 before
any steering existed was asked and not answered — so it stays a hypothesis, though nothing in our
code draws a hole that changes size.

## 4. What to build (all `[PD]`, none needs the headset)

1. **Steering as a correction from the baked pose, identity on-axis.** In the rifle frame the
   on-axis eye ray is the bore. Per frame: `arc = shortest_arc(d, v)` (bore → eye→mirror ray),
   apply `slerp(identity, arc, k)` on top of the baked rotation, with **k = ±0.5** because a mirror
   turns the reflected view by twice the plane's rotation. Sign unknown — it is a knob
   (`steer_k`), and the flat pitch sweep's "view shift per degree of pitch" is the data that can
   pin it before a launch (the sweep rotated the plane by known angles; the law predicts the view
   swings 2×). Ship as `model 2`; `model 0/1` stay in the file as the disproved pair with this
   note as the reason.
2. **Crop follows the aim pixel.** `crop_follow=1` settings key (default 0): crop centre =
   the aim pixel normalised by the space it is projected in, plus the existing `mir_cy` clip-plane
   offset as a delta from 0.5 rather than an absolute. ⚠️ Open question first: aim values above
   1080 in the headset (`(302,1188)`) mean the projection space is not the desktop 1920×1080, and
   the mirror RT (1920×1088 here) renders with a projection we have not identified in VR. Log the
   aim pixel next to the RT size on every `mirror RT: using` line so one launch answers it.
3. **The eye-box.** Find who writes `EyeDistortionRange` each frame (the scope's own controller
   is the obvious suspect — the game animates the eye-box during ADS) and hook or override it; or
   move our picture to a slot the parallax does not touch. Static work: Ghidra/REFramework type
   dump of the lens material's owner.

## 5. Also settled this session (the two "read one log line" rows)

- **Bind-guard identity probe:** wrapper type `via.render.TextureResourceHolder`; all seven
  candidate accessors (`get_Resource`, `getResource`, `get_ResourceHolder`, `get_Texture`,
  `getTexture`, `get_Handle`, `get_NativeResource`) **absent**; the guard disabled itself, as
  designed. `[verified-live 2026-09-05, n=2 launches]`. The identity must come from somewhere
  other than the wrapper — a `[PD]` question if it ever matters; the picture was steady all session.
- **Resolution lever 2:** `mirror RT: using movie/rtex/movie_1920_1080.rtex (1920x1080)` on both
  launches — no fallback — and the plugin latched the 1920×1088 raw-HDR allocation
  `[verified-live 2026-09-05, n=2]`. Whether it looks sharper than 1280 was not judged (Tefa was
  looking at geometry, not detail).

## 6. Automation, scored (§5a of `/lm`)

- **Menu → gameplay:** launch 1 reached gameplay while my Enter/F sequence was being sent, but the
  desktop captures never changed (see below) so I could not verify which press did what; launch 2
  Tefa drove the menus with the controllers by choice. **Not proven in VR** — proven flat only.
- **Commands:** PROVEN in VR — numpad by VK (`.`, `*`), the command file (`fn p10`,
  `fn drive_on`, `steer`, `model`, `ads`), all `[verified-live 2026-09-05, n=2 launches]`.
- **Character + camera:** not exercised (the headset and controllers own them in VR).
- **Self-close:** PROVEN — WM_CLOSE, window gone in 2 s, process gone within 30 s, relaunch
  through Steam clean `[verified-live 2026-09-05, n=1 in VR]`.
- **⚠️ New hazard:** in VR mode the desktop window does NOT repaint — `BitBlt` captures were
  byte-identical across a minute (`watch` deltas 0.00 ×6, three identical PNGs) while the log
  showed the game in gameplay with the rifle locked. **The log is the only state oracle in VR;
  screenshots are dead.** `[verified-live 2026-09-05, n=1 launch, ~3 min]`

## 7. Not established

- Any of the above at n>1, or at another scene.
- Whether the eye-box (§3) predates the steering builds.
- The sign of the half-angle correction (§4.1).
- What projection the mirror RT uses in VR (§4.2).
