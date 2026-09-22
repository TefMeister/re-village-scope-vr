# 2026-09-22 (e) — THE FLICKER IS FOUND: one tick's map is built from the OTHER eye's projection. Eye lock built and installed (home PC, Fable, Tefa in the headset)

## The catch `[verified-live 2026-09-22, n=4 of 4]`

Tefa, standing still, pulled the trigger on each flicker; the ring (note 2026-09-22c) wrote the 90
composed scope pictures before each shot. Read with a threshold relative to the scene's own brightness
(the first pass used a bright-scene threshold and wrongly said "no odd frame"):

| catch | one-frame outlier at k | plugin's `d` on that frame (neighbours) | `P20` on that frame (all other frames) |
| --- | --- | --- | --- |
| 1 | 51 (below the image threshold, but flagged by the number) | — | **−0.174** (+0.174) |
| 2 | 64 and 72 | 0.0256 / 0.0260 (0.003) | **−0.174** (+0.174) |
| 3 | 56 | 0.0261 (0.003) | **−0.174** (+0.174) |
| 4 | 58 | 0.0262 (0.003) | **−0.174** (+0.174) |

In every catch the odd frame is exactly the frame whose per-frame line carries the other eye's
off-centre term. `P20` is `g_cam_P[8]`, the projection the world tick reads off the camera and the
exact map (`sg_compute_P`, `P real`) builds the crop from. The map's centre (`cu/cv`) did not move on
those frames and the source pointer did not change — the whole difference is the projection.

Brightened side-by-side of frames 63/64/65 and 71/72/73 (catch 2): the odd frame is the same scene
at a different framing (shifted, the bright snow patch elsewhere) — the "different picture" of the
09-13 stills, not a rifle intruding.

**So: in VR the camera's projection is swapped per eye. The game-thread read lands on one eye's
projection nearly always and on the other's now and then (thread timing, hence "random"), and for
that one tick the crop is placed for the wrong eye.** The 09-13 "shake (the per-eye projection
alternating, `eye moved`)" was the same thing seen the other way. Every knob since 09-16 (hold, spike
dump, map hold) sat downstream of this read and could only have hidden it.

Also from the catches: the change measure's `d` on the flicker frame is 0.026 — far under the 0.08
threshold, which is why `hold 2` never caught one, and why "0 spikes vs 20 flickers" happened.

## Built: the eye lock (`plugin/src/eye_lock.h`, `world_tick.cpp`)

- Learn the majority eye over the first 30 reads that carry an off-centre term; then **reject** reads
  whose `P[8]` sign is the other eye's — the map keeps the last accepted projection. Symmetric
  projections (flat) are never rejected. Step check: the read is the first step of the tick, the map is
  built from it later in the same tick — the fix sits upstream.
- **Self-proof:** every rejection is counted and logged once a second (`eye-lock: rejected N other-eye
  projection read(s) this second`) — that count should match the flickers Tefa used to see, and with
  the lock on there should be none.
- `re_scope_eyelock.txt`: 0 off (old behaviour), 1 on (default), 2 forget and learn again.
  `EYE-LOCK-OFF.bat` / `EYE-LOCK-ON.bat` (game folder + `mod/helpers/`).
- `tools/eye_lock_test.cpp` 6 cases, all pass `[verified-numerically 2026-09-22]`. Plugin `8c188a22…`
  0 errors 0 warnings `[compile-verified 2026-09-22]`, **installed** (`.pre-eye-lock-2026-09-22` kept),
  archived under the keep-every-build rule.
- `tools/ring_view.py` now uses the relative threshold (4× the ring's own median frame difference).

## The test (next wear)

`START-SCOPE`, play a minute looking through the scope. Expect: no flicker, and `eye-lock: rejected …`
lines appearing at about the old flicker rate. Then `EYE-LOCK-OFF.bat` for thirty seconds: flicker back.
`EYE-LOCK-ON.bat`. If the picture sits differently (zero shifted) with the lock on, the lock chose the
minority eye: `re_scope_eyelock.txt` = 2 relearns it.

## NOT established

- Whether the rejected-read count matches the seen flicker count (the self-proof) — next wear.
- Which eye "+0.174" is (left or right) — does not matter for the fix; the zero was tuned on it.
