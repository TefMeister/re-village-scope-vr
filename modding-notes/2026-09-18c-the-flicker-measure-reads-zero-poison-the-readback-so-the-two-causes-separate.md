# The flicker measure reads zero: poison the readback so the two causes separate

**2026-09-18, dev PC `DESKTOP-V8GTSIR`, `/pd`, Opus. THE GAME WAS NOT LAUNCHED AND NOTHING HERE HAS
BEEN RUN.**

Board row: the `[PD]` ⭐⭐⭐ *"the flicker measure reads exactly zero in VR — find out why before
anything else on the flicker."* 23,400 frames, every summary `avg=0.0000 max=0.000` at both
`t=0.080` and `t=0.005`, while the wearer was moving and counting about **12 flickers per 2 minutes**
`[verified-live 2026-09-17, n=8 summaries]`. `hold 2` rests on the same number, so the whole flicker
front is blocked behind it.

---

## The re-read found nothing wrong, and that is the finding

The row already recorded that slots, RTV, readback and shader had been re-read with nothing visibly
wrong. This session read them again, end to end, and **agrees** `[inferred-static 2026-09-18]`:

- **SRV heap** — 6 descriptors; `[4]` = our RT (t0), `[5]` = `rt_prev` (t1); the diff pass binds a
  table starting at `[4]`. The root signature's SRV range is 2 wide, so t0/t1 both resolve.
- **RTV heap** — 3 descriptors; `diff_rt`'s view is written at index 2 and the diff pass sets
  index 2. They agree.
- **`ps_diff`** — samples t0 and t1 over a 4×4 grid per cell and returns the mean absolute luma
  delta. Correct as written.
- **The mid-frame submit** — closes, executes, fence-waits, and then **does** `Reset` the allocator
  and list before recording the rest of the frame. The obvious hazard is not there.
- **`rt_prev`** is copied from `g.rt` at the end of every frame, and `g.rt` is redrawn unconditionally
  every frame.

**So reading harder is not going to settle it**, and that is worth saying plainly rather than
producing a fourth pass over the same code.

## The real problem is that `avg=0.0000` is ambiguous, and nothing on the board could tell which

An average of zero is produced by two completely different faults, and **the log cannot tell them
apart**:

| what actually happened | what the log shows |
| --- | --- |
| the readback copy never landed, so the buffer is still its initial zeros | `avg=0.0000` |
| the copy landed fine and the shader genuinely computed zero | `avg=0.0000` |

The first is a plumbing bug in our code. The second means `t0` and `t1` sampled **identical pixels**,
which — since `rt_prev` is last frame's `g.rt` — means **`g.rt` is not changing between frames**, an
entirely different problem with an entirely different fix. Two of the row's three candidates sit on
one side of that line and the third on the other, so **the line is the thing worth measuring.**

## What was built: poison the readback before the GPU copy

New harness word **`holddiag <n>`** (and settings/pane key `hold_diag`). While it counts down, each
frame:

1. **Before** the command list is submitted, the readback buffer is filled with a sentinel
   (`kHoldSentinel = -12345.0f`, a value a mean-of-absolute-differences can never produce).
2. The GPU copy runs as usual and should overwrite all of it.
3. The read back counts how much poison **survived**, alongside min, max and how many values are
   exactly zero, and prints a one-line verdict.

How much poison survives is the discriminator, and it gives four distinguishable outcomes:

| reading | verdict | where to look |
| --- | --- | --- |
| **all 192 still poison** | the copy never landed | the diff draw or the `CopyTextureRegion` into `diff_rb` |
| **some poison left** | the copy landed only partly | the placed footprint / row pitch |
| **no poison, all zero** | the measure is real and the answer is genuinely zero | `g.rt` is not changing between frames — the fault is upstream of the measure entirely |
| **no poison, some non-zero** | the measure works | the fault is downstream, in the averaging or the threshold |

