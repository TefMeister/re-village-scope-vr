# 2026-09-16 — the one-frame flicker, read from the code: the picture is probably a POOLED buffer, and three knobs to prove it (`/pd`, dev PC, Fable, NO LAUNCH)

**The game was not launched and nothing here has been run.** Everything below is static reading,
compile-verified code, numeric tests with the game stubbed, and a deploy on the dev PC.

## 1. What this was for

The top row on the board: *the flicker must go — "very distracting"*. Tefa filmed the headset on
2026-09-13 and stepped it frame by frame: the scope glass shows **the rifle itself for exactly one
frame**, then the world again (`dev-archive/recon/2026-09-13-exact-map-first-wear/flicker-frames/`).
With `posehook 1` (the mirror's pose copied just before the frame renders) the intrusions became
**Ethan's sleeve and the fence** for one frame, and the flicker stayed
`[verified-live 2026-09-13, n=2 videos]`. Random, not on a beat, as far as Tefa can tell.

## 2. What the stills actually show (looked at again today)

Cropping the scope disc out of all twelve stills and putting them side by side:

- In the flicker frame the disc does not show *the same picture with a rifle added*. It shows a
  **different picture**: the pedestal has moved a third of the disc to the right and shrunk a
  little, and a grey rounded shape fills the left half. With `posehook` on, the flicker frame shows
  the red gate at a different framing with a light sleeve across the top-left.
- The frames either side of it are identical to each other (the rifle was held still).

So the question is not "why does the rifle get *into* the mirror's render" but **"why does the glass
show a different render for one frame while nothing moved"** `[inferred-static 2026-09-16, n=2 flicker frames]`.

## 3. How the picture reaches the glass (the chain, from the plugin source)

1. The Lua rigs a `via.render.Mirror` on the hand prop and gives it a holder made from
   `movie/rtex/movie_1920_1080.rtex` — the engine allocates an **8-bit sRGB target (fmt 29,
   flags 0x1)** for that path and resolves the mirror's picture into it every frame.
2. The plugin latches that allocation as the mirror source, then **UPGRADES**: it takes the next
   1920×1088 allocation in **R11G11B10_FLOAT (fmt 26, flags 0x5 = render target + UAV)** as the raw-HDR
   source and *retires* the 8-bit one. That buffer is not path-bound to anything of ours — it is
   "one of the engine's own HDR intermediates" of the same size.
3. At present time the compositor samples the latched buffer directly (no copy), draws the scope
   image, and blits it onto the glass material's texture.

Two facts already in the record say the fmt-26 buffer is **not always the mirror's**:

- Taken as a FIRST source it showed **black**, twice, on 2026-09-05 `[verified-live, n=2 rebuilds]` —
  i.e. that allocation, of that size and format, held no mirror picture at all on those occasions.
- The engine allocates several of them (the upgrade explicitly waits for "the next one").

RE Engine hands intermediate render targets out from a pool keyed by size and format. If the mirror's
scene buffer comes from such a pool, then on some frames the buffer we hold is handed to **another
pass** (or the mirror gets a different one), and at present time we sample whatever that pass drew:
a different framing with the rifle, the sleeve, the fence — near things from the *main* view.
That fits the stills, fits "random", and fits `posehook` changing nothing.

**Ranking, all `[hypothesis]` until a wear decides:**

| # | Reading | Fits the stills? | Fits `posehook` failing? | What separates it |
| --- | --- | --- | --- | --- |
| A ⭐ | the raw-HDR source is a **pooled buffer** another pass sometimes writes | yes (different picture) | yes | flicker gone on `src8 1` (8-bit path-bound source) |
| B | the mirror renders once per **eye camera** (multipass duplicate) into one target; we sometimes sample the *other* eye's | partly (small shift expected, a large one seen) | yes | spike log's `P02/P20` sign: spikes always at one eye phase |
| C | the mirror's pose is wrong for one frame (a second writer or a torn position/rotation write) | partly | no (posehook changed *which* thing intrudes, not whether) | flicker persists on `src8 1`; `hold 2` still hides it |
| D | the stock glass re-appears for a frame | no (stock glass is dark, not a scene) | — | — |

## 4. What was built (compile-verified, tested with the game stubbed, deployed on the dev PC, NOT run)

All off by default; the shipped picture is unchanged until a knob is set. All live through the
pane file, like `geomrot`.

- **`hold 0|1|2`** — a frame-change measure in the plugin: a 16×12 pass takes the mean |luma delta|
  between this frame's scope image and the last **shown** one, reads it back, and decides on the CPU:
  - `hold 1`: **measure and log**. Every spike prints `hold: SPIKE #n d=… avg=… -> logged only (src=… P02=… P20=…)`
    for the first 20 and every 50th; a summary every ~25 s (`frames / spikes / holds / avg / max`).
    **The spike count is the diagnostic**: it should agree with the flickers Tefa sees.
  - `hold 2`: also **show the last good frame again on a spike**, never twice in a row. Works
    whatever the cause. Rule in `plugin/src/hold_math.h`; `tools/hold_test.cpp` 16/16
    `[verified-numerically 2026-09-16]` — including the case the first draft got wrong: a steady
    fast pan was being held every other frame (36 Hz judder). Fixed: the frame after a spike is
    always shown, and if it still differs the running average jumps to it.
  - `holdt <0.005..1>`: the spike threshold (boot 0.08, mean luma delta 0..1). Raise it if ordinary
    play logs spikes.
  - Cost: one extra fence wait per present, which mostly moves the existing end-of-frame wait earlier.
- **`src8 0|1`** — when the latch upgrades to the HDR buffer, the 8-bit resolve is now **kept** (a
  second slot, `mirror_sdr`) instead of retired; `src8 1` samples it live. The 8-bit resolve is
  path-bound to *our* `.rtex`, so nothing else can write it. **If the flicker stops on `src8 1`,
  reading A is confirmed.** Sunlight clips to white on this path (the 2026-08-31 "golden veil"), so
  it is the test, not the fix.
- **`fn rtex_hdr`** (say it BEFORE `bringup`) — the fix to try if A confirms: an **authored FLOAT
  `.rtex`** (`natives/stm/movie/rtex/scope_1920_1080_hdr.rtex.5`, 1920×1088, format 26 — the format
  `mirror_env.rtex` ships in, so the engine knows float targets). Path-bound raw HDR, no pooled
  buffer. The plugin accepts a fmt-26 first source **only** while the Lua says it rigged this
  (pane `rtex_hdr=1`) and never with UAV, so the black 2026-09-05 intermediates stay refused. The
  upgrade branch never fires on it (it is already HDR). Expected log: `MIRROR SOURCE latched:
  1920x1088 fmt=26 flags=0x1` and **no** `UPGRADED` line. `[hypothesis: the engine allocates a float
  .rtex as flags 0x1]` — a `fmt=29` latch or no latch means it ignored the format; the holder then
  falls back to the shipped 1920 target by itself.
- The two authored 2560/3840 descriptors from 2026-09-06 existed only in the home PC's game folder;
  re-authored byte-for-byte by the same tool and committed under `staging/…/natives/`, so both PCs
  now carry them (evidence-in-one-place rule).
- `tools/run_test.bat` now finds the build tools on either PC; `check-shader.sh` covers `ps_diff`.

Numbers: plugin 0 errors, 0 warnings; `hold_test` 16/16, `geom_test` 124/124, `crop_follow_test`
40/40, `mirror_roll_test` 176/176, `roll_math_test` 20/20, `tone_curve_check` all pass, fxc all five
entry points OK; Lua compiles (three files), `bringup_sequence_test` 29/29.
Dev-PC install re-stamped 14/14 (`deployed/DESKTOP-V8GTSIR/re-village-scope-vr.tsv`).

## 5. What is NOT established

- Nothing above has run in the game. The measure's typical values (`avg`) under normal play are
  unknown, so the 0.08 threshold is a guess; the summary line is there to correct it.
- Reading A is the best fit, not a finding. The stills cannot tell A from B on their own.
- Whether the engine accepts a float `.rtex` at all.
- Whether `hold 2` at 72 Hz is invisible in the headset (it repeats one frame per spike).

**The diagnostic that would show the *derivation* is wrong, not a knob:** `hold 1` logs **no spikes**
while Tefa sees flickers. Then the glass is changing without our composite changing — i.e. the
flicker happens *after* our blit (the glass material / the engine's own draw of the lens), and none
of the three knobs can touch it. That would point at reading D after all, or at the lens material.

## 6. NEXT (one VR launch, home PC)

1. `bringup`, play normally for a minute. Note roughly how many flickers were seen.
2. `hold 1`, play a minute. Read the log: spike count vs flickers seen. *Also read the summary's
   `avg` — if ordinary play already logs spikes, `holdt 0.15` and repeat.*
3. `hold 2`, play a minute: **flicker gone?** (Any judder on fast rifle swings?)
4. `hold 1`, then `src8 1`, play a minute: **flicker gone AND spikes stop?** ⇒ reading A. Sunlight
   will look worse; that is expected.
5. Next launch, if 4 said A: `fn rtex_hdr` then `bringup`. Log must say `fmt=26 flags=0x1`, no
   `UPGRADED`. Flicker gone with the HDR look intact = done.

Outcomes: 3 works but 4 does not ⇒ keep `hold 2` on (write `hold=2` into the settings file) and
the cause is B or C. 2 logs nothing ⇒ §5's last paragraph.

## 7. Also on this pass

- **The dev PC now runs the home PC's build.** Scripts identical to the home install (line endings
  aside) and the plugin from the same source, plus today's knobs. Not carried over: the **patched
  REFramework `dinput8.dll`** (v2 window-only + plan C). Its source patch and binary exist only on the
  home PC (`D:\RE2 REFramework builds\tools\REFramework-src\mirror-exemption.patch`) — nowhere in git.
  That is the same one-place pattern that lost XIII's proxy source; a `[PD @home]` row asks for it to
  be committed. §9m says the patch did not cure the swing, so the dev PC's stock REFramework is fine
  for flat work; whether the exemption changes the *picture* today is unknown.
