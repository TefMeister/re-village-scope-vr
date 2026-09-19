# The smear becomes a documented limitation — and the crop centre is the new lead

**2026-09-19, home PC (RTX), wearer present.** Written straight after the §9av disproof, and it
changes the direction of the project.

## 1. Tefa's decision: the smear is a LIMITATION, not a bug to chase

Their words:

> "it barely shows up on the left side, and the picture is aimed lower and to the left. maybe, if we
> get the picture right and the crosshair shooting where it is supposed to shoot, it will not even
> be seen in VR, or maybe at some crazy angles trying to toggle it, that does not happen in normal
> gameplay really, so we write this up as a limitation of the mod instead of chasing perfection."

**Recorded as decided by them** — not a verdict this session is entitled to reach on its own.

Three things in that worth keeping, because they are observations and not just a preference:

- **It is one-sided.** "Barely shows up on the left side" — the smear is not symmetric.
- **It appears at angles normal play does not reach.** It was being produced by deliberately
  wrenching the rifle far off to one side.
- ⭐ **The picture is aimed LOW AND LEFT.** That is a new report, and it is the one that matters
  most — see below.

**What this means for the project:** the smear stops being the headline and becomes a line in the
release notes. The mod ships with it named honestly, the way the motion-sickness caution is. Effort
moves to where the scope points.

## 2. ⭐⭐⭐ The new lead, and it is a much better one: the crop centre sits near an edge

The scope picture is a window cropped out of a 2560×1448 texture. Where that window is taken from is
logged every tick as `centre=(u,v)`. Dead centre would be **(0.500, 0.500)**.

Measured live, rifle in hand, while the picture was described as good but mis-aimed
`[measured 2026-09-19, n=1 launch, ~8 consecutive ticks]`:

```
geom: ON centre=(0.735,0.065) ... stretch 1.19 skew -9.1 deg scale 1.29
      | rot 180 flip 0 vflip 0 P real | zero up 14.4 right 9.5
```

- **u = 0.735** — a quarter of the way toward the right-hand edge.
- **v = 0.065** — **within a sixteenth of the edge.** The crop is nearly falling off the texture
  while the rifle is being held normally.

**This explains, in one number, things that §9aq needed a whole theory for:**

- **Why the picture is aimed low and left** — it is being taken from the wrong part of the texture.
- **Why the smear arrives at modest angles** — the crop does not start in the middle with room to
  move; it starts almost at the edge, so it takes very little to push it off.
- **Why it is one-sided** — an off-centre start is by definition closer to one edge than the other.
- **Why steering the render changed nothing (§9av)** — the fault was never in what was *rendered*.
  It is in *which part of it we take*.

⚠️ **This is a lead, not a conclusion.** `[hypothesis]` What has not been established:

- Whether (0.5, 0.5) is even the correct target under this pane pose. The mirror viewpoint is
  deliberately shifted sideways (`propr 0.20`), and `rot 180` / the flips are in play, so some
  offset may be legitimate. **A number being surprising is not the same as it being wrong.**
- What the centre reads when the rifle points at something the player is actually aiming at, versus
  at rest. Only one condition was captured.
- Whether the zeroing (`zero up 14.4 right 9.5`, applied and visible in the same line) is being
  added in the right place or is itself part of the offset.

**None of that needs the game running.** The crop maths lives in `plugin/src/crop_follow_math.h`
with a test suite beside it (`crop_follow_test.cpp`, 40 checks), so the target centre can be derived
and checked statically before anything is launched.

## 3. Housekeeping done

- **The disproved code is switched OFF**, not just abandoned: `VR_SteerMirrorProjection=false` and
  `VR_MirrorProjectionShout=false` written to the live config, so the next launch is clean.
- The steering build stays installed (it is the v2 build plus code that now does nothing) and both
  switch scripts still work in both directions.

## 4. ⚠️ A lesson worth keeping from tonight

§9aq was an elegant theory with twenty passing numerical checks, and it was wrong at the premise.
Tonight's better lead came from **one logged number that had been printed every tick for days**
(`centre=`), read for the first time only because the wearer said the picture looked mis-aimed.

The instrument was already there and already correct. Nobody had looked at it, because the theory
explained the symptom well enough that it stopped being interesting. **A convincing theory is the
most expensive thing to be wrong about**, and the wearer's plain description of what they saw is
what broke it open — twice tonight, first "manual steer did nothing", then "aimed lower and to the
left".

Credit: **praydog** (REFramework), **gmankab** (the `pd-upscaler` fork).