The line also prints `rt` dimensions, format, `rt_prev_valid` and whether the source is raw-HDR or
the 8-bit resolve, because those are the things that differ between a flat run and a VR one.

### Why it is a knob and not always on

It writes to the readback buffer and prints a line per frame, so it is **off by default and counts
down to zero** — `holddiag 120` gives two seconds at 60 fps and then goes quiet by itself. Nothing
about the shipped path changes when it is off `[compile-verified 2026-09-18]`.

### Verification

The verdict is a **pure function**, `holdm::classify`, in `hold_math.h` beside the existing hold
logic — deliberately, so `tools/hold_test.cpp` compiles **the shipped logic** rather than a
transcription of it, which is the same shape as `rgate::decide`.

`hold_test` is now **26/26** (was 16) `[verified-numerically 2026-09-18]`, with ten new checks
covering every boundary: all-poison, one-poison, all-but-one-poison, all-zero, one-non-zero,
none-zero, nothing-read-at-all, and — the one the whole diagnostic exists for — that an all-poison
read and an all-zero read give **different** verdicts.

**The suite was proved able to fail:** removing the `sentinels >= n_all` branch, so a fully poisoned
read falls through to the zero check, makes check 12a fail and nothing else. That is precisely the
mistake the poison exists to prevent, and the test catches it. Reverted; back to 26/26.

All ten plugin suites pass unchanged: 26 + rebuild_gate PASS + 40 + 124 + 14 + 25 + 176 + 20 + 5 +
tone-curve. Every Lua suite passes too (27, 29, 49, 61, 71 and the globals check).

---

## What is NOT established

- **Nothing about why the measure reads zero.** This session built the instrument, it did not take
  the reading. The four verdicts above are what the instrument *can* say, not what it *will* say.
- That the fault is in the plugin at all. The "no poison, all zero" outcome would move it entirely
  upstream, into whether `g.rt` is being redrawn with live content in VR.
- Whether the flat behaviour differs from VR — still the open `[FLAT]` row, and now much more
  informative, because `holddiag` can run flat too.

## The one launch

Flat is enough, and it can share a launch with the other flat rows:

```
bringup
hold 1
holddiag 120
```

Then read the `holddiag:` lines and take the verdict at the end of each. Two seconds of them is
plenty; it stops by itself.

⚠️ **Copy `re2_framework_log.txt` aside before relaunching** — REFramework truncates it at every
launch, and the 2026-09-17 session lost the two logs that mattered exactly this way.

---

## ⚠️ The near-miss, and the guard that came out of it

**The plugin knob was built, compiled, unit-tested and DEPLOYED with no way to reach it.** The
harness word `holddiag` was never added — an earlier patch step failed an assertion partway and
only half of it was applied. Everything downstream still looked healthy: the plugin compiled, all
ten suites passed, the DLL deployed and hash-verified. The first sign would have been a wasted
launch in which the diagnostic printed nothing, which reads exactly like *"the measure is fine"*.

It was caught by hand, which is not a control.

**Why this shape of bug is easy to ship here:** a live knob needs **four** separate edits to line up.

1. the harness word sets a state field,
2. `pane.lua` names that field in its format string,
3. `pane.lua` passes it in the matching **argument position**,
4. the plugin's `pane_file.cpp` reads that key.

Miss any one and the word is accepted and logged cheerfully and does nothing. Get (3) wrong and it
is worse — a real value lands on the **neighbouring** knob.

**`tests/knob_chain_test.lua`** now checks all four links for all eight pane-file knobs (`hold`,
`holdt`, `holddiag`, `src8`, `rbfb`, `swdelay`, `eyepar`, `framev`), and that the format string is
not longer than its argument list. **41/41**, proved able to fail by renaming the `holddiag` word —
the exact bug `[verified-numerically 2026-09-18]`. It also prints, without failing, any plugin pane
key that nothing writes, since some are legitimately settings-file only; that list is empty today.

A new knob of this shape should be added to its `KNOBS` table. That is the point of the table.
