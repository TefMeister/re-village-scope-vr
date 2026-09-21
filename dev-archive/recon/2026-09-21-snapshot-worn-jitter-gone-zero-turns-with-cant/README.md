# 2026-09-21 20:13 -- snapshot hand-off worn: the jitter is gone; the flicker is not; the zero turns with the rifle's cant

Home PC, Tefa in the headset, plugin `2d537448...` (dossier 9cl), scope at 2560x1448.

Tefa: *"zero is still off to the left and down. you are right, the framerate is far worse with 1440p and
the quality is pretty damn good at 720p. flickers still there, the picture does not jitter, but the world
still slightly - angles - is the best way i can describe it, it does move the picture in the scope that is
not how it would look normally"* `[reported 2026-09-21]`.

`sync-and-shots.txt` `[verified-live 2026-09-21]`:
- **Jitter: gone, by the wearer's word.** Over 109 s: in step on 5,866 presents, 1 tick ahead on 3, 3+ ahead
  on 267 (bursts). So the matched-tick half barely acted; what changed for every frame is that `(cu, cv, H)`
  now arrive as ONE tick's set instead of possibly a mix of two.
- **Flicker: still there.** The loose hand-off would have shown NO MAP on 6 frames in 109 s -- a real fault,
  now closed, but not the flicker (or not all of it).
- **Zero: NOT the picture size** -- it is off at 1440p too, so 9cl's padded-rows lead is `[disproved 2026-09-21]`
  as the main cause. The shot line says what it is: the saved zero -10.7/-9.5 read **as seen -10.9 up / -9.2
  right at roll +1.0** (17:0x, zero good) and **-12.0 up / -7.7 right at roll -4.4** (now, zero off) -- the
  zero turned with the rifle's cant. Across today's 42 shots on this zero the roll ran -9.8..+9.1 deg.
- 1440p is settled against: *"framerate is far worse"*; 720p *"pretty damn good"* -> 720p is now the default.
