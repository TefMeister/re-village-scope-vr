# 2026-09-26 night — The speckle band was the game's film grain

*Opus, home PC, flat, Claude driving, with the background reader. Evidence: `dev-archive/recon/2026-09-26n-the-speckle-is-film-grain/`.*

## Short version

The TV-static band at the top of the rifle camera's picture was the game's own **film-grain effect** (`via.render.RetroFilm`),
copied onto our camera from the main one. It is now left off, and the glass is clean. Outdoors is still far too bright; that is next.

## How

1. **Is it in the camera's picture or in our drawing?** Numpad `+` now also saves both pictures to disk. The static was in the
   camera's own picture, in the last quarter of its rows, and different every frame.
2. **Which copied component?** A new word, `cloneskip`, leaves chosen components off the next clone. Bare camera: clean. Then halves
   of the effect list, then quarters. Leaving out only the film grain: clean. Leaving out only the volumetric fog: still speckled.
3. Film grain added to the permanent skip list; a fresh launch showed a clean glass.

## Exposure (not fixed)

The camera's own picture is pure white outdoors. The reader found three tone-mapping settings that differ from the main camera
(auto exposure, TAA, TAA method); copying them dimmed the outdoor part only slightly. The main camera has auto exposure OFF, so its
brightness is set by something we skip (the game's `app.ToneMapController` is the first suspect).

## Also worth checking next time

The plugin may still flip the picture both ways (a leftover from the mirror); needs a look at stairs or sky on the glass.

## Installed on the home PC now

Plugin e28d975f (numpad `+` also dumps pictures), `re8_scope_cam_clone.lua` with the film-grain skip and `cloneskip`,
`re8_scope_cam_fix.lua` (the reader's `cloneil`/`clonetm`/`clonediff`/`clonecomp`), harness with both. Autostart back on `1` (mirror).
