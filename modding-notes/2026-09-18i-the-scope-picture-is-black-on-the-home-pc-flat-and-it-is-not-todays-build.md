# The scope picture is black on the home PC in flat mode — and it is not today's build

**2026-09-18, home PC (`RTX`), `/lm`, five launches, all flat.** The session that was supposed to run
the home-PC group-A tests instead found the thing those tests depend on.

---

## What this session set out to do

Clear `owed/HOME/2026-09-18-re-village-scope-the-13-tests-that-need-the-game-running.md`: group A
(the clothing test, the flicker diagnostic, the rig-rebuild fallback), group B (spread, scope
signature), group C, and the seven addendum items the dev PC added the same evening.

## Step 0 — the deploy, which worked

This machine's install was four files behind and `body.lua` did not exist here at all. Built the
plugin from `staging/re-village-scope-vr/plugin/` (clean; the cmake-version trap the dev PC hit did
**not** occur here — the cache was made by the same cmake 4.4.3 that is on `PATH`), backed up the old
install to `Backup/scope-2026-09-18-pre-deploy/`, copied 18 files plus the two new helper batch files,
verified every copy byte-identical, and stamped all 22 with `deployed.sh record --replace`.
`deployed.sh check` → `ALL 22 FILE(S) MATCH`. `[measured 2026-09-18]`

⚠️ One thing that looked like lost work and was not: the deployed `re8_scope_host_follow.lua` was
9,152 bytes against staging's 8,960, and dated four days later. It is the same file with CRLF line
endings — 192 lines, 192 bytes. Checked before overwriting. `[measured 2026-09-18]`

**`LAUNCH-VILLAGE.bat` and `KEEP-LOG.bat` work.** Nobody had ever run them (the session that wrote
them does not launch games) and their log-copying half had only been tested against a fake log. Five
launches, five logs preserved in `reframework/logs/`, Steam started correctly every time.
**Addendum item 3 is closed.** `[verified-live 2026-09-18, n=5]`

## The finding

**With the scope assembled and the rifle scoped, the scope picture is pure black.** Only our two
green debug markers are drawn on it. The disc sits at roughly (963, 522) r≈140 in a 1920×1080
capture — exactly where `dev-archive/tools/scope_metrics.py 963 522 135` expects it, which is how we
know the black disc *is* our picture and not some other part of the scope model.

Everything that reports on the picture says it is fine:

| what the mod says | value |
| --- | --- |
| `bringup` | `DONE` every launch, no `FAILED`, no `WARNING` |
| `glass_bound` | `2` (our glass is on) |
| `mirror_latched` / `mirror_hdr` / `mirror_ui` | `1` / `1` / `1` |
| `frame:` line | `mirror=1 src_w=1920`, 160–207 fps |
| `hold 1` summary | `frames=25200 spikes=0 holds=0 avg=0.0000 max=0.000` |

`[measured 2026-09-18, n=5 launches]`

### What was ruled out, in order

1. **Not the scene.** Turned 180° from the Duke's shop to the open village and looked again:
   byte-for-byte the same black disc. Evidence `02-turned-180-still-black.png`.
2. **Not the source format.** `src8 1` (the 8-bit resolve instead of the raw HDR buffer) changed
   nothing. `src8 0` put it back.
3. **Not a stale latch — or rather, the documented recovery does not cure it.** Every launch prints
   the ambiguous wave-2 line: *"rig rebuild #1 at the latched width (1920) and the latch did not
   change: … if it is frozen or wrong, the latched source was never this rig's (a boot latch) —
   numpad . and rebuild"*. Ran exactly that: numpad `.` then `rerig`. The re-arm went **PENDING**, no
   further `MIRROR SOURCE latched` line ever arrived, and the picture stayed black.
   Evidence `03-after-numpad-dot-rearm-and-rerig-still-black.png`. `[measured 2026-09-18, n=1]`
4. **Not a dirty session.** Closed the game, relaunched cold, loaded the save, one clean `bringup`,
   nothing else. Black. Evidence `04-clean-relaunch-single-bringup-still-black.png`.
5. **⭐ Not today's build.** Put the previous deployed plugin back (217,600 bytes, the 2026-09-17
   stamp on this machine), relaunched, single clean `bringup`: **identical black picture, identical
   log shape.** Then restored today's build and re-stamped. Evidence
   `05-yesterdays-plugin-same-black.png`. `[measured 2026-09-18, n=1 per build]`

### The diagnostic that was built for this could not speak

