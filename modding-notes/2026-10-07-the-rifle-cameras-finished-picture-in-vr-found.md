# The rifle camera's finished picture in VR: found (2026-10-07 night, home PC, Fable, Tefa in the headset)

**Tefa's ask:** the scope should show the game's own colours, with nothing to tune, following the game's brightness and
hue by itself. Since 2026-09-26 the VR scope has taken the rifle camera's picture BEFORE the game's grading (the authored
float target) and rebuilt curve, exposure and colour table itself -- the outdoor blue (10-03) is that rebuild falling short.

## What was tried, in order `[verified-live 2026-10-07, Tefa wearing]`

1. **The shared PrepareOutput texture, write #1 and write #2** (`clonevrlook off` + `clonepo 1` / `clonepo 2`): both show
   the MAIN view -- the picture follows the head, flickers (the two eyes taking turns), very bright. So in VR that texture
   never carries the rifle camera's picture; the 09-26 verdict was right for a different reason than the backbuffer
   fallback `[disproved 2026-10-07, n=1 each]`.
2. **A render-target census** (plugin, `clonecensus`): one frame's RENDER_TARGET exits listed. First two builds copied the
   textures on the game's own command lists inside the barrier hook and **froze the game twice** (23:08, 23:13: one present
   a second); the third build (list only, a reference kept per texture) runs clean. The list (46-51 exits a frame):
   - 2688x2880 fmt 28 x3 + fmt 27 (UAV): the per-eye output (the upscaler's).
   - **1559x1670: the main eye's pipeline**, twice per frame (fmt 29 LDR, fmt 26 HDR work buffers, fmt 13, fmt 24, and
     **fmt 87 = the shared PrepareOutput texture, exits 18 and 34** -- the two writes of step 1, both the main's).
   - **1920x1088: the rifle camera's pipeline** (its RenderOutput target size): fmt 13, fmt 24, **fmt 29**, fmt 26 x9 --
     and **NO fmt 87**: the clone's PrepareOutput stage writes nothing in VR. That is why the picture was never in the slot.
3. **`clonecensus pick 31`** (the 1920x1088 **fmt 29 = R8G8B8A8_UNORM_SRGB**) on the glass through the proven mid-frame copy:
   Tefa: *"the colours were better. still not right, but the overly blue was gone"* -- and it follows the RIFLE. **This is the
   rifle camera's finished (graded) picture** `[verified-live 2026-10-07, n=1, Tefa]`. "Glitchy" came from the hold (see
   below), not from the picture.
4. **`pick 29`** (1920x1088 fmt 24 = R10G10B10A2): pink/cyan quadrants -- a data buffer, not a picture (Tefa's screenshot).

## Two bugs met on the way (both fixed in source, the second not yet in the installed build)

- The census copy froze the game: never copy many textures on the game's lists inside the barrier hook. List, then copy ONE
  through the single-resource path.
- A pick was let go 15 presents later: the poll re-read the file with the same `n`, saw `po=0` and took the release branch.
  Tonight it was held by rewriting the file with a new `n` every 0.15 s (five source swaps a second = the glitching).
  Fix: with `pick=` in the file the poll must treat `po` as "kept".

## Installed now

Steam game: plugin `f39db797` (list-only census + pick), `re8_scope_cam_fix.lua` with `clonevrlook`, `clonecensus`, the
`VR_FINISHED_PICTURE` flag (still false: the VR path is the float target + VR look, as shipped). Backups of every build
swapped tonight: `D:\RE Village REFramework builds\deploy-backups\_archive-2026-10-07-*`.

## Next (desk first, then one headset launch)

1. Keep a pick (the release bug above). Then make it automatic in VR: after the rifle camera is made, run the census once,
   take the 1920x1088 fmt-29 texture of the clone block (the only fmt-29 at the clone's size), feed it to the mid-frame copy;
   `clonevrlook off` with it (the VR look is the float target's crutch). Fall back to the float target if it is not found.
2. "Still not right": the 8-bit path shows the copy at unit gain through an SRV of the copy's own format; fmt 29 is sRGB-typed,
   so the sampler decodes it to linear and the shader may encode again (or not) -- check the 8-bit branch of the shader
   against what flat's fmt-87 (UNORM, not sRGB) copy needed. Also the clone's own ToneMapping/AutoExposure now matters
   (`clonetm ae 0` pinned) and its FOV/aspect at 1920x1088.
3. Tefa judges outdoors + library door + merchant; if right, ship (Steam install, builds repo), and the colour knobs retire.
