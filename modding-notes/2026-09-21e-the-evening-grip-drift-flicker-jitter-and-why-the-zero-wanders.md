# 2026-09-21 (e) — the evening: the grip, the drift, the flicker, the jitter, and why the zero wanders

Home PC, Tefa in the headset on and off from about 17:30 to 20:20, in an ordinary session (no lane
command). Continues `2026-09-21d-…`. The durable versions are dossier §9cf–§9cm; this is the readable
order of events, with what is and is not established at the end of the day.

## What was done, in order

1. **The rifle thrown left when the second hand goes on** (§9cf, §9cg). The VR mod re-aims the rifle along
   the real hand-to-hand line the instant the grip is taken, and steers against a grip point read from the
   body animation every frame, so the first trigger pull after a grip moved the rifle ~4.8°. Both fixed in
   our patched REFramework. Worn twice: *"steering feels good"*, then *"it works :)"* `[reported]`; the
   pre-shot move fell from 4.6–5.1° to ~1.5° on 11 of 12 shots `[verified-live, n=12]`.
2. **The rifle swinging by itself two-handed** (§9ch–§9cj, **PARKED by Tefa**). Virtual Desktop never
   reports an occluded controller as untracked (0 of 365 samples) `[verified-live]`, so a guard keyed on
   that is a no-op. ⛔ My first "relative grip" maths invented steering from the rifle's own rotation; it is
   corrected, with a 25° limit. ⛔ I then told Tefa the big swings were that bug and that tracking "can't do
   that" — withdrawn: they predate the bug by weeks. Last run: asked-for steering averaged 27–36°, which
   points at the design (the reference is taken while the hand is still travelling) rather than at tracking
   `[hypothesis]`. Levers left in the game folder: `GRIP-FRONT-LOCKED/HALF/FULL`, `GRIP-BY-CONTROLLER`,
   `GRIP-SNAP`.
3. **Scope picture size** (§9ci, §9cm). `fn rtex_1920` had never taken — a missing branch in the size
   picker — fixed. By eye 720p, 1080p and 1440p look the same on the glass; 1440p costs a lot of frame
   rate. `START-SCOPE` is 720p now.
4. **The flicker measure had never measured anything** (§9ck): its `Map` asked for 3,072 bytes of a
   2,880-byte buffer `[verified-numerically]`. Repaired. First real run: 18 spikes against ~20 flickers
   counted. `hold 2` (re-show the last frame on a spike) was worn and does **not** hide the flicker
   `[verified-live]`.
5. **The head-turn stepping is gone** (§9cl, §9cm). The crop went from the game thread to `present` as loose
   atomics; it now goes as one whole snapshot matched to the frame. Tefa: *"the picture does not jitter"*
   `[reported, n=1 wear]`.
6. **Why the zero will not stay** (§9cm). It is applied in the RIFLE's frame, so it turns with the rifle's
   cant: the same saved zero read −10.9 / −9.2 as seen at roll +1.0° and −12.0 / −7.7 at −4.4°
   `[verified-live]`. And it is not an arbitrary number: it equals the headset eye's off-centre projection
   (10.0° / 10.2° against a hand-tuned −9.5 / −10.7) `[verified-numerically]`, which belongs to the VIEW.
   A view-frame zero is installed (`ZERO-STAYS-WITH-VIEW.bat`).

## NOT established

- **The view-frame zero has not been worn.** Whether the hit stays on the crosshair while the rifle is
  canted is the test, and it is the first thing to do next session.
- **The flicker's cause is unknown.** Ruled out today: the pooled HDR buffer (already out), a single
  outlier frame that `hold 2` could hide, and the NO-MAP window in the hand-off (real, 6 in 109 s, closed,
  not it). The measure sees it, so it is in the picture we compose.
- **"The world slightly angles"** inside the scope when the head moves — very likely the bore-tilt zero
  standing in for a true off-centre projection `[hypothesis]`. The repair is the exact map taking the eye's
  real projection (`proj 1`), after which the zero should come out near 0 / 0. That path has a history
  (§9ax) and wants a derivation, not a toggle.
- Whether the jitter fix holds on a second day, and which half of the snapshot did it.
- The two-handed drift, parked.
- `grip-no-throw.patch` has not been applied to a fresh clone alongside the mirror patches.

## Installed on RTX at the end of the day

`dinput8.dll` `4262e542…` (grip take, frozen socket, corrected steering, 25° limit, two-source instrument);
`re_scope_vr.dll` `5fc622f3…` (repaired measure, rate watch, snapshot hand-off, view-frame zero option);
zero −10.7 / −9.5 in the rifle frame until `ZERO-STAYS-WITH-VIEW.bat` is run; `START-SCOPE` = 720p.
