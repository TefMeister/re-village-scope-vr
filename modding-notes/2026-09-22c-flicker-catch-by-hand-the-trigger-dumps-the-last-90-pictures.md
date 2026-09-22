# 2026-09-22 (c) — the flicker, caught by hand: the trigger dumps the last 90 scope pictures (home PC, Fable, NO LAUNCH)

**Built and installed; not yet worn.** Tefa came back to "tackle the flicker". The backwards picture
from the third wear was already undone (drawn pose IN USE, `re_scope_drawpose.txt` = 1, plugin
`7945354b…` was installed) — checked, nothing to do there.

## Where the flicker stood before this session (from the record, nothing new)

- One frame shows a **different picture** (another framing, near things: the rifle, the sleeve, the
  fence); the frames either side agree with each other `[verified-live 2026-09-13, n=2 videos]`.
- It happens on the 8-bit path-bound source too → the pooled-HDR reading is out
  `[verified-live 2026-09-17]`. The pose-copy timing (`posehook`) changed *what* intrudes, not
  *whether* `[verified-live 2026-09-13]`.
- The change measure works since 09-21 but is **not a reliable flicker detector**: 18 spikes vs
  ~20 flickers one run, then **0 spikes vs ~20 flickers** the next (busy scene, the 4× rule)
  `[verified-live 2026-09-21/22]`. `hold 2` (re-show the last frame on a spike) did not remove the
  flickers `[verified-live 2026-09-21]`. At play-time spikes the crop map did not move.
- The five spike captures from the third wear are all wrong-pose pictures; looked at again today:
  every one is a whole-picture change between `prev` and `now` (mean |Δ| 22–27 of 255), which in
  a backwards picture riding the edge of the render says nothing about the flicker.

**The gap:** every knob so far assumed the flicker is in the picture we compose. Nothing has
tested that. If it is *after* our blit (the lens material, the engine's own draw of the lens), the
measure, the hold and the spike dump can never see it.

## Built: the flicker ring (`plugin/src/flicker_ring.cpp`)

- The plugin keeps the **last 90 shown scope pictures** on the GPU (1.25 s at 72 Hz; 480×360
  each, ~62 MB of VRAM while on). One copy per present, into a ring.
- **The trigger is the wearer's "I just saw it".** The `createBullet` hook (already there for the
  scatter cancel) sets a flag; that present reads the whole ring back, and a worker thread writes
  `reframework\data\flicker-ring-N\frame-00..89.ppm` (oldest first, the last = the shot frame)
  plus `frames.txt`, one line per frame: frame number, time, the change measure's `d`/`avg` (with
  `hold 1`), spike/held flags, the latched source pointer, HDR or 8-bit, the map's state and
  centre, the game tick, the eye phase. Up to 4 dumps a launch. No threshold anywhere.
- Control file `re_scope_ring.txt`: 0 off (default), 1 on, 2 dump now. Helpers
  `FLICKER-CATCH-ON.bat` (also `hold 1`) / `FLICKER-CATCH-OFF.bat` (game folder + `mod/helpers/`).
- `spike_dump.cpp`'s readback and PPM writer are now shared (`readback_queue`,
  `readback_write_ppm`); behaviour unchanged.
- `plugin/tools/ring_view.py <flicker-ring-N>` prints, per frame, the mean pixel difference to
  the frame before and after, marks a one-frame outlier `ODD`, and writes a contact sheet.
- Plugin `03f52cc061f1…` built 0 errors / 0 warnings `[compile-verified 2026-09-22]` and
  **installed** (`re_scope_vr.dll.pre-flicker-ring-2026-09-22` kept). Game was not running.

## The test (one launch, Tefa in the headset)

`START-SCOPE`, then `FLICKER-CATCH-ON.bat`. Aim through the scope at something, hold as still as
possible (rifle rested, head still). **The moment a flicker is seen, pull the trigger.** Up to four
times. `FLICKER-CATCH-OFF.bat`. Then `python plugin/tools/ring_view.py "<game>\reframework\data\flicker-ring-1"`.

What each outcome means:

| Result | Meaning | Next |
| --- | --- | --- |
| an `ODD` frame in the ring, ~20–30 frames before the shot | the flicker IS in our composed picture; its `frames.txt` line says what the plugin was doing (map moved? source pointer changed? `d` large?) | fix at that step; the frame itself shows what it is |
| no `ODD` frame, pictures all alike, while a flicker was seen | the flicker is **after our blit** — the lens material / the engine's own lens draw | stop touching the compose path; look at the glass bind and the engine's lens draw |
| `d` tiny on the odd frame while the pixels differ a lot | the change measure is looking at the wrong thing (16×12 luma pass) | fix the measure before trusting any spike count again |

## NOT established

- Whether a shot's own recoil/animation reaches the ring before the trigger frame (it should
  not: the ring holds the frames *before* the shot). If the last few frames look like recoil,
  read the ones before them.
- Whether 90 frames is enough for Tefa's reaction; if the odd frame is always at the very start,
  raise `kRingFrames`.
