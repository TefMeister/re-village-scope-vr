# 2026-09-26 night — The rifle camera's brightness: what did not work, and the lead

Tefa asked whether the washed-out outdoors is the same as the golden veil. It is the same family: a second camera view that
misses part of the game's own grading. But it arrives by a different road.

Tried, live, one launch each: matching the light meter (it already matched), matching auto-exposure, switching the rifle
camera's own tone mapping, colour step and bloom off (no change at all, which is the telling part), a float render target
(still cut off at 1.0), and the old mirror-era trick of grabbing the engine's high-range buffer (wrong buffer: flat grey).

Reading: whatever lands in our render target is the picture **before** the game grades it, clipped at white. praydog's
VR mod never uses a render target for its second camera; it copies the finished picture out of that camera's last stage
(PrepareOutput). That is the next thing to build, after reading his code statically.

Detail: `dev-archive/recon/2026-09-26o-rifle-camera-exposure/`, dossier 9da.
