# 2026-09-27 — The golden glass is beaten

For five weeks the picture inside the scope went golden and washed out outdoors. On 2026-09-27 it was finally beaten,
in one long day with Tefa in the headset, on Opus.

**What it was.** Three things, stacked. The rifle camera's own glow effect (bloom) laid a warm haze over everything. Its
picture has a hard ceiling, and warm-lit snow and sky hit that ceiling in red and green before blue, which leaves yellow.
And our own script, meant to keep the rifle camera matching the main view, copied the main view's brightness and glow back
onto it every tenth frame, undoing every fix, so each test mostly showed the old picture.

**What fixed it.** Glow off on the rifle camera, the rifle camera three brightness steps darker than the main view (our
brightness knob raised to match), and our copy loop told to leave those two settings alone.

**What did not, and is worth remembering.** Our colour code, the lens glass settings, the game's colour chart, copying the
game's grading, and hand-tuned contrast and colour: all measured or worn, none was the cause. The day's biggest clue came
from Tefa's own question, "what else is affected by the scope?", and the last one from a frame-by-frame look at their
video, which showed one good frame in nine.

A bug found on the way: the "finished picture" copy had never been shown at all (a missing flag made the scope fall back
to a crop of the main screen). Fixed, and documented.

Detail: `dev-archive/recon/2026-09-27*`.
