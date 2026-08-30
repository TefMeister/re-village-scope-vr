# First true scope image — Mirror content on the glass (2026-08-26 ~23:21, home PC)

The screenshot pair the 2026-08-26 evening STATUS entry promised to archive:

- `232107-actual-scene-duke-caravan.png` — the actual scene (the Duke at his
  caravan), for reference.
- `232253-through-scope-mirror-content.png` — the same scene THROUGH the scope:
  a live, right-way-up, recognizable, non-recursive render on the scope's own
  glass. `via.render.Mirror` attached to the rifle as producer, glass slot 1
  (`Reticle_BaseAlphaMap`) bound to the Mirror's holder as display,
  `Reticle_UV_Scale_Offset` negative-scale un-flip + `Reticle_Emissive`
  brightness via the fixed float4 sliders.

Known artifacts, both understood (see STATUS §7 and the ledger):
- half the image grey = the planar mirror's clip plane slicing the view
  (geometry problem → host the Mirror on the controllable rig, not the rifle
  root);
- blown-out lighting = raw HDR without the game's tonemap/exposure pass
  (grading problem → correct at copy time in the plugin compositor's shader).

Script state that produced this: staging `156bf41`
(`re8_scope_m6_mirror_producer.lua`, buttons 2+3 + T4 sliders).
