# The Mirror is a bathroom mirror (2026-08-27 evening, home PC)

Full evidence trail: dev-archive `recon/2026-08-27-compositor-and-mirror-truths/`
(ten annotated screenshots). Compositor code: staging `45fb62b`. Session run on
the home PC by user decision, overriding the dev-PC handoff — the home toolchain
built it clean first try.

## What was built

**The plugin compositor works.** The scope image is now sourced from the
`via.render.Mirror`'s render target instead of a backbuffer copy — the Droste
feedback is structurally gone — with an exposure tonemap for the mirror's raw
HDR output (allocates as R11G11B10_FLOAT, confirming the missing-tonemap
theory), flips, and the existing reticle/vignette/zoom all applied. The PiP
showed the Duke upright, correctly graded, following the rifle: near-final
scope image quality, screenshot-proven.

## What was learned — three truths about `via.render.Mirror`

1. **It ignores its host's transform.** Rotation, position, attach-time pose —
   all proven irrelevant by controlled tests (the rig demonstrably turned, per
   quaternion read-back, while the image never changed). The earlier
   "steerable only via host transform" note was an untested inference; wrong.
2. **Its reflective pane comes from the host's MESH.** A meshless GameObject
   gets a far-away fallback pane ("only shows static far away things" — the
   user's own diagnosis, correct before ours). Hosted on the rifle, the pane
   rides the rifle and shows live nearby content. A *frozen* pane still yields
   a moving picture — reflections depend on the viewer — which is what made
   three sessions of rig tests look alive when they weren't.
3. **It displays itself on the host's mesh.** It is bathroom-mirror tech
   end-to-end: the engine paints the raw reflection straight onto the host's
   surfaces, bypassing material texture slots. On the rifle, that painted a
   raw upside-down reflection over the scope glass — underneath which our
   slot-1 texture was displaying correctly all along, in the material's small
   UV circle. The final screenshot of the night shows both authors on one
   pane of glass.

## The lesson worth generalizing

**When two systems can paint the same surface, identify which one you are
looking at before tuning either.** Half of tonight's confusion was adjusting
our pipeline while judging the engine's layer, or vice versa. (Cousin of the
standing provenance rule: test provenance before parameters.)

## Fix list before the next session

- Rig/mirror teardown crashed the plugin's `on_present` (exception caught by
  REFramework, rendering dead for the session) — guard the latched mirror
  pointer on teardown/invalidation.
- Glass and PiP need independent vertical flips (the lens material V-flips);
  one shared constant can never make both upright.
- The m6 heartbeat (~2s) drowns event lines in the log; throttle or tag.

## Next session opener

**Give the rig a mesh, then attach the Mirror to it.** Solves aiming (truth 2:
mesh = pane, and the rig's pitch/yaw sliders are already proven to turn it)
and removes the engine's raw wash from the rifle glass (truth 3: it paints on
the host — our mesh, placed out of view). Glass stays on the plugin's
corrected output (numpad `*`); material UV stretch is now POSITIVE (~0.1, 0.1)
since the compositor owns the flips. The clip tear that survives max zoom at
some angles should die with pane control rather than with cropping.
