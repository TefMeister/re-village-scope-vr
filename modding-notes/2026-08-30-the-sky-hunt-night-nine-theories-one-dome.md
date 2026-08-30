# 2026-08-30 (night) — The sky hunt: nine theories, one dome

One evening, one question — *why does the mirror's sky render black?* — chased
through nine numbered theories (SKY v2 → SKY-REG), a game crash, a live
out-of-process memory hunt inside `re8.exe` while the game kept running, and a
string of user observations that redirected the investigation at least four
times. The sky is still black. But every wrong answer died by controlled
experiment, the true culprit is named, and the fix moved to territory we fully
own. This ledger is the whole chain, in order, for anyone who wants to study
how a hunt like this actually goes.

## The setting

The scope image is produced by a `via.render.Mirror` hosted on a runtime-
spawned goat totem (the pane host), rendered into our RT, composited by the
native plugin onto the rifle's lens glass. Working at session start: steerable
pane (baked pose pitch 180 / yaw 90), auto-noclip (the clip-half kill applied
automatically), EV auto-grading. Missing: the sky — absent from the mirror's
render since it was first noticed (field test v3, earlier that day).

## The chain of theories, each closed by its own experiment

1. **SKY v2 — "cull the black dome with the layer camera's far clip."**
   L5 safety read first: the mirror layer's camera **is the main camera**
   (same address). L6 refused to write, max and min slider alike — correctly,
   since cutting that camera's far clip would truncate the real game world.
   *Lane closed by design.*

2. **"The L2 blue background was showing all along, hidden by the old 50×
   brightness bug."** User: "no it was still all black." *Dead.*

3. **SKY v3 — give the layer its OWN camera** (`layer:set_Camera`, a fresh
   `via.Camera` born on the goat with the Mirror's own `createComponent`
   recipe). The swap STUCK — read-back proved the layer runs on our camera, a
   first — but the image froze. User's observation that decoded it: **"it has
   some moving grass in it… swaying in the same spots."** A frozen *frame*
   doesn't sway. This was a live render from a stone viewpoint.

4. **SKY v4 — CAM-TICK** (rewrite the camera's fields every frame) **+ L10**
   (steal a live engine camera). CAM-TICK ran, view stayed stone — but
   **FOV-WOBBLE zoomed the glass live**, proving the layer reads the camera's
   projection fields fresh every frame while the pose stays cached. L10 turned out
   to have nothing to steal: the census says RE8 gameplay runs exactly ONE
   engine camera (plus our orphans). *Property writes don't rebuild the pose.*

5. **SKY v5 — WM-WATCH** printed the verdict every 2 s: the camera's
   WorldMatrix identical to the centimeter for minutes while the goat provably
   moved. RESWAP (re-calling `set_Camera` per frame) changed nothing. *The
   camera itself is frozen; the layer isn't caching.*

6. **SKY v6/v7 — write the cached matrix raw.** M-SCAN (16-float fingerprint,
   object + 0x4000) and M-SCAN2 (depth-1 pointer chase) both found nothing —
   the managed `via.Camera` is ~0x140 bytes of clip/FOV floats, an identity
   matrix, and almost no pointers.

7. **The out-of-process hunt.** Claude attached ghidrust to the *running*
   `re8.exe` (observe mode, read-only — an out-of-process read of a bad
   pointer just fails, it cannot crash the game) and walked the object graph
   by hand: camera+0x10 → the goat's GO/transform block → **at +0xD0 a cached
   4×4 world matrix whose translation row matched the frozen camera pose to
   the fifth decimal.** Bonus insight: the world-matrix cache is only rebuilt
   while the object RENDERS — and the goat stops rendering the instant L7
   puts a camera on it. The user's "the goat disappears after L7" and the
   frozen picture were **the same event**.

8. **SKY v8/v9 — drive that cache from Lua** (`write_float` at +0xD0,
   fingerprint-verified before the first write). The verification **refused**
   — and when the user pushed back ("I did press it, many times"), the log
   proved them right and the earlier "never pressed" claim wrong (a truncated
   log grep). The three-candidate probe that replaced it returned the final
   verdict: none of the reachable objects holds the getter's pose — the
   +0xD0 find was a **sibling copy**, frozen by the same event, not the
   source. *The private-camera lane died here — see the reset below for why
   that turned out not to matter.*

9. **The background-fill theories.** User's far-clip screenshots (550 m vs
   2650 m) proved the slider sculpts the mirror image — mountains culled and
   restored — **but the sky stayed black even at 550 m**. Then the HDR
   ladder: `set_BackgroundColor` verified-set to (1750, 2750, 4750) — ~50×
   brighter than sunlit terrain — and the sky did not flinch. *The bg fill is
   acquitted: something black is DRAWN there.*

