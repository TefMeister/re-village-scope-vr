# 2026-09-06c — The bore was never wrong, it was the hip carry; the roll lever is now flat-testable; the watcher verdict is fixed

`/pd re-village-scope-vr`, home PC, 19:02–19:35. **The game was not launched and nothing here has
been run.** Source: `staging` (this commit), plugin rebuilt and deployed with backups
`.pre-rollsim-backup-2026-09-06`, producer + harness Lua redeployed the same way. Inbox: README only.

## 1. The ⭐ `[PD]` bore row is closed — `[disproved 2026-09-06]`, from the full log, no code change

The 06b ledger (§5) read every `crop-follow:` line of the 14:51 launch as "flat ADS, bore 40° off the
gaze, candidates at u ≈ 0.003", and the row's hypothesis was a wrong local axis or sign in the bore.
The filtered recon log had the `crop-follow:` and `world[]` lines stripped, so the row asked for the
full log. `re2_framework_log.txt` (3.9 MB, the same launch, 10,800 such lines) says:

| when | fov | joint in camera space (`local=`) | `crop-follow:` centre | bore off the gaze | what it is |
| --- | --- | --- | --- | --- | --- |
| 14:51:53–54, the first three lines | 51.3 | — | (0.45–0.50, 0.45–0.51) | 0.8–6° | rifle briefly on-axis |
| 14:52:01 → 14:53:40 (~100 lines) | **51.3** | **(0.13, −0.13, −0.15)** | (0.00–0.03, 0.36–0.38) | **39–44°** | **hip carry — NOT aiming** |
| 14:53:40.67 | harness `ads 1` installed the aim hook; 0.3 s later `FOV change 51.32 -> 48.62` | | | | |
| 14:53:50 → end (300+ lines) | **48.6** | **(0.00, 0.00, −0.22)** | **(0.498–0.503, 0.512–0.515)** | **0.1–0.3°** | **real ADS** |

So the 40° readings all sit at FOV 51.3 with the muzzle joint 13 cm right, 13 cm down and only 15 cm
ahead of the camera — Ethan holding the rifle across his body. The moment the harness pulled the
trigger, the joint moved to dead ahead (0, 0, −0.22), the FOV dropped to 48.6, and **crop-follow read
the centre at (0.50, 0.51) with the bore 0.1–0.3° off the gaze for the rest of the launch**
`[verified-live 2026-09-06, n=1 launch, 300+ one-second samples]`. The bore axis is right; the
self-calibrating pick (`axis=2`, the muzzle joint's Z) is right; the 06b reading was a pose misread,
helped along by the recon log having no `world[]` lines to show the pose.

Two things this settles, one it does not:

- **FOV 51.3 is the hip-carry FOV, not an ADS FOV.** ADS here is 48.6 (the companion suppresses the
  zoom to 48.6). The crouched-aim row's "keeps FOV 51.3" and its (0.13, −0.13, −0.09) anchor now read
  as the same hip pose seen crouched; that discriminator is weaker than recorded `[n=1]`, as 06b §6
  already suspected.
- **The 05n headset run was the same pose.** Its `world[]` lines (recon `2026-09-05n-…/re2_framework_log-…-process4-cropfollow.txt`)
  show `local=(0.1,−0.1,−0.1)` at fov 81.1 on 29 of 41 LOCK samples — the hip-carry anchor, not the
  ADS one — so the "rifle held across the body" reading of 06a stands after all `[inferred-static
  2026-09-06]`. Nothing in that run says the crop-follow mapping was wrong; it says the rifle was
  not being aimed. The VR row is re-written accordingly: **aim first, confirm `local=(0.00,0.00,-0.22)`
  in the `world[]` line, then read the `crop-follow:` line.** Whether the VR aim animation puts the
  joint at exactly that offset is `[hypothesis]` — the flat value is the reference.
- Not settled: the refl candidates sit 0.012 below the direct ones (v 0.513 vs 0.501) — that is the
  0.4 m mirror parallax at the far point, as check 8 of the suite predicts, not `mir_cy`.

## 2. The roll lever is flat-testable — built, deployed, NOT RUN `[compile-verified 2026-09-06]`

06b §4 read the code: `roll_k` multiplies the rifle's measured roll about its bore relative to the
camera, a flat screen never produces one, so a flat sweep could never exercise the lever. Built now:

- **Producer:** `st.rot_roll` turns the WHOLE rig about the rifle's bore (the root's local Z, the axis
  `off_f` runs along) — the offset vector AND the orientation, as a rig welded to a rolling rifle
  moves: `rot = root * roll(Z) * yaw(Y) * pitch(X)`, position = root + az·fwd + ay'·up + ax'·right with
  ax', ay' the root axes rotated about az. `st.roll_sim` is the degrees handed to the plugin. Both go
  through `re_scope_vr_pane.txt` (`roll=`, `roll_sim=`), both default to 0 = exactly what shipped.
  Two new sliders in the panel; "zero rotation offsets" zeroes them too.
