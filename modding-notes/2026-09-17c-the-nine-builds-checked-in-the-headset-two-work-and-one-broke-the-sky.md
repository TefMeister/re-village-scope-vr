# 2026-09-17c — the nine 2026-09-16 builds checked in the headset: two work, one broke the sky (`/ms`, home PC `RTX`, Tefa wearing, 21:54–00:05)

**Tefa's brief:** *"let's get all the features that dev pc built checked today, but not work on
them, just make sure what works and what doesn't."* So this is a verdict sheet. Nothing in the
plugin or the Lua was changed. What did change: three lines of the settings file (§4), and 17 new
double-click helpers (§5).

Three launches. **Only the third launch's log survived** — REFramework truncates the log at every
launch. The lines from launches 1 and 2 were read live and are transcribed in the evidence folder;
see §6 for the lesson.

Evidence: `dev-archive/recon/2026-09-17-the-nine-builds-checked-in-the-headset/`.

## 1. The verdict sheet

| # | Build | Verdict |
| --- | --- | --- |
| c | weapon-switch glass flash, `swdelay 1500` | ✅ **works.** Now the boot value |
| f | spread probe, `spreadprobe` | ✅ **works.** There is no spread number to read |
| d | scope-signature log line | 🟡 prints on every bind; one scope only, so no comparison yet; `parts=` cannot be read |
| a | flicker: `hold 1` / `hold 2` / `src8 1` | ❌ **the measure is blind** (reads exactly 0). `hold 2` rests on the same measure. The `src8` question got answered by accident (§2a) |
| b | save-reload fallback (`rb_fb`, on by default) | ❌ **a regression: it demotes the source to 8-bit on every `bringup`.** Black sky, golden colours. Switched off in the settings file. Its real job is still untested |
| h | worn frame built directly, `framev 2` | ❌ picture upside down; the diagnostics half is right |
| g | per-eye aim, `eyepar 1` | ❌ no visible change, and its premise is disproved by its own log line |
| i | hand height, `handhigher` | ❌ the write lands and reads back; the drawn hand does not move |
| e | prop pulled in, `propu` heights | ❌ no height is clean. The cause is now understood (§2e) |

## 2. Each one, with what it rests on

### a. The flicker knobs — the measure reads exactly zero

Baseline by eye: **about 15 flickers in about 2 minutes** of ordinary play, then **about 12** in
the next 2 minutes with `hold 1` on `[verified-live 2026-09-17, n=2 counts, 1 wearer]`.

`hold 1` was received (harness line 22:32:45) and the measuring block ran: its frame counter
climbed to 23,400. But every summary reads `spikes=0 holds=0 avg=0.0000 max=0.000`, at the shipped
threshold and again at `holdt 0.005`, the floor of the clamp `[verified-live 2026-09-17, n=8
summaries over 7 minutes]`. The wearer was walking and aiming throughout. A working measure cannot
read a mean luma change of 0.0000 across a moving picture, so **this is not "no flicker found". The
comparison is returning nothing.**

Not established: why. The descriptor slots, the render target view, the copy to the readback
buffer and the shader were all read again during the session and nothing is visibly wrong
`[inferred-static]`. The candidates not yet excluded: the diff draw does not land in `diff_rt`;
the readback maps a buffer the copy never reaches; or `g.rt` at that point in the frame does not
hold this frame's picture in VR. A flat launch can separate these: if `avg` is non-zero flat, the
fault is specific to the VR present path.

`hold 2` was not run. It decides on the same number, so it cannot trigger.

**The `src8` question, answered for free.** Launch 1 ran on the kept 8-bit resolve from 22:16 to
the end (§2b), which is the same buffer `src8 1` selects (`hook::mirror_sdr` in both
`pane_file.cpp:143` and the `src8` path `[inferred-static]`). Both flicker counts above were taken
on it. So **the flicker happens on the 8-bit path-bound source too, and reading A of the 09-16
note (the pooled raw-HDR buffer is the cause) is out** `[verified-live 2026-09-17, n=1 wearer,
2 counts]`. Not counted tonight: the rate on raw-HDR, so "the same rate on both" is not claimed.

### b. The save-reload fallback demotes the source on every `bringup`

Wearer, launch 1: *"the sky is black through the scope again and the golden colours are back."*

Launch 1's log: source latched 22:16:03.981, **upgraded to raw-HDR at .987, and at 22:16:04.110
`rig rebuild #1: source fell back to the 8-bit resolve`**. `bringup` rebuilds the rig as part of
its normal run, and the 09-16b fallback treats that rebuild like a save reload. The line promises
the upgrade watch reopens "for the next fmt-26 allocation". None had arrived by 22:51, 35 minutes
later, when the log was last read before the game was closed. Black sky and a golden cast are the recorded signature of the 8-bit resolve
(dossier, the 2026-08-30 sky runs).

A/B `[verified-live 2026-09-17, n=1 wearer; log n=3 launches]`:

