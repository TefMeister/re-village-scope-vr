# 2026-09-21 19:52-19:58 -- the first time the flicker measure has ever read anything

Home PC, Tefa in the headset, plugin `b65387e2...` (dossier 9ck), scope at 1080p.

Tefa: *"should be a few minutes and it's about 20 flickers, some stronger than the others and at random
intervals. PICTURE-TEST-2-HEAD-ONLY.bat produced no jitter and warped the picture inside the scope, it
didn't move left and right like it did when we were working on it a week or so ago"* `[reported 2026-09-21]`.

`hold-and-rate.txt` `[verified-live 2026-09-21]`:

- **The measure works.** `avg` 0.0015-0.047 (was 0.0000 in every session since 09-16), no
  `COULD NOT BE MAPPED` line.
- **18 spikes in 3.5 minutes against ~20 flickers counted.** Six of the 18 (19:53:15-19:53:19) fall
  inside `bringup`, before the rig was finished, so about 12 are play; the wearer's extra ones are the
  *"some stronger than the others"* -- weaker than the 0.08 threshold. Spike sizes d = 0.08-0.23 against a
  running average of 0.01-0.03. **So the flicker IS in the picture we compose, before our blit** --
  9z's own discriminator, answered at last -- and `hold 2` finally has a number to act on.
- 15 of 18 spikes read `P20=+0.243`, 3 read `-0.243`: the eye phase is not a clean discriminator.
- **Rate:** in every one-second line after bring-up the scope picture CHANGED on every present and the
  camera rotation changed on every tick (72 of 72 at full speed). Nothing is renewed at half rate.
- **With `cropfollow 0` the wearer saw NO jitter.** So the stepping is not in the source picture and not
  in the head pose's rate: it is made by the CROP PLACEMENT. Next: compare the pose the crop is placed with
  against the pose the mirror was actually drawn with, per frame (dossier 9cl).
- Cost of `hold 1`: 66.1 fps average with it on (n=298 s) against 71.3 after it went off (n=74 s).