- **Harness:** `roll <deg>` sets both (the faithful simulation), `droll` steps it, `rollpane <deg>`
  turns only the rig (measure the raw mirror law with `roll_k = 0`), `rollsim <deg>` feeds only the
  plugin (see the compositor's own rotation direction with `roll_k ≠ 0`). The echo line now carries
  `roll=`/`rollsim=`.
- **Plugin:** `cf_pane_from_rig` takes the roll so the `lua-pane agrees/DISAGREES` cross-check still
  holds under a rolled rig; while `roll_sim ≠ 0` it REPLACES the measured `g_roll_rad` (the measured
  value is kept in `g_roll_meas` for the log). The once-a-second `crop-follow:` line gained a tail:
  `roll meas X sim Y k Z -> applied W deg (pane roll R)` — the roll is finally logged, which 06b noted
  it never was.
- **The sign is checked against the shipped measurer, not asserted.** `crop_follow_test.cpp` section 11
  (10 new checks, 40 total, 0 failed `[verified-numerically 2026-09-06]`): roll 0 is the identity; roll
  alone is a right-handed turn about local Z; a 20° roll turns the pane normal and the pane's offset
  from the root by 20° about the bore (matrix truth); and a rifle really rolled +20° about its bore
  **measures** +20° through `roll_signed_angle` with the camera on the bore, so `roll_sim` feeds
  +deg → +rad. `roll_math_test.cpp` still 20/20.
- **`dev-archive/tools/roll_sweep.py OUT roll|rollpane|rollsim`** runs the sweep unattended
  (`0, 5, 10, 15, 20`, back to 0, roll zeroed and the aim released in `finally`). The default (no mode)
  is still the pitch/yaw sweep.

What a launch decides, in order: (1) `rollpane` sweep with `roll_k = 0` — does the picture roll 2× the
rig's roll (mirror physics `[hypothesis]`), and which sign under `flip_h=1 flip_v=1`; (2) `rollsim`
sweep with `roll_k = 1` — which way the compositor turns the picture; (3) `roll` sweep with `roll_k`
at the coefficient that makes (2) cancel (1) — a straight door frame that stays straight is the
close. `lua-pane DISAGREES` at any roll = the plugin's rolled-pane reproduction is wrong; fix, do not
tune.

## 3. The stranded-latch watcher credits a latch that moved just before the counter `[compile-verified 2026-09-06]`

06b §1: on both GOOD rigs the watcher printed "same width, latch did not change" after `REPLACED` /
`UPGRADED`, because the allocation lands inside `fn p10` before the Lua's rebuild counter reaches the
plugin's ~0.25 s file poll. The reader now remembers the tick of the last `latch_gen` change; a rebuild
seen within 150 ticks of a latch move to the rigged width prints `the latch had already followed N
ticks before the rebuild counter was read … -- not stranded` and arms no watch. Anything else takes
the old path, so the STRANDED verdict (proven live once, 06b) is untouched. Free check on the next
launch: the two good rigs of the sharpness recipe should print the new line.

## 4. The 2560 target: AUTHORED and deployed (second half of the session, 19:23–19:35) — `[compile-verified]`, engine acceptance `[hypothesis]`

Tefa said "continue with PD", so the extraction happened after all — without unpacking anything.

- **`dev-archive/tools/ree_pak_extract.py`** pulls named files out of the paks by name hash
  (murmur3 of the UTF-16 path, lower- and upper-cased, seed −1), reading the format off Ekey's public
  REE.Unpacker source on this PC (credit: Ekey). It scanned `re_chunk_000.pak` + 13 patch paks in a
  few seconds; all six `.rtex` files of interest live in the main chunk, deflate-compressed, and every
  one is **64 bytes**. Extracted copies stayed in the scratchpad — game content, never committed.
- **The `.rtex` is a 64-byte descriptor, nothing more** `[measured 2026-09-06, n=6 files]`: `RTEX`,
  version 5, a constant 4, the DXGI format (29 = R8G8B8A8_UNORM_SRGB for all five movie targets —
  the plugin's first-source "fmt=29" rule was reading this field's consequence all along; 26 =
  R11G11B10_FLOAT for `mirror_env`), width, height, then 1/0/0/1/0/0/0, 1.0f, 1.0f, 0. The engine
  allocates the surface at load from these numbers.
- **The "padded" heights were in the file the whole time:** `movie_1920_1080` is **1920×1088**,
  `movie_1280_720` is **1280×728**, `movie_1144_1048` is 1144×**808**, `movie_650_850` is 650×858,
  `mirror_env` is 1024×1024. So the latch's height windows describe the descriptors, not runtime
  rounding, and a file's name is not a contract for its size.
- **`dev-archive/tools/rtex_author.py <w> <h> <out>`** writes the structure from scratch (no game
  bytes in the script). Authoring 1920 1088 and 1280 728 reproduces the shipped files **byte for
  byte** `[verified-numerically 2026-09-06]`, which is the whole proof that the field reading is
  right. Deployed as loose files: `<game>/natives/stm/movie/rtex/movie_2560_1440.rtex.5` (2560×**1448**)
  and `movie_3840_2160.rtex.5` (3840×**2168**), following the +8 convention so their aspect (1.768)
  matches the shipped ones (1.765) and the aspect path stays untouched.
- **Prerequisite flipped, with a backup:** `re2_fw_config.txt` had `LooseFileLoader_Enabled=false`;
  now `true` (one line changed, bytes otherwise identical; backup
  `re2_fw_config.txt.pre-looseloader-backup-2026-09-06`). Without it the loose descriptors are never
  seen. Whether REFramework's loader serves a file the pak does NOT contain (as opposed to overriding
  one it does) is part of the launch's question `[hypothesis]`.