`hold 1` is accepted and its summary prints. `holddiag 120` is accepted — `[re-scope-vr] hold_diag ->
120 frame(s) of raw flicker diagnostics` appears — but **not one `holddiag:` line is ever printed**,
so none of the four verdicts was reached. Because the `hold:` summary *does* print, the outer guard
at `present.cpp:604` passes; something inside it stops short, most likely `g.rt_prev_valid` never
becoming true. **Not confirmed — handed to a static pass.** `[hypothesis]`

⚠️ So **A2 is not answered.** `avg=0.0000` is still unexplained, and the instrument built on
2026-09-18 to explain it did not run. What we now know that we did not before is that the picture it
would be measuring is black, which makes "THE MEASURE IS REAL AND THE ANSWER IS ZERO" the obvious
candidate — but that is a guess until a `holddiag:` line actually prints.

### The lead worth chasing first

**No confirmation of a working scope picture with the headset OFF has been found in our own notes.**
Every confirmation this session could find was a headset wear. `re2_fw_config.txt` carries
`VR_ExemptMirrorCameras=true`, `VR_MirrorUsesOriginalCamera=true` and `VR_RenderingTechnique_V2=2`,
and REFramework did **not** enter VR on any of these launches (`XR_ERROR_FORM_FACTOR_UNAVAILABLE` —
no headset connected). If the buffer our hook waits for is one REFramework only allocates in VR, then
the picture has never worked flat and nobody noticed, because all the judging was done in the
headset. **That would re-gate several board rows from FLAT to VR.** `[hypothesis]` — handed to a
static pass with the five logs and five screenshots.

---

## What DID get answered, and it is not nothing

### A1 — the clothing probe: the access path is good and the automatic trigger exists ✅

`bodyprobe` found `app.PlayerMeshController` via `get_playerMeshController` (route 2 of the three).
**`IsAimSniperRifle field=true` while scoped** — so the automatic mode has a real trigger and
`bodyhide 1` is a buildable feature, which was the open question.

Nine mesh fields present, two absent (`FaceMesh`, `HairMesh`). Four are drawable:

```
[body  ] UpperBodyMesh   DrawDefault=true    [arms  ] LArmMesh   DrawDefault=true
[body  ] LowerBodyMesh   DrawDefault=true    [arms  ] RArmMesh   DrawDefault=true
[shadow] 5 × *ShadowMesh DrawDefault=false / ShadowCast=true
```

`bodyhide 2` reported `HIDDEN -- 7 meshes written`, cleanly, no failures. `[verified-live 2026-09-18, n=1]`

⚠️ **The half that matters is still unanswered**: whether hiding Ethan clears the *scope picture*
cannot be judged while the picture is black. And in the ordinary first-person view Ethan's hands and
the rifle were still visible after the hide — but that was not measured properly (the frame-diff was
swamped by the ADS-release camera settle, which is the exact trap `ai-game-control-profiles` already
warns about), so **no claim is made about it.**

### A3 — the rig-rebuild fallback: it holds ✅

`bringup` produced `rig rebuild #1 seen … re-arm pending=0 -- watching ~2 s for the latch to follow`
and then the at-the-latched-width branch, not `the latch did NOT follow`. The discrimination the
2026-09-18 rework added is working on a fresh `bringup`. `[verified-live 2026-09-18, n=3 launches]`

### B1 — the aimed spread dump: answered, negatively, and cleanly ⭐

Ran `spreadprobe` not aiming and again while aiming, same save, same weapon, and diffed the two live
weapon dumps mechanically (75 lines each).

**Exactly one field differs:**

```
not aiming:  <DrawOffByScope>k__BackingField = false
aiming:      <DrawOffByScope>k__BackingField = true
```

That is a draw flag, not a spread value. The two spread-named fields on the live weapon —
`isReduceRecoil = false` and `isRestrictAimShake = true` — **do not change between the two states.**

So, by the row's own rule: **the aim state does not live on the weapon.** Reducing spread by writing
a weapon field is not the route; it lives on the player or in the shot code.
`[verified-live 2026-09-18, n=1 pair]`

⭐ Two by-products worth keeping: `isRestrictAimShake = true` is a shipped flag directly relevant to
the rifle-shake row, and `DrawOffByScope` is a per-weapon "do not draw this while scoped" flag, which
is relevant to both the clothing row and the hide-the-stock-scope idea (B3).

### B2 — the high-magnification scope signature, re-read ✅

