# theHunter: Call of the Wild VR: a measured scope design, and a flicker post-mortem worth reading first

**Found:** 2026-09-23, `/gr` estate sweep, through phunkaeg's *VR Modding Playbook* (`sources.yml` →
`theHunterCotW-VR`, harvested there as ch02 `#scoped-optics` / pattern HAND-007).
**Source:** vaas993, *theHunterCotW-VR* — <https://github.com/vaas993/theHunterCotW-VR> (GPL-3.0,
last commit 2026-09-10). Documents read on GitHub: `docs/SCOPE_ONE_EYE_DESIGN.md`,
`docs/THE_FLICKER_POSTMORTEM.md`, `docs/VR_PRIOR_ART_LESSONS.md`. Nothing copied.

## What it is

A native-stereo OpenXR mod for theHunter: Call of the Wild (Avalanche's Apex engine, D3D11). It is a
hunting game, so its author spent real effort on **rifle scopes in VR**, and wrote it down with
numbers.

## 1. The scope problem, measured

A real telescopic sight has an exit pupil that only one eye fits into. A VR scope has none, so both
eyes see the magnified picture from their own positions. In their build the reticle sits at zero
disparity while the magnified world's disparity is multiplied by the magnification `[reported]`:

- at ~2.75×, reticle-to-target disparity of **30 / 12 / 6 / 4 arcmin at 20 / 50 / 100 / 150 m**,
  against a comfortable fusion limit of roughly 6–10 arcmin, so at most ranges either the reticle or
  the target doubles;
- a reticle centred on one eye puts the shot **32 mm to the side at any range and magnification**,
  a fixed error that never looks like a scaling bug.

**Their decision:** while scoped, render **both eyes from one camera** — the one the bullet leaves
from — faded in over ~120 ms, behind a switch that is off by default. They **rejected** drawing the
scope to one eye only (it causes binocular rivalry, flickering at 0.5–2 Hz) and **rejected**
blanking the other eye (dimmer view, re-fusion cost when the scope drops) `[reported]`.

**Their test that needs no theory:** with the feature on, close the left eye and fire, then close
the right eye and fire at the same mark. Both hits must land on the same vertical line; if they do
not, the two eyes are still getting different angles `[reported]`.

⚠️ **How far this transfers is `[hypothesis]`.** Our scope draws its picture onto a lens/mirror in
front of the eyes rather than magnifying a stereo world, so the disparity numbers above may not apply
as written. What likely does transfer: the one-eye-then-other-eye shot test as a cheap
discriminator for our per-eye aim work, and their reason for not rendering the scope to one eye.

## 2. The flicker post-mortem: "same object, same path"

Their scope's glass and its mask disc flickered against each other every few seconds `[reported]`.
Four wrong theories came first: a slider that showed `0.00` for small non-zero values (so "3D off"
was never really off), a counter that saw only one of seven failure exits, a counter placed in a
condition rather than the body, and four attempts that widened a fix and made it worse.

**The real cause:** glass and mask were **one object drawn twice by two different routes** — one
through a constant buffer that could silently fail to resolve, one through the rasterizer, which
could not. On a frame where the constants failed, the glass stayed put and the mask moved. **Fix:**
send the mask down the glass's route. Their general rule: *if two draws are the same object, they
must take the same code path — not equivalent paths, the same one.*

**Why it matters here:** this project has chased a one-frame flicker and per-eye "hops" on the scope
picture (modding notes 2026-09-16 and 2026-09-16g). Before another knob is added, it is worth
checking whether any two things that should move together — lens, glass, mask, picture, crop — reach
the screen by different routes, one of which can fail quietly `[hypothesis]`.

## 3. Smaller leads from their prior-art notes `[reported]`

- **Expensive insets refresh at a divisor** (Halo MCC VR: `scope_refresh_divisor = 3`) — a cost
  lever for the scope render.
- **Scope as its own physical panel, placed in metres** (KisakCOD-VR: forward/left/up offsets, a
  24 mm radius, 1024 capture).
- **Any value that changes between eye 0 and eye 1 in the same frame is instant double vision** —
  their ramp is advanced once per real frame, never per eye pass.

## Credits

vaas993 (theHunterCotW-VR); phunkaeg (*VR Modding Playbook*); the Halo MCC VR and KisakCOD-VR authors
as cited inside vaas993's notes.
