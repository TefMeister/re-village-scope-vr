# 2026-09-26 — the rifle camera sat at the world origin; moving it did not change the glass

Home PC, flat (no headset: `XR_ERROR_FORM_FACTOR_UNAVAILABLE`), `/lm`-style drive by Claude, Opus.
Words: numpad `.` → `cammake 20` → `camprobe` → `campose 1` → `camprobe` → `camupdate 1` → `cropfollow 0`.

- **Before `campose`, ScopeCam was at (0.00, 0.00, 0.00) while the rifle was at (-100.04, -10.59, -30.08)**
  `[verified-live 2026-09-26, n=1]`. Parenting with `UpdateSelf=false` never moves the camera: the sky-blue
  reading of 2026-09-25 (camera outside the map) is confirmed for the POSE half.
- The catcher latched our 1920 target again (`REPLACED` 1920x1088 fmt=29, then `UPGRADED` fmt=26), and our
  camera owns two Scene layers (view 3 plain, view 2 with the mirror) `[verified-live 2026-09-26, n=1]`.
- `campose 1` put ScopeCam exactly on the rifle's position; `camupdate 1` switched update on; **no takeover**
  either time (primary stayed MainCamera) `[verified-live 2026-09-26, n=1]`.
- **The glass did not change meaningfully with any of them, nor with `cropfollow 0`.** In flat it showed a
  brown/orange blotchy picture with a horizontal smear on the right half, from `cammake` onward — not the
  sky-blue seen in VR last night (`c1..c4-glass.png`; mean pixel change c3→c4 about 2/255) `[verified-live
  2026-09-26, n=1]`. What the brown is, is unknown: a close-up of the rifle/hand from inside the model, or a
  picture that is not ours at all `[hypothesis]`.
- FOV again read 26.23 after asking for 20.

Open questions for next time: is the glass showing OUR camera's target at all (paint it, or clear it to a
known colour)? Does our camera's picture follow the camera once the pose is right (move it a metre ahead of
the muzzle, or turn Ethan)? Why does `cropfollow 0` change nothing?
