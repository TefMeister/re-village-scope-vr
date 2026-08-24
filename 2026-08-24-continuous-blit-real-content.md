# Continuous scope-image blit into the proven engine target

Same-day follow-up to the RT-backing breakthrough. That session proved the mechanism with a
one-shot checkerboard; this session makes it real — the finished per-frame scope image
(already fully rendered: magnified crop, vignette, reticle) now gets written into the
engine's own material-bound render target continuously, via a real GPU draw sized to the
target's actual resolution, since a straight byte copy can't handle the size difference
between our 480x360 render target and the engine's own texture.

Also fixed a real problem the WIN session's fix would otherwise have hidden: the VR
on/off guard used to gate the whole per-frame pipeline, including drawing our own scope
image in the first place — fine when the only consumer was the flat 2D overlay (which
genuinely needs to stay off in VR), wrong now that there's a second, VR-safe consumer
(the in-world material bind) that would have gone dark in VR for no good reason. The
guard now only covers the flat overlay.

**Verified:** clean build, clean load on the dev PC (hooks install, GPU init, stable,
no crash). **Not yet verified:** the actual continuous-write path itself, since it only
activates once a scoped weapon is equipped — this dev PC's save hasn't reached real
gameplay yet. Also surfaced, not yet solved: even once the display mechanism works, the
image content itself is still sourced from a backbuffer/mirror capture, which is a known
weak point for true VR correctness (separate from today's fix).

Full detail: `re-village-scope-vr-dev-archive/recon/2026-08-24-continuous-blit-real-content/`.
Code: `re-village-scope-vr-staging` (`faf8635`).

**Next:** reach real gameplay with the F2 scoped rifle, press F4 (unchanged from the WIN
session), confirm the glass shows the live scope image instead of a static pattern.