10. **SKY-REG — the first-ever real `registerScene` calls.** (Round-4
    forensics had proven every historical call was silently skipped — the
    layer fetch never worked.) All three layer combos registered
    (`isRegistered=true`), including onto the main view's own scene layer.
    Nothing changed. *registerScene is bookkeeping, not pipeline attachment.
    The in-engine sky levers are exhausted.*

## The culprit, named

A **camera-anchored sky dome**: a small dome glued to the camera, riding
inside any usable far clip (that's why 550 m didn't touch it), drawn over the
background fill (that's why ×5000 blue never showed), shading **black**
because the mirror's reduced pipeline never runs the atmosphere pass that
lights it. Three independent experiments, one object. The same missing pass
explains the **golden over-lit outdoors**: no atmosphere = no blue skylight
fill, sun-only lighting — indoors is "basically 1:1" because there is no
skylight to miss.

## The crash (22:47) — and the lesson

`c00000fd` — stack overflow — 60 ms after the layer census hit "total 15."
Reset Scripts wipes Lua state but **not the world**: every P10 across every
reset left a live goat + Mirror re-rendering the scene each frame. Mirrors
seeing mirrors recurse; fifteen blew the stack. The user's early warning was
the tell: rising lag and grass animating jittery-fast — the scene being
rendered many times per frame. Fix shipped the same hour: a stray-goat sweep
that auto-runs at script load (unhooks + destroys every totem-hosted mirror
that isn't the current rig, handing any layer pointing at a doomed camera the
main camera first), plus the same guard in "Tear down rig."

## The strategic reset

The private-camera lane's only purpose was the far-clip sky cull — and the
dome rides inside any clip, so **the lane is retired without loss**. The
shipped flow returns to the main-camera mirror: live, aim-following,
steerable, auto-noclipped, auto-graded. The sky (and the golden cast, and the
missing crosshair) move to the one pass the engine has no vote in — **our own
compositor shader**:

- **Sky:** key the dome region (near-perfect black in raw pre-tonemap HDR;
  real shadows still carry ambient) and paint a procedural sky gradient
  scaled by the live EV.
- **Golden outdoors:** EV-gated white balance — pull red / push blue when EV
  says outdoors, no-op indoors. Luxury tier: read the game's own
  `app.ColorCorrectController` / LDR post-process values per frame and apply
  its grade.
- **Crosshair:** drawn back on top in the same pass.

## Working method, for the record

This night ran as a two-person lab, and neither half was optional. The human
half: eyes in the headset and on the monitor, catching what numbers don't
carry — *swaying grass inside a frozen frame*, *the goat vanishing at L7*,
*"the beige is mountains, not sky"* — and pressing the buttons, since nothing
here runs autonomously in-game. The machine half: reading `re8.exe`'s memory
while the game ran, building nine instrumented Lua/plugin iterations in one
evening, and keeping every claim tied to a log line — including the one claim
it got wrong, which the human caught.

Evidence: session log `re2_framework_log.txt` (same night, timestamps above),
crash dump `reframework_crash.dmp` (game folder), far-clip comparison
screenshots `Screenshot 2026-08-30 222916/222940.png` (dev-archive), staging
commits `7690e62 → 26bee09 → 24f44d3 → d8d0e18 → 8450e58 → 8772916 → b6eebc8`
and onward through SKY-REG (one commit per theory — the git log IS the
timeline).
