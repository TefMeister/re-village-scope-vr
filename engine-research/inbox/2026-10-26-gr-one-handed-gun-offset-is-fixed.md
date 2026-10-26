# Pointer: the one-handed gun pose adds a FIXED offset, so a tilt that comes and goes is tracking

From `/gr`, 2026-10-26. For the board's `[VR USER]` row "one-handed, the rifle points up by quite a lot"
(2026-10-02; "not seen since, kept open because it comes and goes with tracking"), whose first step is the no-game
read of how praydog's `re8_vr.lua` builds the one-handed pose.

- Answer, from praydog's published source `[inferred-static 2026-10-26]`: hand rotation = game camera rotation x
  controller rotation x a fixed per-hand offset (`RE8VR.cpp` ~339-352); the offset is set once at script start and
  differs between OpenXR and OpenVR; it is not saved to the script's config. Nothing smooths or tracking-checks the
  controller rotation first.
- So on our always-OpenXR setup the offset is a constant and cannot explain a tilt that appears on some launches only;
  the tracked controller orientation is the likelier source `[hypothesis]`.
- Cheap separators, if it shows again: the REFramework menu's "Right Hand Rotation Offset" values (unchanged = offset
  ruled out), or a log of raw controller rotation beside the gun's.
- Full write-up: `external-research/topics/2026-10-26-the-one-handed-gun-pose-is-controller-times-a-fixed-offset.md`.

Suggested board change: mark the row's no-game first step as answered, and keep the row on the tracking side.
