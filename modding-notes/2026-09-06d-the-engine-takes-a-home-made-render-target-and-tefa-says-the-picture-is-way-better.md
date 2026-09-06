# 2026-09-06d — The engine takes a home-made render target, Tefa says the picture is way better, and crop-follow still swings

`/lm re-village-scope-vr`, home PC, 23:02–23:20. **One launch, in VR** (headset on Virtual Desktop;
eye render 2688×2880, fov 81.1). Tefa put the headset on partway through and judged the picture
directly. Evidence: `dev-archive/recon/2026-09-06d-2560-authored-target-vr/`.

## 1. ⭐ A `.rtex` we wrote ourselves is allocated by the engine `[verified-live 2026-09-06, n=1]`

The cold order `fn rtex_2560` → numpad `.` → `fn p10` produced, in sequence:

```
[m6_mirror] mirror RT: using movie/rtex/movie_2560_1440.rtex (2560x1448)  <- SELECTED deliberately
[re-scope-vr] [hook] MIRROR SOURCE latched (1280-wide): 2560x1448 fmt=29 flags=0x1
[re-scope-vr] [hook] MIRROR SOURCE UPGRADED to raw-HDR allocation: 2560x1448 fmt=26
```

Three separate things each of which could have failed:

- **REFramework's LooseFileLoader serves a path the pak does not contain** — not merely an override of
  a file that exists. The 64-byte descriptor written by `dev-archive/tools/rtex_author.py` and dropped
  at `natives/stm/movie/rtex/movie_2560_1440.rtex.5` resolved through `sdk.create_resource` with no
  fallback. (`LooseFileLoader_Enabled=true` is the prerequisite; it was `false` before this evening.)
- **The engine allocated a 2560×1448 surface** from those numbers, in the shipped movie-target format
  (fmt=29, flags=0x1), i.e. it read our width and height and honoured them.
- **The HDR upgrade path followed at the new size** (fmt=26 at 2560×1448), so the pre-clip HDR route
  the scope depends on is not tied to the shipped sizes either.

**So the resolution ceiling is no longer the shipped inventory.** The 2026-09-05 conclusion "borrowing
a bigger shipped target is exhausted at 1920×1080, the next step would have to *create* a target" was
right about the situation and wrong about the difficulty: creating one is a 64-byte file.
`movie_3840_2160.rtex.5` (3840×2168) is deployed and **untested**.

## 2. ⭐ Tefa's verdict on the picture, in the headset `[verified-live 2026-09-06, n=1 observer]`

> *"it is way better the quality, if it stayed like this would be great!"*

That is the sharpness question answered by the only instrument that was ever going to answer it. Three
earlier attempts to settle 1920-vs-1280 by capture pairs failed on pose or on statistics; a bigger
jump plus a human eye settled it in one look. **The 1920-vs-1280 row is superseded** — 2560 beats both,
and the comparison it asked for no longer decides anything.

Not established: the frame cost. A second full-scene render at 2560×1448 on top of VR stereo was not
measured, and Tefa did not report the game feeling worse. Measure it before this becomes the default.

## 3. The stranded-latch watcher fix is proven live `[verified-live 2026-09-06, n=1]`

```
rig rebuild #1: the latch had already followed 4 ticks before the rebuild counter was read
(latch gen 2, source 2560 wide = the rigged width) -- not stranded
```

Exactly the case that printed the wrong verdict this afternoon (06b §1). Built 19:13, run 23:06.

## 4. ⭐ VR aiming DOES put the rifle on the gaze axis — the pose hypothesis is now measured `[verified-live 2026-09-06, n=1 launch]`

This evening's 06c §1 closed the "bore is 40° off" row as a hip-carry misread and left one thing open:
whether VR aiming lands the muzzle joint where flat ADS does. It does.

