# Compositor night + the three Mirror truths (2026-08-27 evening → 2026-08-28 ~00:15, home PC)

User decision at session start: the dev-PC handoff is overridden — **the compositor
work happens on the home PC** (toolchain was proven here on 2026-08-22; built clean
first try again tonight).

## Built and verified: the plugin compositor (staging `45fb62b`)

Mirror RT as the scope-image source. Second latch phase (the matching 1280x7xx
allocation that arrives AFTER our own target; pointer inequality = identity;
numpad `.` re-arms). `ps_main` gained an exposure tonemap (`1-exp(-c*e)`) — the
mirror renders raw HDR (`fmt=26` = R11G11B10_FLOAT, confirming the 2026-08-26
finding); flips ride the crop extents as negative halves. numpad `-` cycles
AUTO/BACKBUFFER/MIRROR; in MIRROR mode numpad 8/2 = exposure, 4/6 = flips (modal —
the numpad is otherwise mount calibration). Device reset now drops both latches.

**Proof:** screenshots 03 (castle, first tonemapped output) and 08 (**the Duke,
upright, correctly graded, aim-following — near-final scope image quality**).

## The three Mirror truths (each screenshot-backed)

1. **`via.render.Mirror` ignores its host's TRANSFORM entirely.** Rotation: pitch
   swept +45..-127 and yaw typed to 45 with the rig quaternion PROVEN turning in
   the new heartbeat read-back — image indifferent (07). Position: teleport ±50m —
   indifferent. Attach-time pose: reattached while the rig rode the rifle (D
   before R, order log-verified) — still the castle. The 2026-08-24 note
   "steerable only via the host transform" was an untested inference and is WRONG.
2. **The pane comes from the host's MESH.** Meshless rig → fallback plane parked
   far away ("static far away things" — the user diagnosed it before we did).
   Rifle-hosted → live nearby content that follows aiming (the Duke tonight, the
   Duke yesterday, the factory room on 08-24). A frozen pane still yields a
   moving picture (reflections depend on the viewer) — which is what made the rig
   look alive for three sessions.
3. **Mirror SELF-DISPLAYS on its host's mesh.** It is bathroom-mirror tech: the
   engine paints the raw reflection onto the host's own surfaces. On the rifle
   that painted the raw (upside-down, half-cut) reflection across the scope glass
   — bypassing the texture slot, ignoring F9/flips, present before any bind.
   Screenshot 10 is the decisive frame: **two authors on one glass** — our
   corrected image upright in the material's small UV circle, the engine's raw
   wash behind it.

## Bugs found (fix before next session)

- **Teardown kills the plugin's rendering:** destroying the rig+mirror threw an
  exception in `on_present` (`APIProxy` 23:26:34) — most likely GetDesc on the
  freed mirror resource — and rendering stayed dead for the session. Guard: on
  teardown/invalidation, drop `mirror_latched` before touching the rig, and/or
  validate the pointer per frame.
- **Glass and PiP disagree on vertical orientation** (the lens material V-flips):
  they can never both be upright while one flip constant drives both. Split into
  a separate blit-pass flip for the glass copy.
- Log diagnosis kept drowning in the m6 heartbeat (~2s cadence) — lower it or tag
  event lines distinctly.

## Open

- Clip tear crosses the frame at some aim angles even at max zoom (09) — welded
  pane angle. Expected to be solved by the next experiment, not by cropping.
- The whole flow is many manual steps; automate once geometry is settled.

## NEXT SESSION OPENER — the rig-with-a-mesh experiment

Give the rig a mesh (`createComponent(via.render.Mesh)` + a small mesh resource
via `create_resource("via.render.MeshResource", ...)` — pick any tiny prop .mesh
from the pak list), THEN attach the Mirror to it. If truth 2 holds, the pane
becomes steerable (the pitch/yaw sliders already exist and are proven to turn the
rig); truth 3 stops mattering because the engine's wash paints onto OUR mesh
(place it out of view — or exploit it directly as an in-world display). Glass
stays bound to the plugin holder (numpad `*`), UV stretch now POSITIVE
(~0.1, 0.1 — compositor owns the flips), `Reticle_Emissive` for brightness.