- `rb_fb` on (default), launch 1: demoted, black sky.
- `rb_fb=0` in the settings file, launches 2 and 3: `UPGRADED`, no `fell back` line, *"sky is
  back, colours look normal again"*.

Switching it off **live** did not recover the picture: `rbfb 0` then the panel's `. Re-arm mirror
latch` logged `re-arm PENDING` and waited for an allocation that never came. A relaunch was the
only way back. That matches the 2026-09-05 finding that allocation cannot be predicted from
outside.

**Not established: whether the fallback does its actual job.** No save was reloaded tonight. The
security-camera row is exactly where it was, minus one candidate fix that cannot ship as built.
If it is reworked, it has to tell a save reload from `bringup`'s own rebuild, or re-upgrade itself.

### c. The weapon-switch flash — works

`swdelay 1500`; rifle to pistol and back, several times. Wearer: *"no white flash on the scope
glass at all."* Log: `switch: rifle leaving the hands -- glass restore deferred 1500 ms`, then
`deferred glass restore now` 1.49–1.50 s later, on all 11 switches away from the rifle; no crash
`[verified-live 2026-09-17, n=11 switches, 1 wearer]`. The row's own condition for making it the
default is met, so `sw_delay=1500` is now in the settings file.

Not exercised: the fast path (`the same rifle came back before the deferred restore`). Every
switch back tonight took longer than 1.5 s.

**A separate, older thing seen here:** switching *back* to the rifle shows the stock glass (dark,
orange reticle) for about a second (shot3). That is the auto re-bind's own wait: `binding the
glass at +1 s and +5 s`, and press 1 lands 1.0 s after the rifle returns. Whether the first
press can come sooner is a new `[PD]` row. The wait may be there because the glass is not
bindable earlier, which has not been checked.

### d. The scope signature — prints, but there is nothing to compare it with

18 lines on launch 3, all `materials-enabled [m0=1 m1=1 m2=1 m3=1] parts=present-but-no-count
(not read)`, high-magnification scope fitted. The logger works
`[verified-live 2026-09-17, n=18 binds, one scope]`. The part-visibility half found the enable
call but no count, so it declines to read. Still needed: the same line with the stock scope
fitted (the board row says it swaps in the inventory; not tried tonight).

### e. The prop heights — no height is clean, and the reason is geometric

Standing (launch 1): `propu -0.4` shows Ethan's jeans, `propu 0.1` shows the rifle itself,
`propu -0.2` and `propu 0` show clothing. Crouched (launch 3): at `-0.2` the picture is **half
under the ground** plus clothing (shot1, 23:38); at `0.1` it clears the ground and shows clothing
(shot2, 23:44) `[verified-live 2026-09-17, n=1 wearer, 2 screenshots]`. `-0.4` was also clicked
while crouched (23:43:22) and drew no separate comment; level (`0`) was not tried crouched.

This fits the 09-16e derivation: moving the plane moves the mirror's virtual viewpoint by twice
the distance. At a 20 cm drop the viewpoint sits 40 cm below the bore, which is under the floor
when crouched and inside the player's body when standing. **Height trades one intrusion for
another. It is the wrong knob.**

Tefa's workaround: hiding Ethan's body in REFramework's VR menu removed the clothing at the
normal drop. Those are `RE8VR_HideUpperBody` / `RE8VR_HideLowerBody` (and `RE8VR_HideArms`). They
were **not saved** — all three read `false` in `re2_fw_config.txt` afterwards — so the body was
back after the relaunches, which is why shot1 and shot2 show clothing again. Tefa: *"still i hope
there is a better solution to this."* Two candidates, neither checked against the engine: switch
those flags from our Lua only while the scope is up, or keep the player's meshes out of the mirror
pass. The mirror's own clipping is still unstudied. The ground intrusion needs its own answer
either way: hiding the body does nothing for it.

Step (1) of the row, `propoff` against `propnear`, was not run.

### g. The per-eye aim — no change, and the premise is disproved

Wearer: *"honestly it is pretty damn steady now, it was before TEST-5-EYE-AIM-ON.bat as well."*
The 09-16g reading was that the reflected eye hops every frame by about 0.06 m. Its own log line
says otherwise. Of 231 lines, **200 read `eye moved 0.000 m` or `0.001 m since last tick`**, 24
read 0.002–0.007 m, and 7 read 0.037–0.051 m; the aim sits 0.0–1.5° off the bore
`[verified-live 2026-09-17, n=231 lines]`. An eye that hopped every frame would show the large
figure on every line. It shows it on 3%. Six of those seven fall inside one 32-second stretch
(23:38:43–23:39:15), about five seconds apart, which is when the wearer was crouching and standing
to look at the ground intrusion; that they are ordinary head movement is `[hypothesis]`.

Tefa's diagnosis: *"it is the whole weapon that has that reprojection shake to it and it makes
the scope shake with it."* `[reported]` That points at the rifle model's own pose under
reprojection, upstream of anything the scope does. `eye_par` stays 0.

### h. The worn frame built directly — upside down

`framev 2`. Wearer: *"picture is upside down and moving the rifle up and down is also inverted."*
The diagnostics did what the note predicted: `geom:` went from `IMPROPER`, roll 129–140°, to
proper, roll 1–5° (evidence file). **So the frame maths is right and the assumption about the
glass is wrong**: by the note's own outcome table, upside down means the glass path does not
v-flip the way `sg_rifle_frame_rh` assumes.

Then the panel's `7 Glass flip V`: the key landed (`virtual key 0x67`), the compositor line
flipped to `glassFlipV=0`, and the wearer saw no change at all. The note expected that knob to
fix it. So either `glass_flip_v` does not reach the picture while `framev 2` is on, or the
inversion is not where the note puts it `[verified-live 2026-09-17, n=1]`. `framev 1` restored
the worn picture.

⚠️ **That `7` press saved the settings file with `frame_v=2` in it.** The plugin saves on a knob
press and wrote the live frame value as the boot value. Caught at the end of the session and set
back to 1. Left alone, the next launch would have started upside down with nothing in the log to
say why. **Any hotkey press while a harness override is live can persist that override.**

### i. Hand height — the write lands, the hand ignores it

⚠️ The first run was a false pass. Tefa reported the hand lower and the drift gone. The log had
**no `handhigher` line at all**: the click never reached the mod. Asked to repeat it, Tefa: *"you
might be right and i was just holding it differently when sitting down testing it. it did not
change at all."*

On the repeat all three commands landed: `left_hand_position_offset y 0.0450 -> -0.0050 (reads
back -0.0050)`, then back to 0.0450, then -0.0050 again, with no visible movement on any of them
`[verified-live 2026-09-17, n=3 writes]`. So `re8vr.left_hand_position_offset` is writable,
holds its value, and does not position the drawn hand in this state. The same is true of the menu
slider the 09-16i note called disconnected. Whatever places the hand is elsewhere.

### f. The spread probe — works, and finds no spread field

240 lines. Only two names match its spread/recoil/accuracy filter on the live weapon:
`isReduceRecoil = false`, `isRestrictAimShake = true`. No numeric spread or accuracy field, on
the high-magnification scope, not aiming `[verified-live 2026-09-17, n=1 dump]`. This agrees with
the 09-16f static read. Not done: a dump while scoped in, or after a shot.

## 3. What this does to the queue

- The flicker: three knobs, none usable. The pooled-buffer theory is out. The next move is a
  working measure, and a flat launch can test that.
- The zero drift row (bullets land right and high) was not touched. There was no rifle ammo
  tonight (shot3's weapon wheel shows 0).
- New rows: the blind measure; the fallback must tell `bringup` from a reload; `framev 2`'s
  inversion; keep the player out of the mirror; the re-bind's one-second wait; the hand's real
  offset; hotkey saves persisting harness overrides.

## 4. What was changed on `RTX`

Settings file only, game closed both times, backed up first
(`re_scope_vr_settings.txt.bak-2026-09-17`, `.bak-2026-09-18-end-of-session`):

- `rb_fb=0`: the fallback is off until it is reworked.
- `sw_delay=1500`: the switch fix is the boot value.
- `frame_v=2` back to `frame_v=1`: undoing the accidental save.

The plugin's first full save tonight also wrote keys the file never had before (`geom_usep=1`,
`geom_proj=0`, `mroll_sym=1`, `zero_up=14.400`, `zero_right=9.500`, and the 09-16 knobs at their
defaults). `mroll_sym=1` differs from the shipped default of 0, but `bringup` sets it to 1 anyway,
so the worn state is unchanged. Left as written.

The 19 deployed files are untouched; `deployed.sh check` said 19/19 at the start.

## 5. The helpers

17 new double-click files in the game folder and in `mod/helpers/`: `TEST-1` to `TEST-8`, the
four `TEST-3B-DROP-*` heights, and `FLICKER-1B-SENSITIVE`. Twelve were clicked tonight and each
produced the expected `harness:` line. Five have never been run: `TEST-1-RERIG`,
`TEST-2-SWITCH-DELAY-OFF`, `TEST-3-PROP-NEAR`, `TEST-3-PROP-OFF` and `TEST-5-EYE-AIM-OFF`. The
table in `mod/helpers/README.md` marks which is which. A first draft hit the trap the 09-17b note warns about (`printf` turned the `\r` of
`\re_scope_cmd.txt` into a carriage return and wrote `datae_scope_cmd.txt`). It was caught by
reading the file back before anyone clicked it.

## 6. Two lessons about the method

1. **Copy the log aside before asking for a relaunch.** REFramework truncates it. Launch 1 held
   the two most important findings of the night and its log is gone; what survives is what was
   read into the session while it ran.
2. **A wearer's "it works" needs its log line before it counts.** The hand test passed by eye and
   had not happened. Every helper click leaves a `harness:` echo line, so checking takes seconds.