| pose | `local=` (joint in camera space) | bore off the gaze | roll vs the camera |
| --- | --- | --- | --- |
| **aiming** | **(−0.00, −0.03, −0.30)** | **3.5–5.9°** | −4 to −14° |
| ready / rifle up but not aimed | ~(0.1, −0.3, −0.4) | **~40–42°** | ~−7° |
| lowered | — | ~40° | **~165°** (near inverted) |
| flat ADS, for comparison (06c) | (0.00, 0.00, −0.22) | 0.1–0.3° | ~0 |

Two consequences, both load-bearing:

- **The pose gate is real and it is cheap.** `bore < 20°` in the `crop-follow:` line is a one-line
  check that a headset verdict is worth recording. It caught a bad judgement window tonight.
- **The rifle genuinely rolls against the head in VR** — a few degrees while aiming, far more at rest —
  where a flat screen produces none. That confirms 06b §4's static reading `[inferred-static]` by
  measurement, and it means `roll_k` has something real to act on. **The roll row is a `[VR]` row, not
  a flat one**, and the flat `roll_sim` harness built this evening is a rehearsal rig for it, not the
  test itself.

## 5. crop_follow does NOT fix the tracking `[verified-live 2026-09-06, n=1 observer, 2 of 4 mappings]`

> *"it is still acting the same, moving around the pipe of the scope, and the picture inside is moving
> where i look and tilt"*

Tested: `crop_mode` 2 (reflected target / shared eye projection, the default) and `crop_mode` 0
(direct target / shared projection), switched live through the harness with no relaunch. Modes 1 and 3
were **not** reached.

**⚠️ A caveat I wrote and then had to withdraw — the mistake is the useful part.** I logged the bore
at ~40° during the judging windows and wrote that the verdict might have been given off-pose. Tefa
corrected it: *"the rifle turns when i move the motion controllers in my hands and have the headset on
my forehead, but when i do the actual looking test i know what i see."* The 40° samples were the gaps
**between** tests, with the headset up; every verdict was given while looking through the scope. So the
observation stands at full strength, and the general rule is now written down
(`claude-memory/PREFERENCES.md`, and the standing memory): **a report from Tefa about what the game
looked like is the primary evidence. My telemetry explains it; it never overrules it.** The pose gate
below is still worth having — it is how an *unattended* run knows a frame is worth judging — but it is
not a licence to discount a person who was watching.

If modes 1 and 3 also swing, the board's own decision table calls it:
"tracks in NONE of the four with all `inside` = the mirror is not a reflection of the head camera and
this line of work is on the wrong mechanism." That would be a large, useful negative — it would retire
crop-follow as the lever and send the work back to the bisector-plane steering idea left open in
dossier §9g. **Do not draw it from tonight's two.**

## 6. Two log defects found by using them `[measured 2026-09-06]`

- **The latch line mislabels the width:** `MIRROR SOURCE latched (1280-wide): 2560x1448 fmt=29`. The
  parenthetical is wrong and would mislead anyone grepping for the source width.
- **The `lua-pane DISAGREES` warning misfires in VR.** It read 13.0° then 3.5° within seconds, varying
  with rifle motion — the signature of the Lua publishing its pane at ~2 Hz while the plugin recomputes
  from the live transform every tick, not of a wrong convention (flat, with the rifle still, it read
  `agrees` all afternoon). Its text says "this is a DERIVATION error … do not tune, fix", which would
  send a future session hunting a bug that is not there. It should compare like with like: only judge
  when the rifle is nearly still, or timestamp the Lua's pane.

## 7. Not established

- Frame cost of the 2560 target, and everything about 3840.
- `crop_mode` 1 and 3 in VR.
- Whether `roll_k` helps in VR — it needs a settings-file value and a relaunch, which tonight had no
  room for.
- The 2560 target has been latched exactly once, in VR, in one process `[n=1]`.

**GATE: VR — NOTHING FURTHER WITHOUT THE HEADSET** on the row that matters. Everything cheaper is
either done or now superseded: the sharpness comparison is answered, the 2560 allocation is answered,
and the roll law turned out to be a VR question. Two `[PD]` items remain (the log defects), and the
3840 target is one flat launch.
