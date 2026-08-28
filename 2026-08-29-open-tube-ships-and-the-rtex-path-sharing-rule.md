# 2026-08-29 (small hours) — open-tube 1× ships; the .rtex path-sharing rule; the mirror's three limits are one limit

Second half of the 08-28 marathon. Two user-verified wins and a wall with a name.

## Shipped: the open-tube zoom cycle (user-designed)
F9's 1× preset now disables the lens materials — the player looks through the REAL hollow
scope tube (true geometry, true parallax; T2's diagnostic state promoted to a feature by
the user re-reading their own screenshot). Magnified presets re-enable the glass and
auto-bind the compositor image. Game-thread serviced, name-narrowed, every write read back.

## The rule that fixed the glass: never give two producers the same .rtex path
`sdk.create_resource` returns the SAME shared engine resource for the same path. The
plugin's blit target and the Lua mirror's render target both used
`movie/rtex/movie_1280_720.rtex` — so the Mirror rendered its raw output straight into the
texture the glass displays, and the compositor (tonemap, flips, reticle) was silently
bypassed. Symptom signature for future recognition: glass upside-down + clip-grey half
while the PiP shows the corrected image. Fix: plugin target → `movie_1170_784.rtex`;
latches identify by width (1170 vs 1280), independent, orderless. RE8's full shippable
.rtex inventory is in Ekey/REE.PAK.Tool `Projects/RE8_STM_Release.list` (~30 entries incl.
1920×1080, mirror_env, recordsys per-character).

## The mirror's three faces are one wall: NO PANE CONTROL
(a) Grading — the mirror feeds pre-tonemap HDR; exposure+emissive can't reconstruct the
game's film look. (b) Clip-vs-zero — sliding the compositor's crop off the clip-plane half
un-zeroes the rifle by the same amount (shots land below the cross); the plane passes
through the rifle, so accuracy and clip-dodging are structurally opposed. (c) Self-
reflection — the flipped muzzle is visible in-frame. Pane control would fix (b) and (c)
outright; it is the linchpin, and it is blocked on the RE8 runtime-mesh-spawn question
(see 2026-08-28 ledger). That research task is now the project's top priority.

Staging: `1f255eb` (open tube) → `1246c8e` (separate rtex + baked look) → `7d09fd2`
(crop slide). Everything runtime-only; one restart restores stock.
