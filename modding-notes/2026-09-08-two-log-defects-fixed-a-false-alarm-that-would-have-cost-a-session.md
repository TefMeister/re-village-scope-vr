# Two log defects fixed: one line contradicted itself, the other accused the derivation of a bug it did not have

**`/pd`, home PC, 2026-09-08. THE GAME WAS NOT LAUNCHED AND NOTHING HERE HAS BEEN RUN.**
`[compile-verified 2026-09-08]` — VS2022 Release, clean build, `re_scope_vr.dll` produced.

Closes the `[PD]` row queued 2026-09-06 after the VR launch ("two log defects found by using
them"). Both are in `plugin/src/Plugin.cpp`. Neither changes what the compositor does — they change
what it *tells you*, which is the part that was sending sessions the wrong way.

## (a) The latch line contradicted itself

It read `MIRROR SOURCE latched (1280-wide): 2560x1448 fmt=29` — a hardcoded label sitting beside
the real dimensions it disagreed with `[measured 2026-09-06]`.

The label was never true by rule, not merely out of date: `looks_like_mirror_target()` accepts
several known `.rtex` sizes, and 1920×1080 was added on 2026-09-05 for the scope-resolution row. So
there is no single width to name.

**Fix:** drop the claim. The dimensions are already printed one field along, so the line now reads
`MIRROR SOURCE latched: 2560x1448 fmt=29 …`. Replacing one hardcoded width with another would have
re-created the defect the first time the accepted-size list grows again.

## (b) ⚠️ The one that mattered: `lua-pane DISAGREES` accused the derivation under ordinary motion

The `crop-follow:` line compares this plugin's pane normal against the Lua's and prints
`agrees` / `DISAGREES`. When steering is off, the follow-up line asserted:

> "Steering is OFF, so this is a DERIVATION error (slider values or the pitch/yaw convention out of
> sync) — the crop is on a wrong plane; do not tune, fix."

**In VR on 2026-09-06 it fired at 13.0° and then 3.5° seconds apart with nothing wrong**
`[measured 2026-09-06]`.

### Why it misfires, and why it is not a threshold problem

The two sides are **sampled at different rates**. The Lua publishes its pane at roughly 2 Hz; the
plugin rebuilds it every tick. Under rifle motion the two therefore describe **different instants**,
and the angle between them is dominated by staleness rather than by any error in the derivation.

That makes it a false alarm of the worst kind: it names a specific cause, tells the reader not to
tune, and would send a session hunting a bug that is not there. Raising the 3° threshold would not
fix it — under a fast enough swing any fixed threshold trips, and under a slow enough one a real
derivation error hides.

### The fix: judge only when the rifle is nearly still, and say when judgement was withheld

There is no timestamp on the Lua's pane to difference against, so this gates on **our own** pane
instead. The plugin now measures how far its own pane normal moved since the previous tick
(`deg/tick`) and only issues a verdict when that is `<= 0.35 deg/tick`:

- **still, and mismatch ≥ 3°** → the old warning, now stating the measured rate and the threshold,
  and saying explicitly that *staleness cannot explain this*;
- **moving, and mismatch ≥ 3°** → a new, differently-worded line: `NOT JUDGED`, with the rate, the
  reason (the ~2 Hz publish), and **"this is expected under rifle motion and is NOT evidence of a
  derivation error. Hold the rifle still to get a verdict."**
- the inline field in the `crop-follow:` line now reads `moving (not judged)` instead of
  `DISAGREES` in that case, so the one-line summary cannot contradict the detail line.

An unknown rate (first tick, or after a gap) counts as **moving** — withholding a judgement is the
safe direction, and the next tick has a rate.

**The threshold is deliberately loose and the asymmetry is intentional:** it only has to separate
"held still by a human" from "being swung". A false *moving* costs one skipped judgement; a false
*DERIVATION error* costs a debugging session.

## What is NOT established

- **The 0.35 deg/tick threshold is a judgement, not a measurement** `[hypothesis]`. It has not been
  run. It was not derived from the 2026-09-06 samples, which recorded the *mismatch* angles (13.0°,
  3.5°) and not the pane's own rate — the quantity this gate uses was never logged, which is
  precisely why the new lines print it.
- **Timestamping the Lua's pane is the better fix and stays open.** It would let the plugin
  difference real elapsed time instead of inferring motion, and would also make the still case
  rigorous rather than merely plausible. This change is the cheap half of the row's two suggestions.
- Nothing about the underlying pane derivation is claimed either way here. If the crop is on a
  wrong plane, this change does not fix that — it stops the log asserting it when it cannot know.

## The diagnostic that would show this fix is itself wrong

If a real derivation error exists and the rifle is genuinely still, the still branch must fire. So:
**with steering OFF and the rifle rested, a `crop-follow:` line reading `moving (not judged)` is the
failure signature** — it would mean the pane's own rate never settles below the threshold even at
rest (noise in the rifle transform), and the gate is then too tight rather than too loose. The rate
is printed in both branches specifically so that this can be read off one log without a rebuild.

## Deployment

**Not deployed.** The built DLL is at `plugin/build/Release/re_scope_vr.dll` in `staging`. Deploying
was skipped deliberately rather than rushed at the end of a session; the next session should deploy
and `deployed.sh record` it in one step.
