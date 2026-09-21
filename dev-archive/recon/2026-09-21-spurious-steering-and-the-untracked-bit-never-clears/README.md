# 2026-09-21 18:51-18:55 -- first wear of the drift guard: the tracked bit never clears, and MY steering maths was wrong

Home PC, Tefa in the headset, `dinput8` `335c5023...`, scope picture 1280x720.

Tefa: *"the occlusion, it still does that, but it shows that the drift wants to fight the guard now and
starts janking the weapon back and forth"*, then a screenshot: *"this is how bad the drift gets, the
screenshot shows the weapon muzzle pointed at me!"* `[reported 2026-09-21]`.

`grip-watch.txt`, 365 samples at 4 Hz `[verified-live 2026-09-21]`:

- **left LOST 0 of 365, right LOST 0 of 365** -- Quest 3 through Virtual Desktop never clears
  `XR_SPACE_LOCATION_POSITION_TRACKED_BIT`, occluded or not. The guard never acted once.
- hands 25.4 cm apart on average (17.6-37.9) -> 1 cm of position error = ~2.3 deg.
- **`steering` read 30-71 deg with the left hand at 0.2-5 cm/s.** Tracking slide cannot do that (30 deg at
  25 cm is 14 cm). It jumped 0 -> 20 deg in the first half second, while the rifle was being raised.
  That is the 17:4x "relative" maths inventing steering from the gun's own rotation -- dossier 9ci.
- a real slide is visible too: 18:53:07.4 -> 18:53:09.5, steering +10 deg in 2 s at 1.4-4 cm/s with the
  hands 25 cm apart = ~2.2 cm/s of position slide.

Also in this log: the scope ran at 1280x728 and Tefa judged it *"as sharp still ... very nice crisp
picture"* `[reported 2026-09-21]`; 69.3 fps average with the picture on (n=319 s) against 64.7 at
1920x1088 earlier the same evening `[measured 2026-09-21, different scenes]`.