- **Producer:** `MIRROR_RTEX` entries 3 and 4 (marked `authored`), `fn rtex_2560` / `fn rtex_3840`;
  an authored pick falls back to 1920 then 1280 when `create_resource` returns nil, and the default
  order (1920 first) is unchanged, so nothing regresses unless selected. **Plugin:**
  `looks_like_mirror_target` accepts 2560×1400–1460 and 3840×2120–2200 with the same fmt=29 /
  no-UAV first-source rule. Rebuilt clean, deployed (`.pre-rtex-author-backup-2026-09-06`), hash-verified.
- **The launch:** fresh process → reach the level → `fn rtex_2560` → `.` (re-arm BEFORE the first rig)
  → `fn p10` → `fn drive_on` → `*` → `ads 1`. Outcomes: `mirror RT: using movie/rtex/movie_2560_1440.rtex`
  + `REPLACED (2560x1448 fmt=29)` + `UPGRADED` = the engine took a home-made descriptor and the detail
  ceiling just rose; `did not resolve, trying the next candidate` = the loader did not serve the loose
  file (check `LooseFileLoader_LogLooseFiles=true` next); `using …2560…` but no `REPLACED` line = the
  resource resolved but no 2560-wide allocation arrived (the engine ignored the size or clamped it).
  Frame cost is a second full-scene render at that size; read the frame rate before judging the glass.

## 5. Not established

- Nothing above has run. The roll build is compile-verified and numerically checked; its behaviour on
  the glass is `[hypothesis]` until the sweep.
- The 150-tick window in §3 assumes rigs are rebuilt seconds apart by hand; two rebuilds inside ~1.5 s
  could credit the earlier one's latch to the later.
- Whether the VR aim pose puts the muzzle joint at the flat ADS offset (0, 0, −0.22) is unknown; the
  VR row now asks for that line to be read before any crop-follow verdict.

- Whether the engine allocates a 2560-wide surface from a descriptor it never shipped, and whether the
  loose-file loader serves a path absent from the pak, are both `[hypothesis]` until the launch above.

**GATE: FLAT — NOTHING FURTHER WITHOUT THE GAME RUNNING.** No `[PD]` rows remain. Cheapest next: the
2560 launch (one cold order, three outcomes above), then the roll sweeps and the sharpness pair; the
row that matters is the headset one, now with a pose check in front of it.