`scope-signature: materials-enabled [m0=1 m1=1 m2=1 m3=1] parts=present-but-no-count (not read)` —
identical to the previously recorded reading. The comparison still needs the **stock** scope fitted,
which needs inventory driving this session could not do (see the input gap below).
`[verified-live 2026-09-18, n=1]`

### Addendum item 1 — the settings-permanence fix: confirmed working ⭐✅

Set two harness overrides (`hold 1`, `framev 2`), pressed numpad 1, and got exactly the line the fix
was built to print:

```
settings saved, and 2 harness override(s) were NOT made permanent -- kept the boot value for:
hold 0 (live 1), frame_v 1 (live 2).
```

`re_scope_vr_settings.txt` still reads `hold=0` and `frame_v=1` afterwards. The once-per-launch
`boot values captured for 26 harness-commandable knobs` line was present. The save also added the new
`frame_vneg=-1` key, as expected. **The 2026-09-17 `frame_v=2` accident cannot happen again.**
`[verified-live 2026-09-18, n=1]`

### Addendum item 5 — the shake reading: the control works ✅

Both `jitter (last ~1 s):` states were produced and read correctly:

```
held still:    bore path 0.030 deg net 0.015 max-step 0.0009 ratio 1.0 (held still)
being aimed:   bore path 0.177 deg net 0.173 max-step 0.0047 ratio 1.0 (being aimed (smooth))
```

Step 2 — the control the whole reading depends on — reports `being aimed (smooth)` as required, so
**the instrument is awake and trustworthy.** At 2.4× the bore travel arrives at the eye as 0.07 deg
held still. ⚠️ This was **not** a real shake test: the rifle was held by a script, not by a human
hand in a headset, so the "is the pose we are handed already shaking" question is untouched. What is
established is that the measure works. `[verified-live 2026-09-18, n=1 each state]`

### Addendum item 6 — the crouch/ground reading: half answered ✅⚠️

Standing, repeatedly and stably:

```
ground: the picture is taken from y=-34.02 | floor -34.69 -> above the floor by 0.65-0.67 m |
head -33.08 pane -33.56 | off_u lever -1.99 (a metre of pane moves the viewpoint that far) |
+0.08 m of off_u would leave 0.50 m of clearance
```

**Standing is healthy** and the doubling lever is confirmed live at −1.99, against the −2.00 derived
statically. `[verified-live 2026-09-18, n=many]`

⚠️ **The crouched half was not obtained** — the character could not be made to crouch (below).

### Home-PC frame rate, for free

160–207 fps flat at 1920×1080 with the scope composited, `mirror=1`. Recorded because the dev PC's
numbers are not the judge of anything. `[measured 2026-09-18]`

---

## The automation gap this session hit, and it is the next session's first job

**After the harness's `ads` hook has run, the game stays in gamepad input mode and ignores synthetic
keyboard movement.** `w`, `c` and `lctrl` all produced no change in `cam=` or in the `head` figure of
the `ground:` line, across repeated tries, with `ads 0` sent and acknowledged first. Weapon-slot keys
appeared to register once (`switch: rifle leaving the hands` fired) but could not be made to repeat.

This is already half-documented in `ai-game-control-profiles/profiles/resident-evil-village.json`
("The game switches to pad input mode while held, so keyboard/mouse are ignored until released") —
what is new is that **it does not reliably release**, which silently blocks:

- the crouch half of item 6,
- the inventory work B2/B3 need (fitting the stock scope),
- item 7's weapon-switch re-bind measurement (`auto re-bind: the glass took after N ms` never
  printed, because the rifle could not be brought back).

`[verified-live 2026-09-18, n=several]` The fix belongs with the `ads` hook — either release the pad
mode properly on `ads 0`, or drive movement through the same pad the hook already owns rather than
through `SendInput`.

---

## Not attempted this session, and why

| Row | Why not |
| --- | --- |
| A1's visual half, addendum item 4 (`framev 2` / `framevneg`), C2 (1920 vs 1280 sharpness) | all are judgements of a picture that is black |
| B2 second reading / B3 | needs the stock scope fitted — blocked by the input gap |
| Item 7 (weapon-switch re-bind timing) | same |
| C1 (roll sweeps), C3 | time; nothing blocking them |
| Group D (all four) | the headset, which was not connected |

---

## Files

- Five full logs: `reframework/logs/re2_framework_log-2026-09-18_22-{10-15,23-55,28-18,32-34,41-00}.txt`
- Five screenshots: `dev-archive/recon/2026-09-18-flat-scope-picture-is-black/`
- Pre-deploy backup of the install: `<game>/Backup/scope-2026-09-18-pre-deploy/`
