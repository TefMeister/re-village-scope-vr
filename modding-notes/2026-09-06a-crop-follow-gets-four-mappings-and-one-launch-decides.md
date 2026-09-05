# 2026-09-06a — crop_follow gets four mappings, and one launch decides which the mirror uses (`/pd`, home PC, static only)

**Lane:** `/pd re-village-scope-vr`, home PC, 01:06–01:50. **The game was not launched; nothing
here has been run.** Source `staging` `afcc0cd`. Plugin rebuilt clean (zero warnings), fxc OK on
all four shader entry points, **162,816 B**, deployed with a dated backup
(`re_scope_vr.dll.pre-cropfollow-vr-backup-2026-09-06`) and hash-verified; producer (331,052 B)
and harness (11,141 B) Lua redeployed the same way. New numeric suite
`plugin/tools/crop_follow_test.cpp`: **31 checks, 0 failed** `[verified-numerically 2026-09-06]`;
the two Lua suites still green (61 and 71). Inbox was README-only.

## 1. What the board asked for, and what was actually unknown

The first `[PD]` row said: project the scope axis into the **mirror's** render, scale by the RT,
hold the last good crop across a lock drop, log the crop centre every second. Reading the
2026-09-05n log against the code showed the row hides two questions the launch never separated:

1. **Which projection does `via.render.Mirror` render with?** If it shares the viewing camera's
   projection, NDC maps 1:1 onto the target whatever its pixel size, and in VR the 1920×1088
   target holds a 0.933-aspect eye view stored anamorphically. If it renders its own 16:9
   projection at the same vertical FOV, the horizontal field is 1.9× wider. **Flat cannot tell
   these apart** (backbuffer 1920×1080 vs target 1920×1088 agree to 0.7 %); **VR can**. Tefa's
   "squashed vertically in VR, squashed horizontally in flat" `[reported 2026-09-05, n=1]` is what
   the anamorphic reading predicts `[hypothesis]`.
2. **Direct point or reflected point?** A planar mirror shows the viewing camera's image of the
   *reflected* world, so the target's pixel is the projection of the target mirrored across the
   pane's plane. For the **baked** pane this barely matters: the pane is a horizontal mirror about
   0.2 m below the line of sight (normal = the rifle's −Y — `crop_follow_test.cpp` check 4 derives
   it from the shipped slider values through two independent routes), so reflecting a 50 m target
   moves it 0.4 m vertically, under half a degree. It matters for any other pane pose.

The 2026-09-05d code was one of the four combinations (direct point, shared projection), and the
headset run's "still the same" could not say which of the four it was testing.

## 2. Why "changed nothing" was the expected result of that run — the log's own numbers

Every `world[ok-body]` line in the 23:37 process has the bore's far point at `aim=(-30…-150, 960…1200)`
of `proj=2688x2880` and the lens anchor at `px=(2600…3850, 2600…3500)`. In angles: **the bore
pointed about 40° left of the head's gaze and 13° up, while the scope glass sat 36° right** — the
rifle was held across the body. Under the shared-projection reading the target is at NDC x ≈ −1.06,
i.e. *just outside* the eye image, so the crop clamped to the left edge and showed the edge of the
head's view; under the 16:9 reading the same target lands at u ≈ 0.22, inside. Test check 9
reproduces both numbers from the log's pose `[verified-numerically 2026-09-06]`.

So the mirror can only ever show what the (reflected) head camera sees. **Keeping the rifle inside
the head's field of view is a usage limit of this design**, and the new log prints the bore's angle
off the gaze so the next run can tell "outside the render" from "mapping wrong".

## 3. What was built

**Plugin (`plugin/src/crop_follow_math.h`, pure maths, tested):** the Lua rig pose reproduced from
the rifle root transform + slider values (position = root + Z·fwd + Y·up + X·right, rotation =
root · yaw(Y) · pitch(X), normal = local +Y), point reflection across that plane, the pinhole
projection with the plugin's conventions, NDC→UV under both projection readings, and
`cf_crop_centre()` combining them with an `inside` flag.

**Plugin (`Plugin.cpp`):**
- `crop_follow_update()` runs every world tick: builds the pane from the LIVE rifle transform (no
  lag on rifle motion), computes all four candidates, drives the glass with the one `crop_mode`
  selects (settings key, default **2 = reflected / shared projection**), **holds the last good
  centre** whenever the selected candidate cannot be computed (the old path snapped back to the
  fixed crop — the jacket), and logs once a second: the four candidates each tagged `OUT` when
  outside the render, the bore's angle off the gaze, the pane it used, and whether the Lua's own
  pane normal **agrees** (< 3°) or **DISAGREES** — the derivation-wrong diagnostic. With steering
  OFF a DISAGREES line means the reproduction is wrong; do not tune, fix.
- `aspect_mode` (settings key, default 0 = shipped): 1 makes the sampled-window aspect correction
  use the camera's projection aspect instead of the source's pixel aspect — the anamorphic reading.
  Separate key, off by default, so the crop test is one variable.
