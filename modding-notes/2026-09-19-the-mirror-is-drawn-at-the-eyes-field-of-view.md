# The smear has an exact angle, and the cheap fix would have made it worse

**2026-09-19, `/pd`, dev PC `DESKTOP-V8GTSIR`. STATIC ONLY — the game was not launched, nothing was
deployed, nothing was run.** Dossier: §9aq. Tool: `plugin/tools/mirror_fov_check.cpp`.

## What was asked

The board's top row said the shake and the smear in the scope are one fault: the crop is told to
centre on a point that lies outside the frame the mirror actually drew, so it clamps at the border
and the border stretches diagonally across the glass. It named three candidate fixes, said to do
**(1) draw the mirror wider than the gaze cone** first — and, correctly, refused to start until
somebody answered whether the field of view is ours to widen at all.

This is that answer. It needed no launch, because the two numbers it turns on were already measured
live on 2026-09-12 and written into the dossier.

## What was found

**1. The mirror is drawn at the headset eye's field of view: 90.9° across.** That is not the mirror's
own setting — REFramework forces the HMD eye projection onto it (§9j/§9l). The mirror's *own*
projection is 59.4°.

**2. ⚠️ So exempting the mirror pass — the patch that already exists, built and proven to fire on
2026-09-12 — would make this fault WORSE, not better.** It restores the native projection and takes
the half-width from 45.4° down to 29.7°, losing 15.7° of room a side. That was the obvious cheap
thing to reach for and it is exactly backwards. The exemption is still right for the problem it was
built for; it is simply not this problem.

**3. The crop first clamps at +38.7° on one side and −49.1° on the other.** The two sides differ by
10.4° for one reason only: an HMD eye projection is off-centre, and the board's own measurement of
**the bore 20–44° off the gaze during the smear straddles 38.7° exactly.** The row's hypothesis is
now a number, and it is a number that could have come out wrong.

**4. New, and nobody has looked for it: the two eyes do not clamp together.** The second eye carries
the mirrored shift, so it clamps at 49.1° on the same side — **a 10.4° window in which one eye smears
and the other does not.** A stereo mismatch like that is felt as discomfort long before anyone
identifies it as a picture fault. Worth asking the wearer directly, and it costs nothing to ask.

**5. Widening works but is not free.** To hold the bore at 44° the mirror must be drawn at 50.7°
half-width, leaving **83 %** of today's sharpness; at 50°, **67 %**; at 55°, **56 %**. The scope
magnifies, so that loss lands squarely on the thing being looked at.

**6. ⭐ There is a better fix the row did not consider: steer the projection instead of widening it.**
An off-centre shift changes *which* cone is drawn without widening it. Putting the bore at the centre
of the drawn frame costs **nothing in sharpness**, and because the crop then sits in the middle of
the frame **it cannot clamp at any angle**. The failure mode is removed rather than pushed further
out, and the "clamp gracefully instead of smearing" fix stops being needed at all. Same hook, same
patch site, better on every axis measured.

## What was built

- `plugin/tools/mirror_fov_check.cpp` — **20 checks, 0 failed**, and four deliberate mutants all
  caught (a symmetric projection, a wider native projection, a much larger crop window, and a
  different zoom). A test that cannot fail is not evidence, so each mutant is asserted to trip.
- `plugin/src/crop_follow_math.h` gains **`proj = 2`**. Steering breaks both existing crop
  candidates — each describes a frame centred on the gaze — and under steering the right crop centre
  *is* the texture centre, by construction, at every input. Compile-verified.
- Regression: the existing suites pass unchanged — `crop_follow_test` 40 checks 0 failed,
  `prop_offset_check` 5 passed 0 failed.

## What is NOT established

- **Whether the engine culls correctly against a strongly off-axis frustum.** At 60° the whole
  frustum sits to one side. Nothing here tests what RE Engine does with that; objects popping at the
  frame edge is the predicted failure. **This is the main risk and it needs a launch.**
- **Whether the bore angle can be handed to the REFramework hook at the moment it is needed.** The
  plugin computes it already; the wiring is unanswered.
- The clamp onsets are exact *given* the two matrices, and those matrices are `n=1`.
- The 20–44° range comes from one session.

## What it needs next, and where

The change itself belongs in the REFramework fork, at the site the 2026-09-12 v2 patch already
touches — inside the mirror window, write a steered projection instead of returning. **The build
tree for that fork exists only on the home PC** (absent from the dev PC, checked today), so this is
raised as an addressed reminder rather than left on a board both machines read.

Nothing was deployed. The game was not launched.
