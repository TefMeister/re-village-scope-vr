# 2026-09-27 15:20–15:29 — the golden VR glass: Tefa's headset test, then two remote tries

Supersedes: dev-archive/recon/2026-09-27-golden-outdoors-static/README.md §"Two findings", first bullet ("the source in VR
is NOT clamped at 1.0"). It is clamped. The rest of that file stands.

## Tefa's test (outdoors, in the headset)

- *"everything is still golden outside, 2 made it brighter and 0 made it bluer, but the goldenness of it still stays"*
  `[reported 2026-09-27]`.
- The numpad + probe (15:22:15) read the rifle camera's float target: **max 1.00, block averages 0.45–0.99, most blocks
  above 0.9; the darkest block RGB (0.59, 0.43, 0.22)** `[measured 2026-09-27, n=1]`. So in VR too the picture arrives
  clipped at 1.0 and warm. My static inference that it was not clamped was wrong: I assumed the glass shows our output
  as-is, but the glass is part of the world, so the main camera's own exposure and grading act on it afterwards.
- Numpad 2 lowering our gain made the glass BRIGHTER to Tefa. Fits the same picture: the scope fills much of the view,
  so a darker glass makes the game's eye adaptation brighten everything, the glass included `[hypothesis]`.
- EV during the walk: 3.00 outdoors, 2.89 then 2.00 at the indoor zone changes. So EV does follow in VR; the
  "EV stuck at 3" worry is withdrawn.

**Conclusion:** the gold is baked into the clipped source. Nothing after the clip can take it out; the fix has to act
before it. That is the `clonetm ev` lever (staging `d2fb794`), which is therefore the right one after all.

## The remote tries (the game still running, Tefa out of the headset)

- `clonetm` read: clone AutoExposure 2 (Disable), EV 3.0, **PreTonemapRange 1.0 on both** (the clip level's likely name).
- `clonetm ptr 16` read back **0.0**; `clonetm ptr 1.0` read back 1.0. `clonetm ev 5` read back **-0.0**.
  **Cause: an integer typed in the command reaches a float setter as 0; a decimal works** `[verified-live 2026-09-27, n=2]`.
  Fixed: the `ev` and `ptr` pins now always pass a float (`+ 0.0`), test suite passes, installed.
- The game closed at 15:28:30, just after the EV-0 write: **Tefa quit it** `[reported 2026-09-27]`. Not a crash.
  The corrected `clonetm ev 5.0` never reached the game.

## Next (in the headset, outdoors, scope raised)

Harness lines into `reframework/data/re_scope_cmd.txt`, ALWAYS with a decimal point; the probe is `107` into
`reframework/data/re_scope_vr_keys.txt` (numpad +, works only while the scope picture is up):
1. `clonetm ev 4.0` → probe → Tefa: still golden?
2. `clonetm ev 5.0` → probe → same question. Golden gone and the probe max below 1.0 = the fix; then bring the
   brightness back with numpad 8 and make EV follow the game's (clone EV = main EV + offset, every frame).
3. If EV changes nothing on the probe: try `clonetm ptr 4.0` (is PreTonemapRange the clip?).

Settings changed by Tefa's test and saved: `exposure_gt` 1.95 → 0.998, `wb_amount` 1.0 → 0.5. Left as they are until the
fix lands; the brightness gets re-tuned then anyway.

## Second headset round, 15:38–15:48 (Tefa outdoors, scope up; Claude sending the lines)

- `clonetm ev 4.0` read back 4.0; probe before/after: min 0.29 → 0.13, darkest block (0.93, 0.63, 0.29) → (0.55, 0.39, 0.26),
  **max still 1.00** `[measured 2026-09-27, n=1]`. Tefa: *"still golden, a bit darker i think"*.
- `clonetm ev 6.0` read back 6.0 (the probe did not fire: the scope was down while Tefa typed). Tefa: *"still golden - it
  is not a setting for brightness or the hue of it, it's something else"* `[reported 2026-09-27]`.
- `clonetm ptr 16.0` read back **1.0**: the game keeps PreTonemapRange at or below 1, so it is not a clip we can lift
  `[verified-live 2026-09-27, n=1]`. EV put back to 3.0.
- **Darkening the rifle camera before the clip does NOT remove the gold** `[reported 2026-09-27, n=2 steps]`. The
  "darken before the clip" lever is closed.

Also seen: twice the game closed ~1 s after an OpenXR "interaction profile changed" event while Tefa was out of the game
view typing; the first time Tefa had quit it, the second is unexplained `[hypothesis: leaving the game view]`.

## Tefa's pointer: "we won by using the prop"

The August golden veil was the 8-bit, clipped mirror picture; it was beaten by taking the mirror's **raw-HDR scene
buffer** (fmt 26, values in the tens, before any clip) and grading it ourselves (dossier §7/§9d). The rifle camera's
float target stays clipped at 1.0 whatever we set, so the translation is the same move: find the rifle camera's own
unclipped scene buffer. `clonehdr 2` (the mirror-era upgrade, applied to the clone) was tried once in FLAT on 09-26 and
gave flat grey (recon `2026-09-26o`); it has never run in VR. That is the next lead, static first.

## Static follow-up, 16:00 (Opus): the August trick, and why the next try is the colour grade

- **The August trick as recorded** (dossier §9d, notes 09-05k / 09-16 / 09-17c / 09-18): the mirror's 8-bit resolve
  (fmt 29) = black sky + golden; the fix was to switch to the mirror's own raw-HDR scene buffer (fmt 26, allocated right
  after it, values in the tens) and grade it ourselves. That buffer exists because a reflection is an HDR texture the
  scene samples; a camera's output is not.
- **Translated to the rifle camera on 09-26 (`clonehdr 2`)**: the next fmt-26 allocation after the clone's 8-bit target
  (1920x1088, 36 ms later) was also clipped at 0.999 and nearly flat — an engine intermediate, not a pre-clip scene
  `[measured 2026-09-26, n=1]`. Today's VR target is also 1920x1088 fmt 26 and clipped. No unclipped copy of the rifle
  camera's picture has been found to grab `[inferred-static]`.
- **So what the rifle camera's picture lacks is not range but the grade.** Darkening it 3 stops kept it golden
  (Tefa: not brightness, not hue). The game's grade lives in `via.render.LDRPostProcess.get_ColorCorrect()`
  (`via.render.LDRColorCorrect`, dumped 08-30), set per area by `app.ColorCorrectController`, which the clone is built
  WITHOUT (09-27 log: `clonemake: 22 skipped: ... app.ColorCorrectController ...`). A fresh LDRPostProcess keeps a
  neutral grade, which also explains why switching the clone's LDRPostProcess off changed nothing on 09-26 `[hypothesis]`.
- **Built:** `clonecc` (read both grades, every getter, DIFF-marked), `clonecc copy` (set the clone's ColorCorrect to
  MainCamera's, re-asserted every 10 LockScenes), `clonecc off`. Test suite extended and passing, all script suites
  pass, installed `[compile-verified 2026-09-27]` (Lua: suite-verified), unrun.

## Next (headset, outdoors, scope up)

`clonecc` (the read: expect DIFFs) → `clonecc copy` → Tefa: is the gold gone? If the read shows no DIFF, the grade
is not the difference and this lead closes.
