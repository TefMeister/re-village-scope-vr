# The aspect fix verified, the GT curve wins on its own, the sky package retired, the scope zeroed (2026-09-04 evening, home PC, flat, Tefa at the game)

Conversational session: Tefa drove the game and reported, Claude read the log and built.
Everything below is `[verified-live 2026-09-04, n=1]` unless tagged otherwise. REFramework
revision on this PC: fork build `76298bd` (`pd-upscaler`, 2026-03-11), plugin API 1.15.0.

## 1. The 2026-09-02 aspect fix: right, and the reticle proved it

- Log line on bind: `aspect: source 1280x728 = 1.758 -> uvHalf u=0.1185 v=0.2083`. Exactly the
  derivation of the 09-02 note.
- Tefa at the well: **"well is the same as in game"**, **"reticle looks absolutely fine"**,
  horizontal field **"doesn't feel too narrow at all, just right"**. The reticle going square with
  no reticle code touched was the free falsification test, and it passed. No zoom-preset tweak.
- The tone-curve live read came up before the well: `tone curve online: triple=1 m=0.220 l=0.400
  … whitePoint min=11.00 max=25.00 range=0.98 (applied)`, swapchain format 28 → SDR toe. The
  defaults were not in effect; the live read works.

## 2. The bind-order guard works, and its ownership check is a false negative

`glass: our bind was replaced … re-asserting` fired on the E press as designed — and then **every
1.36 s for the rest of the session** (47 lines in the first minute). Tefa: **no blinking at all**,
picture steady. So nothing was replacing the bind; `glass_bind_is_ours()` compares the
`getMaterialTexture` read-back pointer against the holder pointer and they differ on this build,
so the guard re-binds needlessly (restore + bind inside one tick, invisible). `[hypothesis]` on the
mechanism, `[verified-live]` on the symptom. Fix for a no-game slot: compare against the pointer
read back immediately after our own bind.

## 3. White balance: default wins

Numpad `0` on a big sky, cycled: **"it looks best at default"** (`wb=0`). Row retired.

## 4. The snow was the atmosphere package, not the curve — and the GT curve alone matches the game

The tone-curve drill went sideways first and then landed the biggest result of the night.

- Tefa's numpad `2` presses ran in the **exponential** mode (the log shows the GT knob untouched
  at 0.134 while the exponential knob fell 0.107 → 0.006): **the village darkened and the snow did
  not change at all** across a 20× exposure range. A tonemap of honest HDR cannot do that.
- The numpad `+` probe aimed at the snow: **source is finite raw HDR**, block averages 1.5–18.5,
  brightest pixel 135.9, nothing infinite; and **our RT's maximum was 0.69** at that exposure — the
  compositor produced no white anywhere, so the white was painted after it.
- Numpad `9` ladder with Claude reading the log live (1.5 → 3 → 5 → 8 → 12 → OFF): the moment the
  package went off, **"snow went dark"**. The atmosphere package was painting the snow. Why its
  mask (source luminance *below* skyThresh) catches raw-18 snow is not understood — `[hypothesis]`
  the sky-fill is not the only brightening term in the package (skyGain / wbStrength).
- Then numpad `5` → **GT-CURVE at the untouched 0.134 knob, package OFF**: **"they look about the
  same, the snow is ok now, the scope picture might be just a tiny bit darker than the game, but
  I'm really not sure"**. And at the mountain view: **"sky looks like it should too"**, screenshots
  `231723` (game) vs `231733` (scope) — **"very similar and completely acceptable"** (rescued to
  `dev-archive/recon/2026-09-04-gt-curve-sky-package-off/`).

**Verdict:** the shoulder row is not just built but right, and it makes the atmosphere package
unnecessary: on the game's own curve the dome that the package existed to light already looks
like the game, at two spots (village well, mountain view). n=2 spots, one evening, one weather.
The package stays in the code, off, until a spot proves it is still needed.

## 5. Zeroing done

Shot on a post: high by ~⅔ of the reticle half-height, a touch right. Numpad `1` moved the wrong
way (mirror arrives V-flipped), numpad `3` the right way; landed at **`cropY = 0.60`** (from
0.50). Shots then "land where I'm aiming"; the residual shot-to-shot scatter Tefa attributes to the
game's own spread, and a post-reload shift he will check against vanilla first. **Two keys added
for this** (staging `066e9ba`): numpad `4`/`6` slide the crop centre horizontally (new `mir_cx`,
persisted), `1`/`3` step 0.01 instead of 0.02; the H/V flips those keys used to toggle are settled
at 1/1 and now live only in the settings file. `cropX` stayed 0.50 — the sideways error needed no
correction after the vertical one.

## 6. Two new defects

- **Resolution.** "Picture in the scope is very low resolution." Cause is structural: the mirror
  is the game's `movie_1280_720.rtex` allocation (1280×728), the magnified patch is ~300 source
  pixels wide, and our compositor RT is 480×360 (which is also where the reticle is drawn).
  Levers, both static: raise the RT; find a larger `.rtex` the mirror can latch instead.
- **Crouched aim: the scope goes through the lens** (open tube, 1x). Measured: standing ADS puts
  the lens anchor at camera-space `(0.15, −0.03, −0.16)` and it locks; crouched aim holds the rifle
  lower, anchor `(0.13, −0.13, −0.09)` — 13 cm below the eye at 9 cm depth, ~3 view-heights outside
  the frustum, `project()` refuses it, no lock. A guard was built (staging `d99663b`: while
  magnified, clamp the anchor into the view) and **did not fire**: crouched aim keeps the hip FOV
  of 51.3°, so the `fov < 45` gate excluded the very case. `[disproved 2026-09-04]` for that gate;
  the clamp itself is untested. **Parked as flat-screen work** — see §7.

## 7. Priority change (Tefa, 2026-09-04 ~00:00): VR first

*"I would like to make this work in VR first and then, when there is time, get it working flat
screen."* The crouch defect is a flat aim-pose artefact (in VR the eye is the headset and the
rifle is where the hands are) and goes to the back of the flat list. The next step is the
existing `[VR]` row: the in-headset pane retune.

## Not established

- Why the atmosphere package brightened raw-18 snow (its mask should not reach it).
- Whether the GT-only picture holds in other weather / indoors / at night (n=2 outdoor spots).
- The crouch clamp itself (never executed).
- Whether the post-reload shift is ours or the game's.
