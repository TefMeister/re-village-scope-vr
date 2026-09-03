# 2026-09-03 — The scope gets the game's own three-section tone curve (`/pd`, home PC, NO LAUNCH)

**The game was not launched and nothing here has been run.** Everything below is
`[compile-verified 2026-09-03]` or `[verified-numerically 2026-09-03]`; the first look is the
next flat session's job, and §6 says exactly what to look at.

Source: `staging` `87efe59`. Deployed: `re_scope_vr.dll` 139,264 B (previous kept as
`re_scope_vr.dll.pre-shoulder-backup-2026-09-03`) and the panel script
`re8_scope_m6_mirror_producer.lua` (previous kept as `…lua.pre-shoulder-backup-2026-09-03`).
Both hash-verified after copy.

---

## 1. In plain words

The scope's picture comes from a second render of the scene (the "mirror") that arrives as raw
light values, not as a finished image. Turning raw light into something a screen can show is the
job of a *tone curve*, and the one the scope had been using was the simplest possible shape: a
curve that bends from the very first step and flattens out at the top. One knob — the exposure —
slid the whole picture along that curve. Yesterday's tuning showed the problem with that: at the
knob position where the village looked right, sunlit snow was a flat white blob, while the game's
own view kept the texture in it.

The game does not use that simple curve. Its grading component (`via.render.ToneMapping`) is a
**three-section** curve — a soft toe for the darks, a **dead-straight** middle, and a separate
shoulder that rolls the brightest values off — and we already had its live numbers from the
2026-08-30 recon. Those numbers (0.22 / 0.40 / 1.33 / 1.0) turn out to be, to the digit, the
published defaults of a well-known curve (Uchimura's "GT" tonemap, CEDEC 2017). So the scope now
uses that curve, fed with the game's own parameters read live, instead of inventing one.

What this buys, and what it does not (§3 has the numbers): the straight middle means the
midtones reproduce the game's response *by construction* instead of by tuning; the shoulder is a
separate term. But **the new curve does not by itself bring the snow back at the current knob**
— it needs the knob to come down, and the straight middle is what should let that happen without
the village going muddy. Whether it actually does is the test.

## 2. What was built

| Piece | Where | What it does |
| --- | --- | --- |
| The curve, one file | `plugin/src/tone_curve.inc` | Uchimura GT in the C/HLSL common subset. **Compiled twice from the same bytes**: `#include`d into `Plugin.cpp` as C++ (for the CPU-side inverse), and read by CMake into a generated header that is prepended to the HLSL string, so the pixel shader runs the exact text the harness tests. |
| Shader | `ps_main`, raw-HDR branch | `toneMode > 0.5` → per-channel GT on the exposed value (`knob · 0.4 · 2^-EV`, unchanged); else the old `1-exp`. Root constants 12 → 20. |
| Live parameters | `world_tick`, beside the `get_EV` read | `UseTripleSectionTonemap`, `LinearSectionBegin/Length`, `SDRToe`, `HDRToe`, `Contrast`, `Min/MaxWhitePoint`, `WhiteRange` — `Method*` cached once, read at ~2 Hz, sanity-gated, **logged on first read and on every change**. |
| Toe choice | `init_gpu` | swapchain `R16G16B16A16_FLOAT` or `R10G10B10A2` → `HDRToe`, else `SDRToe`. Logged. `[hypothesis]` |
| White point | settings key `tone_wp` (default 0) | If on, divides the exposed value by `MinWhitePoint / 5.6` — 1.0 at the outdoor value the knob was tuned against. `[hypothesis]`, deliberately off for the first look. |
| Sky-fill anchor | CPU side | Under GT the "paint the sky at 0.72 post-tonemap" gain is `gt_inverse(0.72) = 0.7724 / exposure` instead of `1.2730 / exposure`; the inverse is the shipped one, by bisection. |
| Controls | numpad `5`, `8`, `2` | `5` cycles **GT + live EV → exponential + live EV → exponential + EV frozen at 3 → …**. `8`/`2` retune the knob of whichever mode is active. |
| Knobs | settings `exposure_gt` (new) and `exposure` (untouched, 0.134) | Both start at 0.134, so the very first `5` press is a pure A/B of curve *shape*. |
| Panel + status | `re8_scope_m6_mirror_producer.lua`, `re_scope_vr_status.txt` | Shows `grading: GT CURVE / EXPONENTIAL / …`, the active knob, whether the live parameters were read, and the game's current white point. |
| Static checks | `plugin/tools/tone_curve_check.cpp`, `plugin/tools/check-shader.sh` | §4. |

Nothing on the 8-bit (backbuffer / SRGB resolve) path changed: that path is display-referred and
never enters the tonemap branch.

## 3. What the numbers say — read this before the first look

`tools/tone_curve_check.cpp` prints these; they are the shipped curve, not a transcription.
`[verified-numerically 2026-09-03]`

Exposed value x′ → output, GT vs the old exponential:

| x′ | GT | EXP |
| --- | --- | --- |
| 0.10 | 0.087 | 0.095 |
| 0.22 | **0.220** | 0.197 |
| 0.40 | **0.400** | 0.330 |
| 0.532 | **0.532** | 0.413 |
| 1.0 | 0.828 | 0.632 |
| 2.0 | 0.980 | 0.865 |
| 3.0 | 0.998 | 0.950 |

The straight section runs **0.22 → 0.532**, not 0.22 → 0.62: in GT the "length" 0.40 is a
fraction of the `(P − m)` headroom divided by the contrast, so `l0 = 0.78 × 0.40 = 0.312`. (The
`/gr` drop read it as an absolute length; corrected in its inbox.)

Raw mirror radiance at **yesterday's knob (0.134) and EV 3** — effective exposure
`0.134 × 0.4 × 2⁻³ = 0.0067`:

| raw | x′ | GT | EXP |
| --- | --- | --- | --- |
| 8 | 0.054 | 0.037 | 0.052 |
| 40 | 0.268 | 0.268 | 0.235 |
| 100 | 0.670 | 0.652 | 0.488 |
| 200 | 1.34 | 0.917 | 0.738 |
| 500 | 3.35 | **0.999** | 0.965 |
| 1000 | 6.70 | 1.000 | 0.999 |

Two honest consequences:

1. **At the same knob, GT is brighter in the mids and clips the top *harder*, not softer.** The
   shoulder of a P = 1 GT curve is steeper than `1-exp`. So the first `5` press should make the
   picture look a little brighter and the snow, if anything, slightly worse. That is expected and
   is not the verdict.
2. **The fix is the knob coming down** — two to four presses of numpad `2` in GT mode (each
   −20 %). At half the knob (0.067): raw 200 → 0.652, raw 500 → 0.959 — texture in the snow — while
   raw 40 sits at 0.127 instead of 0.268. Whether the village then still reads like the game's
   view is the real question, and it is exactly the trade the straight middle is supposed to win
   over the exponential (at the halved knob EXP gives raw 40 → 0.125, raw 200 → 0.488: darker
   *and* flatter).

### 3a. A correction to yesterday's board row

The row said "at `exposure=0.134` anything above ~25 raw lands ≥ 0.96". That used the knob as
if it were the effective exposure. The effective value is `knob × 0.4 × 2⁻ᴱⱽ` = 0.0067 at EV 3, so
flat white (≥ 0.96) starts at **raw ≈ 480**, not 25. The defect stands — the screenshots are the
evidence, and sunlit snow plainly reaches that — but the number in the row was wrong by ~20×.
The 08-31 probe figures (terrain 8–40, sun 2385) are consistent with this: at the old knob the
terrain lands at 0.05–0.24, so the village scene the user matched to the game must run well above
the 8–40 band. `[verified-numerically 2026-09-03]` for the arithmetic; the scene radiances remain
`[measured 2026-08-31, n=1 probe]`.

## 4. Verification done (no game needed)

- **Numeric harness** (`clang++ -std=c++17 -Wall -Wextra`, zero warnings): the shipped `.inc`
  against an independent transcription of Uchimura's GLSL over 0..20 — **max |Δ| = 5.3 × 10⁻⁸**;
  `y(m) = m`; the section `m..S0` is *exactly* `m + a(x − m)` at 99 points; value and slope
  continuous at `S0` (slope 1.0000 / 0.9968 vs a = 1); monotonic over 0..100, never above P,
  reaches 0.9999 by x′ = 100; with `c = a = 1` it is the identity on 0..S0; the shipped inverse
  round-trips at 99 points to < 10⁻⁴. **ALL CHECKS PASSED.**
- **Shader**: `tools/check-shader.sh` assembles the same source the plugin hands to `D3DCompile`
  (`tone_curve.inc` + the `kShaderSrc` raw string extracted from `Plugin.cpp`) and runs `fxc`
  (Windows Kits 10.0.26100) on all four entry points: `vs_main`, `ps_main`, `ps_comp`, `ps_blit` —
  all OK. Previously a typo in the HLSL would only have surfaced at the next launch.
- **DLL**: VS2022 Release, **zero warnings**, both `reframework_plugin_*` exports present
  (`dumpbin`), 139,264 B, MD5 `d413bafb…` identical on disk and in the game folder.
- **Lua**: `luac -p` clean; the deployed copy was byte-identical (modulo CR) to git HEAD before
  it was replaced, so nothing uncommitted was overwritten.

## 5. What is NOT established

- **Nothing has been run.** The shader compiles; whether the picture is right is the next
  session's call.
- **That the game's curve *is* Uchimura's GT** is `[inferred-static 2026-09-03]`: the four live
  values match the published defaults exactly, and the parameter *names* match term for term,
  but the engine's algebra has not been read. **The build does not depend on it** — it depends
  on the measured shape (straight middle, separate shoulder), and on our own curve being what
  the harness says it is.
- **`Contrast` = GT's `a`** is `[hypothesis]`. It reads 1.0, where the mapping is the identity,
  so it cannot be wrong *today*; it could be if the game ever moves it.
- **Which toe (SDR 1.0 vs HDR 1.33)** is chosen from the swapchain format — `[hypothesis]`,
  logged at init so the next log answers it. The two differ only below x′ = 0.22.
- **What `MinWhitePoint` / `MaxWhitePoint` / `WhiteRange` mean** is unknown. They move with the
  zone (5.6 → 8.0 and 0.9 → 0.8 on 08-30). The `tone_wp` divisor is a guess at the *direction*
  (a higher white point = the same raw lands darker) and is **off by default**; the change-log
  line is what will show whether they track anything the scope needs.
- **Whether any global curve closes the gap at all.** The mirror render has no atmosphere pass
  (sun-only light, black sky — 08-31 finding), so its dynamic range is plausibly *wider* than the
  game view's, which has skylight filling the shadows. If, with the knob lowered until the snow
  shows texture, the village is clearly darker than the game view **in both modes**, the curve
  was never the whole story and the remaining gap belongs to the sky/WB package. `[hypothesis]`

**Diagnostics that would say the derivation is wrong, rather than a knob needing a nudge:**

- Log says `tone curve online: … REJECTED as insane` or `a ToneMapping getter was not found` →
  the live read failed and the shipped defaults are in effect (the picture is still valid, but
  "live" is not).
- Log says `tone curve online: … m=0.220 l=0.400 …` but GT mode looks *identical* to
  exponential mode at the same knob → `toneMode` is not reaching the shader (constant offset or
  root-signature count), because the two curves differ by 0.1 at x′ = 0.5 and that is visible.
- GT mode with the knob lowered gives snow texture but the mids look **flatter/muddier than EXP
  at matched brightness** → the straight section is not doing what §3 claims; re-run the harness
  before believing the shader.

## 6. Next launch — what to do, and what each outcome means

After the aspect judgement (still first on the board), at the sunlit-snow spot of
`Screenshot 2026-09-02 230446.png`, source MIRROR:

1. Read three log lines: `swapchain format=… -> tone-curve toe=…`, `tone curve online: …` (the
   numbers should be 0.220 / 0.400 / 1.00 / 1.33 / 1.00 and a white point near 5.6 outdoors), and
   `mirror compositor: grading=GT-CURVE …`.
2. Press numpad `5` three times, watching the snow and the village each time: **GT → EXP →
   EXP-frozen → GT.** Same knob in each. Expected: GT a touch brighter, snow no better yet.
3. In GT mode press numpad `2` until the snow shows texture (expect 2–4 presses). Now compare the
   village against the game view.
   - **Village still reads like the game, snow has texture** → the row is done; note the knob.
   - **Village goes dark/muddy before the snow comes back** → press `5` to EXP and lower *its*
     knob the same amount; if EXP is *worse* at matched brightness the curve helped but the
     range is too wide for any global curve (§5 last point); if EXP is *no different*, the GT path
     is not active (§5 diagnostics).
4. Optional, only if 3 went well: set `tone_wp=1` in `reframework\re_scope_vr_settings.txt`,
   walk indoors and out, and watch whether the scope now follows the game's brightness *change*
   between zones better or worse than before. Either answer settles a hypothesis.

## 7. Credit

The curve is Hajime Uchimura's GT tonemap (CEDEC 2017, "HDR Theory and Practice"); the
implementation here is our own from the published formula. The observation that the game's own
curve is three-section and already dumped came from the `/gr` sweep of 2026-09-03.
