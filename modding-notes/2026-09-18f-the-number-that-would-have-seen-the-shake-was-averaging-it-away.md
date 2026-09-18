# The number that would have seen the rifle shake was averaging it away

**2026-09-18, dev PC `DESKTOP-V8GTSIR`, `/pd`, Opus. THE GAME WAS NOT LAUNCHED AND NOTHING HERE HAS BEEN RUN.**

The board row said *"the shake is the rifle, not the scope: look upstream."* Looking upstream turned
out to be blocked by something closer to home: **we have never had a measurement that could see a
shake**, and the one that looks like it can has been quietly reporting the opposite.

---

## 1. Where the row stood

The wearer: *"it is the whole weapon that has that reprojection shake to it and it makes the scope
shake with it"* `[reported 2026-09-17]`. The scope's own per-eye aim was already ruled out the same
night — `eyepar 1` changed nothing and its own log line disproved the premise, the reflected eye
having moved 0.000–0.001 m on 200 of 231 ticks `[verified-live 2026-09-17, n=231 lines]`.

So the shake is upstream of the scope. The row asked for REFramework's weapon-pose path to be read.
**That path is not readable from here:** `re8vr:update_hand_ik()` is a native method on REFramework's
own sol object, implemented in its compiled DLL, and nothing on disk in the game folder contains it
`[inferred-static 2026-09-18]`. The Lua that *is* on disk only calls it.

## 2. ⭐ The actual finding: the measure we had is a net displacement, sampled once a second

`crop_follow` has printed `self %.2f deg/tick` since the pane-mismatch work, and it reads like a
motion measure. It is not one.

The previous sample is taken **inside** the `if ((tick % 60) != 0) return;` logging block. So the
number is the angle between the pane normal *now* and the pane normal *one second ago*, divided by
60 — a **net displacement**. A rifle vibrating about a fixed direction returns to where it started,
so it reads near zero **for precisely the motion being investigated**. And anything vibrating faster
than 1 Hz is sampled once per cycle, so it aliases as well.

`tools/jitter_test.cpp` §3 puts a number on it: a **0.5° vibration** reads as **under 0.01 °/tick**
on the old measure `[verified-numerically 2026-09-18]`.

### ⚠️ And it is load-bearing, which is the part that matters

`self_rate` feeds `pane_still`, which gates the pane-mismatch verdict — the one whose own comment
says *"a false 'DERIVATION error' costs a debugging session"*. A shaking rifle that happens to end
where it started reads as **HELD STILL**, and that verdict can then fire on exactly the motion it was
written to exclude. 0.01 °/tick is comfortably under the 0.35 °/tick threshold.

No such false verdict has been observed, and the trigger also needs a ≥ 3° mismatch, so this is a
real path rather than a known event `[hypothesis]`. `pane_still` is now tightened to require the
accumulated **path** to be small as well — which can only ever withhold judgement more often, and the
comment above it already calls that the safe direction.

## 3. What was built

`plugin/src/jitter_math.h` — pure, no D3D, so the test compiles the shipped code. Every tick it keeps
two quantities per direction:

* **path** — the sum of the per-tick angular steps: how far the direction actually travelled;
* **net** — the angle from the window's first sample to its last: how far it ended up.

A smooth pan has path ≈ net, so **ratio ≈ 1**. A vibration has net ≈ 0 and a large path, so the ratio
is large. One number separates *being aimed* from *shaking*, and it is exactly the number a 1 Hz net
measure destroys.

It reports once a second on the existing `crop-follow` cadence — **no new knob, no new four-link
chain** — because the accumulation is what had to move, not the reporting. Three details that are
each a trap:

* **The accumulator sits above the 1 Hz gate.** Putting it inside is the original mistake, and §7 of
  the test reads `crop_follow.cpp` as text to check it is still above.
* **Angles come from `atan2` of the cross product, not `acos`.** `acos` is ill-conditioned near zero
  for exactly the hundredth-of-a-degree steps this is about; §1 shows it losing them.
* **A quiet floor.** Below 0.05° the ratio is forced to 1 rather than dividing two noise figures —
  otherwise a rifle resting on a table produces a spectacular ratio out of float dust and reads as a
  violent shake.

⭐ The line also reports **what the wearer sees**: the bore's travel multiplied by the zoom. A
telescope multiplies angles, so at 6× a tenth of a degree of rifle wobble arrives at the eye as six
tenths. **The picture looking far shakier than the rifle is expected, not a second fault** — and that
alone may account for why this reads as a scope problem.

**jitter_test: 28/28, proved able to fail on six mutants** `[verified-numerically 2026-09-18]` — path
collapsing back to net, the quiet floor removed, a degenerate reading folded in, `acos` restored, the
zoom no longer multiplying, and the accumulator moved below the gate.

## 4. ⚠️ What this cannot settle, and why that is stated up front

It measures what the rifle's direction does **per game tick**. It cannot see the runtime's own
reprojection, which resamples the head pose *after* the game thread has finished the frame and is
invisible to anything running on that thread. So the reading splits the row rather than closing it:

| what the log says | what it means |
| --- | --- |
| **large bore path, ratio ≥ 5** | the pose we are *handed* is already shaking → upstream, in REFramework or the controller. Our scope is faithfully magnifying someone else's jitter. |
| **small bore path, wearer still sees shake** | the pose is clean and the shake is added *after* us → a runtime/reprojection problem, a different fault with a different owner. |
| **large `at the eye` but small bore path** | not a shake at all: ordinary hand movement magnified by the zoom. |

Those are different problems and they would have been worked differently. Guessing which one was in
play is what the last two sessions on this row did.

## 5. Deployed, and what is not established

Rebuilt with the bundled VS CMake, the DLL deployed with a dated `.bak-2026-09-18d` backup, 28 files
re-stamped and hash-verified. Thirteen plugin suites and nine producer suites pass.

**Nothing here has been run.** The blindness of the old measure is arithmetic on the shipped code and
is settled; the *cause* of the shake is not measured at all yet, and the new line has never printed.

**Next launch, no extra trip:** turn `cropfollow 1` on for a few seconds while holding the rifle as
still as you can, then again while aiming smoothly, and read the two `jitter (last ~1 s):` lines. The
first tells you whether the pose is shaking on its own; the second is the control that proves the
measure is awake.

Credit: **praydog** (REFramework).