- A new steady-state file `reframework/data/re_scope_vr_pane.txt`, written by the producer (~2 Hz,
  on change) and polled by the plugin: sliders, steer state, the Lua's pane normal, the `.rtex`
  width it rigged, a rebuild counter, a census counter, and **live overrides** `crop_mode` /
  `crop_follow` / `aspect_mode` (−1 = leave the settings value). Harness commands `cropmode 0..3`,
  `cropfollow 0|1`, `aspectmode 0|1` reach the plugin within a quarter second, **no relaunch**.
- **Stranded latch (the second `[PD]` row):** on every rebuild counter change the plugin watches
  ~2 s; if the latch generation did not move and the rigged width differs from the latched width,
  it logs `STRANDED LATCH: …` with the recovery recipe and turns the indicator tab **amber** until
  the latch changes. Same width = one line saying live means pooled buffer, frozen means boot
  latch. No source is ever auto-cleared.
- **SRV census (the third `[PD]` row):** `fn sc_next` now announces itself, then binds 0.4 s later
  from `on_frame`; the plugin opens a 90-tick window in its `CreateShaderResourceView` hook and
  describes every distinct RENDER_TARGET-flagged resource that gets an SRV (max 40 lines), then
  prints totals. ⚠️ **Asymmetric verdict, stated in the close-out line itself:** a screen-shaped
  RT-flagged 2D texture appearing after the bind is evidence `mirror_env` is a live capture; an
  empty census is **not** evidence it is static — a bindless engine may create no SRV at bind time.
  The row's premise ("the engine creates an SRV when the material samples it") is `[hypothesis]`.

**Producer Lua:** `pane_publish()` (defined after `quat_rotate`, called from `rig_pose_once()` and
from `on_frame` when the rig is not driving), `st.rig_gen` bumped in `make_holder()` (the
"mirror RT: using" moment), `sc_next` wrapper with the deferred bind.

## 4. The next launch — VR, and what each reading means

Cold order unchanged (`.` before the first `fn p10` on 1920, `fn drive_on`, `*`, `ads 1`; a Lua
reload costs a relaunch for the source). `crop_follow=1` is already in the settings file;
`crop_mode` is absent so the default 2 applies. **Aim at something, keep the rifle inside the
head's view, lean and turn.** Then:

| reading | meaning |
| --- | --- |
| `crop-follow:` line shows the selected candidate `OUT` while the bore is < 35° off the gaze | the projection reading is wrong — send `cropmode 3` (16:9), compare |
| picture tracks the target as the head turns, at one mode and not the other | that mode is the mirror's projection; record it, make it the default |
| picture tracks but sits consistently above/below the target | `mir_cy=0.60` is bleeding in as the +0.1 delta the fixed crop needed; numpad 9 resets it, then judge again |
| picture tracks horizontally, vertical is right, but it is stretched 1.9× wide | send `aspectmode 1` — the anamorphic reading; the shared-projection mode and this belong together |
| `lua-pane DISAGREES` with steer OFF | the pane reproduction is wrong: check the sliders line against the file, then the pitch/yaw convention; nothing else in this note is trustworthy until it agrees |
| `HELD` for long stretches with the rifle in view | the selected candidate is behind the camera — only possible for the reflected modes with a pane pose far from baked; switch to mode 0/1 |
| picture does not track in any of the four modes, all `inside` | the mirror is not a reflection of the head camera at all and this whole line of work is on the wrong mechanism — the roll-only observation of 2026-09-05n would then be the stronger fact |

**A pane-model note the record should carry:** every observation in 2026-09-05n §2 (yaw about the
normal changes nothing; pitch about the bore rolls the picture; the picture turns with the head)
is exactly what a true planar reflection of a mirror rigid to the rifle predicts, so "dead by
mechanism" is stronger than its evidence. Model 3's zero visible change at −60° is consistent
with its rotation axis having been the pane normal for a sideways lean (its own log line says
"0 = the rotation is about the pane normal and moves nothing", and that value was not quoted).
This does not resurrect pane steering as the lever — crop-follow is cheaper and does not fight
the roll law — but it means a future "bisector plane" steering (normal along the eye's offset from
the bore line, plane through the midpoint) is not ruled out `[hypothesis]`.

## 5. What is NOT established

- Which of the four mappings the engine implements. Default 2 is a physics argument plus one
  reported observation, not a measurement.
- That the plugin's rifle transform is the same object as the Lua's `find_rifle()` result. The
  `agrees`/`DISAGREES` line is the check.
- The eye projection in VR is asymmetric; `project()` is a symmetric pinhole at the camera's
  reported FOV. Expect a constant few-percent offset, not a tracking failure. `mir_cx`/`mir_cy`
  can zero it once tracking is confirmed.
- Nothing about the SRV census beyond "it will print what it sees".

**GATE: FLAT — NOTHING FURTHER WITHOUT THE GAME RUNNING.** The three `[PD]` rows are built and
deployed, and the deferred 1144×1048 row has been moved out of `OPEN` into the log with its stated
reason (scope rule), so no `[PD]` row remains. The flat rows (roll law on a straight edge,
1920-vs-1280 sharpness, crouched aim, GT-only indoors) are the cheaper items if the day is a flat
day — but **the row that matters is `[VR]`**, and it is now one launch with the decision table
above.
