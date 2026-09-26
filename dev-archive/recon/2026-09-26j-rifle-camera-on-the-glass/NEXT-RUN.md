# The next flat run: the rifle camera starts by itself (built 2026-09-26 late by /pd, Opus; plugin a169a870)

New since the run in this folder: the plugin samples only the rows the camera draws (the speckle band, `clone_rows.h`, 9/9);
the clone keeps its eye AT the scope and hides the rifle with a 0.60 m near plane (`clonenear`) instead of pushing through
walls (push default 0); the autostart takes a `clone` word. `[compile-verified 2026-09-26]`, nothing run.

1. Close the game. Set `reframework\data\re_scope_autostart.txt` to `1 1920 clone` (it holds `1` today: the mirror only).
2. Launch → gameplay → draw the rifle. Expect in the log: `autostart: DONE -- rig present`, `4/4 rifle camera queued`,
   `clone_src #… published`, `MIRROR SOURCE REPLACED … 2560x1448`, `autostart: DONE -- rifle camera on the glass`.
3. Glass: the magnified view down the rifle, **no speckle band at the top**, **no front sight** (the near plane).
   If the sight still shows: `clonenear 0.8`; if close walls vanish: `clonenear 0.4`.
4. Put the rifle away and draw again: `rifle camera removed`, then a fresh clone.
5. Brightness: compare the glass with the screen at the same spot; if dim, note it (a gain knob is a one-line add).

Then the aim point (a shot at a mark vs the glass centre), and [VR].
