# DISPROVED: the projection at that hook does not draw the scope picture

**2026-09-19, home PC (RTX), live, wearer present.** The clean negative that ends the evening's
main line of work, and takes a premise from §9aq with it.

## The test and the result

`VR_MirrorProjectionShout` halves `m00`/`m11` inside the mirror window, **doubling the drawn field
of view**. Not a nudge — if that projection drew the scope picture, the picture would visibly pull
right back.

Tefa, having toggled it: **"no change, picture looks the same with it on and off."**

The log confirms every part of it was a fair test `[verified-live 2026-09-19, n=1]`:

| Check | Evidence |
| --- | --- |
| the scope picture was live | `mirror=1 src_w=2560` on the frame lines throughout |
| the source was the real one | 2560×1448, latched and upgraded to raw-HDR at bring-up |
| the toggle genuinely moved | `m00` 0.4924 → 0.9848 → 0.4924 across the test |
| the hook was firing | 42,600+ steering writes logged |

**So: `VR::on_camera_get_projection_matrix`, inside the mirror window, is called, and what it
returns is not what the scope picture is drawn with.** `[disproved 2026-09-19]`

## What this kills

- **The steering fix (§9aq fix (1b), §9at, built today).** Dead at this site. The code, the build
  and the switch scripts all work exactly as designed and change nothing that matters.
- **The exemption as a lever (§9l, built 2026-09-12).** Same site, same window. Its build has
  carried `TESTED-swing-unchanged` in its own filename for two weeks — that was this same result,
  unrecognised.
- ⚠️ **The PREMISE of §9aq.** Its argument opens with *"the mirror is drawn at the HMD eye's field of
  view, 90.88°"*, read from **this getter** `[verified-live 2026-09-12, n=1]`. That reading is now
  known not to describe the scope picture. The clamp onsets (+38.71° / −49.09°), the sharpness
  table, the one-eye band — all of it was arithmetic about the wrong thing.
  The one-eye band was separately **not observed** (both eyes smear, 2026-09-19), which agrees.

**The arithmetic in §9aq was never wrong.** Every check in `mirror_fov_check.cpp` still passes. It
was correct reasoning about a matrix that turns out not to govern the picture. Worth keeping in mind
that 20 passing numerical checks bought no protection here at all: the tool verified the maths, and
the maths was never the weak part.

## The thing that should have been noticed sooner

Two builds, two weeks apart, both writing this getter inside the mirror window, both firing, both
changing nothing — and the first one's null result was recorded **in its own filename**. Today's
build was made without going back to ask why that said "unchanged". The cheapest test available all
evening was reading a filename.

## What is still true, and where this goes next

- **The smear itself is unexplained again.** It is real and reported repeatedly: the picture
  stretches and streaks when the rifle is held well off to one side.
- **The plugin crops a window out of a 2560×1448 texture** that the game's own mirror pass renders.
  `src_w=2560` says the plugin has the right texture. What sets *that* pass's projection is now the
  open question, and it is not this getter.
- ⚠️ **A crop-side fix can only make the failure graceful, not remove it.** If the frame is fixed and
  the crop must follow the bore, then past some angle the wanted content **was never rendered** —
  nothing the crop does can invent it. §9aq's fix (2) (clamp gracefully) becomes the realistic
  ceiling until the real projection lever is found. This is the part worth being clear-eyed about
  rather than optimistic.
- **Next, and it needs no game running:** find what actually determines the mirror pass's
  projection — the `via.render.Mirror` component's own fields, the scene layer's camera, or
  something the engine sets before the layer draws. Static work, and it is the only route back to
  removing the fault rather than softening it.

## Housekeeping

The steering code stays in the fork and in `mirror-steering.patch`, **clearly marked as disproved**
rather than deleted: it cost a build, it is the evidence for this note, and `SHOUT` is a reusable
way to ask "does this projection reach that picture?" of any future candidate site. It must never be
shipped on, and nothing new should be built on top of it.

Credit: **praydog** (REFramework), **gmankab** (the `pd-upscaler` fork).
