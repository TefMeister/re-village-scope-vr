# 2026-09-12 evening — the spin cancel worn four times (home PC `RTX`, `/lm`, Tefa wearing)

Write-up: `modding-notes/2026-09-12e-four-wears-the-spin-cancel-goes-from-snapping-to-half-strength.md`; dossier §9r.

- `headset-frame-cancel-off-crosshair-tilted.jpg` — a Virtual Desktop capture from inside the headset,
  v1 build with the cancel OFF (`mrollk 0`). The crosshair is tilted ~35° *with* the scenery: that is the
  rifle rolled in the hands, which a real scope also does. Our own frame, not game content.
- `mroll-trace.txt` — v1's computed roll sampled once a second with `cropfollow` briefly on: near −134°
  while still, a 26° jump in one second when the pane moved. World-up about a near-vertical reflected
  forward.
- `mroll-trace-v2-v3.txt` — the same readout across the v2 and v3 wears: v2 steady at ±1° but still
  ~−139° (2 Hz pane file); v3 (per-tick normal, verified muzzle axis) reading −7…−37° as the head moves.
- `log-key-lines.txt`, `log-key-lines-v2-v3-wears.txt` — every harness command in order, the bind-time
  `look:` lines (placement fix landing on every launch), latch/rig lines, rifle locks.

Verdicts, all `[verified-live 2026-09-12, n=1 wearer]`: v1 `mrollk 1` spins and snaps, `0` spins only;
crosshair stays put while the picture turns; v2 `mrollk -1` "rotates, then snaps back the right way
up"; v3 no snapping, `-1` over-corrects, `-0.5` less swing with a steady tilt.
