# The next flat run: the rifle camera down the barrel, with the main camera's exposure (built 2026-09-26 by /pd, Opus)

Built on §9cv (the clone renders once its world matrix is written). New in `re8_scope_cam_clone.lua` (staging `7e2ea82`):
`clonepose bore` (Body joint + lens mount (0, 0.151, 0.099) — the mirror rig's own anchor — pushed `fwd` metres along the joint's
forward axis, camera −Z along it), `cloneaim fwd|flip|axis`, `clonefov` (re-asserted each LockScene), `clonelook 1` (MainCamera's
post-process/exposure component properties copied every 10 LockScenes, praydog's list and skips), `clonescope [fov]` (all of it).
**Not established** `[hypothesis]`: which Body-joint axis is the muzzle (default z, camera looking along it = flip 0), whether 0.30 m
clears the tube, whether the property copy brightens the picture or breaks something.

Fresh launch, gameplay, then:

| # | words | what to look at |
| --- | --- | --- |
| 1 | numpad `.` → `src8 1` → `cropfollow 0` → `clonescope 20` (6 s) | log: "clonepose bore: scope pose at … looking (…)" — the looking vector should be close to the main camera's forward when aimed straight; "clonelook 1: copied N" |
| 2 | glass screenshot + numpad `+` | the wall ahead, magnified, brighter than §9cv's |
| 3 | if the glass shows the back of the room / the player: `cloneaim flip 1`; if sideways / up: `cloneaim axis x` or `y` (and flip) | the axis/flip that shows what the rifle points at |
| 4 | if the scope tube/barrel is in view: `cloneaim fwd 0.5`, `0.8` | the smallest push that clears it |
| 5 | walk and strafe; `clonelook 0` vs `1` | picture follows; exposure difference |
| 6 | fire one shot at a spot (`ads`, the saved zero words) — `re_scope_shots.log` | where the bullet lands vs the glass centre (the new camera has no zero yet) |

**Reading:** a magnified, correctly lit view of what the rifle points at = the rifle camera replaces the mirror for the picture; the next
job is the glass hookup (catcher on the clone's target without numpad `.`, crop-follow off by default), then zero and VR.
