# 2026-09-12 first worn win — `retdepth` A/B and steering `model 0` (home PC `RTX`)

Log excerpts from the 15:10 launch, Tefa wearing, Claude driving only the two command files.
Write-up: `modding-notes/2026-09-12d-first-worn-win-the-disc-sits-still-and-the-gun-steers-the-picture.md`.

- `log-key-lines.txt` — the bind-time `look:` lines (both lens materials: `Reticle_Depth_Min`
  authored 0.388 → 0.000, `_Max` 500 → 0.000, `EyeDistortionRange` read as the float4
  `(0.1, 0.3, 0, 0)`), every harness command in the order sent, the latch/rig lines, the
  `retdepth -1` restore line.
- `crop-follow-samples-every-20th.txt` — every 20th once-a-second `crop-follow:` line across the
  session, for the pane normal under `steer 0` (≈ −Y), `model 2` (within ~6° of −Y) and
  `model 0`.

Verdicts, all `[verified-live 2026-09-12, n=1 wearer]`: `retdepth 0` stops the disc sliding,
`retdepth -1` brings it back, `retdepth 0` again stops it; `cropfollow 0` shows the horizontal-
mirror signature (yaw follows the head, pitch inverted); `model 2` no change; `model 0` the gun
steers the picture and the picture rolls with head and gun movement, not with head tilt.

Game content: none. These are our own log lines.
