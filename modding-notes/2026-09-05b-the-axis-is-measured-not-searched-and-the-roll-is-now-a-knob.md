Supersedes: the free-search axis selection in `scripts/re8_scope_m6_mirror_producer.lua` (`steer_rotation`, 2026-09-05 00:30 build), and this morning's bind-guard premise in `modding-notes/2026-09-05-the-ownership-check-now-records-its-own-token-and-rt-scale-is-a-settings-number.md` §1

# The steering axis is measured now, not searched — and the roll is a knob

`/pd`, home PC, 2026-09-05 (second pass). **The game was not launched; nothing here was run.**
Inbox empty. Written after the 11:36 `/lm` flat sweep, whose results this builds on.

---

## 1. First, what the sweep said about this morning's bind-guard fix

**Diagnosis right, premise wrong.** The log line I added this morning did its job in one launch:

- `ownership token … DIFFERENT` on **every** bind ⇒ the engine really does not hand back the
  holder pointer. The morning correction stands. `[verified-live 2026-09-05]`
- **But the same launch showed a new read-back pointer every call** — `getMaterialTexture`
  allocates a **fresh wrapper each time**. So the pointer I stored was also a throw-away, the
  comparison could never match, and the guard went on re-asserting every 1.15 s (54 lines in 60 s;
  harmless, picture steady, achieving nothing). `[verified-live 2026-09-05]`

So wrapper pointer identity is dead in **both** directions, and no better choice of wrapper pointer
rescues it. I got the second half wrong this morning, and the instrument I built is what showed it.

**The deeper fault was not the comparison — it was the fallback.** A comparison that always fails
is indistinguishable from a bind that is always being stolen, and the guard resolved that ambiguity
by doing the destructive thing (re-bind) forever. Everywhere else in that function an unanswerable
question returns "leave it alone". This one path did not.

### What is there now

1. **A probe, not a claim.** The stable thing is the *resource* the wrapper wraps — we made our
   holder from `hook::last_committed`, so we own something to compare against. Whether the wrapper
   exposes it could not be checked without the game, so `glass_texture_identity()` **tries a list of
   candidate accessors and logs which exist**, along with the wrapper's real type name. One launch
   names the right one. `[hypothesis]` — nothing here asserts any of those accessors is real.
2. **The bind log now re-reads the slot twice** and says outright whether the wrapper is fresh per
   call, so this finding cannot quietly stop being true without us noticing.
3. **If no identity is available, the guard disables itself** and says so once, instead of
   re-binding on a comparison that cannot succeed. That loses the bind-order trap it was written
   for; it is still the better trade against a spurious rebind every second forever.

---

## 2. The steering axis: measured, not searched

The sweep's reasoning is sound and worth restating because it is the whole result: **rotating a
plane about its own normal is exactly the rotation that leaves the plane — and therefore the
reflection — unchanged.** Five +5° yaw steps (a rotation about the rig's local Y) left the picture
untouched; five +5° pitch steps rolled and swept it. So **local Y is the mirror normal.**
`[verified-live 2026-09-05, flat sweep, n=1 scene]`

The 00:30 build searched all six local axes for the best dot against the required normal, chose
**local +Z at dot 0.79**, and rotated the wrong axis — which alone explains "the reflection looks
back at the body".

**Why 0.79 looked convincing and still was not evidence:** the search scores axes against `n` under
the *baked pose only, at one instant*. Several local axes can score well there, and the best scorer
is merely whichever sits nearest `n` at that moment — not necessarily the plane's normal. The sweep
tests the invariant instead of a snapshot alignment. The test below reproduces this: on a
constructed pose the free search picks **local +Z at dot 0.987** when Y is the true normal.

### The change

`steer_rotation()` no longer searches. The axis is **local Y**, and only the *sign* is chosen at
enable time by whichever of ±Y currently points nearer `n` — the axis is measured, the sign is not,
and getting the sign wrong flips the corrective arc by 180°. The panel's "next axis" override still
reaches all six.

### Verified numerically

`scripts/tests/steer_axis_test.lua` — **61 checks, all passing** `[verified-numerically 2026-09-05]`.
It does not transcribe the maths: it slices the real helper block out of the shipped producer script
and `load()`s it, so every function under test is the shipped text.

| test | result |
| --- | --- |
| `quat_shortest_arc` maps a onto b, incl. antiparallel and identity | dot 1.000000000, unit quaternions |
| rotating about local Y leaves local Y's world direction fixed (the sweep's invariant) | dot 1.000000000 at 5/10/15/20/25° |
| ...and a +5° **pitch** step does move it | confirmed — the other half of what the sweep saw |
| after the fix, the chosen axis lands on `n` from 40 poses | **worst dot 1.000000000** |
| the ±Y sign choice works from either side | both land |
| the old free search, replayed | picks local **+Z at dot 0.987** on a pose where Y is the normal |

**What this cannot decide:** whether `n = normalize(v − d)` is the right imaging model at all. The
flat sweep could not separate it from `normalize(f − d)` either. **Only the headset can.** Nothing
above should be read as settling that.

---

## 3. Roll compensation, as a knob

The sweep also found that pitching the rig **rolls the image roughly 1:1 with the tilt**, law not
pinned (reeds, baseline coherence 0.06).

Cancelling that roll is the one piece of the steering **Lua cannot do**, because Lua does not own
the compositor sampling. So that half is built now, natively, and it needs no rig handle and no new
Lua plumbing — which is why it could be done this session while the rest of the native port could
not (see §5).

- **Measured, not assumed:** the plugin already had the camera rotation, the muzzle rotation and a
  self-calibrated bore axis. The rifle's roll about the bore relative to the camera is computed from
  those, as a **change from a baseline** rather than an absolute — the reference "up" is a
  muzzle-local axis picked cyclically off the bore, so its absolute orientation is arbitrary, but
  that arbitrary part is constant while one weapon is held and the baseline subtracts it exactly.
  Re-baselined when the bore axis changes, so nothing leaks across a weapon swap.
- **Applied to the source sampling only.** `ps_main` now rotates the sampling coordinates, in
  aspect-corrected square space so a 4:3 target cannot turn the rotation into a shear. The reticle,
  vignette and source-mode tab are all drawn from `c` and **do not move** — the sight is the thing
  that must stay put.
- **`roll_k` is a settings key, default 0 = OFF.** The shipped picture is unchanged until it is set.
  `1.0` is the sweep's "roughly 1:1" reading. It is **signed**, because the sweep did not pin the
  sign either: if `1.0` is worse, try `-1.0` before doubting the idea.
- Free floats `_pad2` carried it, so the constant-buffer size and root-constant count are unchanged.

**This also makes the `[FLAT]` roll-law row easier**, which is the main reason to build it before
the law is pinned: nulling the roll with a knob is a far easier read than measuring a tilt-to-roll
ratio off a screenshot.

### Verified numerically

`plugin/tools/roll_math_test.cpp` — **20 checks, all passing**, clean at `-Wall -Wextra -Wpedantic`
`[verified-numerically 2026-09-05]`. It includes the shipped `src/roll_math.h`, so the function
under test is the one that ships. Rotating the rifle about its own bore by φ moves the measured
angle by exactly φ (7 steps, ±5° to ±120°); the sign follows the right-hand rule; a rigid rotation
of the whole configuration leaves the roll unchanged; the parallel and near-parallel cases are
**refused** rather than answered with numerical dust.

⚠️ **One assertion in that test was wrong and the shipped code was right.** I first asserted
`+179° − (−179°) = +2°`. It is **−2°**: from −179° you reach +179° by going *back* two degrees
through ±180°, not forward. `roll_wrap` had it right. Left in the file with that note, because
getting this sign backwards *in a caller* is exactly what would make the correction fight the roll
instead of cancelling it near the wrap point.

### One landmine removed while I was in there

The blit path fills the same constant buffer and zero-filled `[12..19]`. A zero `rollCos`/`rollSin`
is a **degenerate** rotation that collapses every sample to the crop centre. `ps_blit` does not read
those fields today, so nothing was broken — but the first person to reuse that fill for a shader
that does read them would have got a flat grey picture and no clue why. It now writes the identity.

---

## 4. What is NOT established

- Whether the imaging model is right (§2). Headset only.
- Whether the roll correction helps, and at what `k` and sign. It ships **off**.
- Whether any texture-identity accessor exists for the bind guard (§1). The probe answers it.
- The roll law itself is still unpinned; `roll_k` is a knob precisely because of that, not a fix.

**The diagnostic that would show the roll *derivation* is wrong** rather than the coefficient needing
tuning: with `roll_k = 0`, the log's roll figure should track the rifle tilt about the bore and
**stay near zero when you only yaw or only walk**. A roll reading that wanders while the rifle is
held steady means the measurement is wrong, and no value of `k` will save it.

---

## 4b. The atmosphere post-mortem, answered — and the row's premise was the misdirection

The `[PD]` row asked: *"why did the atmosphere package brighten raw-18 snow to white? Its sky-fill
masks on source luminance BELOW skyThresh, which cannot reach 18. Read `ps_blit` for the other
brightening terms (skyGain, wbStrength)."*

**Two corrections, then the answer.**

**(a) `ps_blit` has no brightening terms.** It is four lines: an optional V-flip and a passthrough
sample. `skyGain` and `wbStrength` live in `ps_main`. `[verified-numerically 2026-09-05]` Reading
`ps_blit` would have found nothing and looked like a dead end.

**(b) The premise "raw-18 snow" is where the reasoning went wrong.** The mask arithmetic in the row
is correct — `skyM = (1 − smoothstep(skyThresh·0.25, skyThresh, rawLum)) · skyStrength`, and at
`rawLum = 18` even the top rung (`skyThresh = 12`) gives `smoothstep(3, 12, 18) = 1`, so `skyM = 0`
and the sky fill genuinely cannot touch it. **But the snow is not at raw 18 in the mirror.**

That is the whole thing. `rawLum` is the **mirror's** luminance, and the mirror renders the scene
**with no atmosphere pass** — that is this project's oldest finding, the reason the sky is black
there. So sunlit snow is *not* bright in the mirror source. The 2026-09-05 sweep measured exactly
this at another spot: *"our RT 0.02–0.05 at source 2–6"*. At `rawLum ≈ 2–6`, rungs 5 / 8 / 12 leave
the mask **wide open**.

**And what it opens onto is very bright.** `skyGain` is sized CPU-side to land the painted sky at
0.72 *after* the tonemap, so it is divided by the exposure — with the GT knob at 0.134 the
non-GT branch alone is `1.2730 / exposure ≈ 9.5`, and the GT branch inverts the curve for the same
target. The fill is `lerp(col.rgb, sky · skyGain, skyM)` with `sky ≈ (0.62, 0.74, 0.88)`. So a dark
snow pixel is lerped toward something around (6, 7, 8) in linear HDR and lands near white.

**Conclusion: the snow was classified as sky.** The mask's premise is "dark ⇒ sky", but in a render
with no atmosphere pass, *dark* also means "anything not directly lit". Snow in the mirror is dark,
so it is sky, so it is painted. `[inferred-static 2026-09-05]` — read out of `ps_main` and the
CPU-side gating, consistent with both measurements on record (source 2–6 at the sweep spot; package
OFF ⇒ snow went dark), but the `rawLum` of the snow *at the spot where it went white* was never
captured, so this is not verified.

**The free test that would confirm or kill it:** the effect must track the ladder. At rung 0
(`skyThresh = 0.5`) snow at raw 2–6 sits above the mask and should stay correct; at rungs 8 and 12
it should go white. If the snow whitens at rung 0 as well, the sky fill is **not** the mechanism and
the remaining unmasked term — the white balance, `crop[10]`, ungated from the ladder on 2026-09-02
— is the next suspect. (Though note WB is close to luminance-neutral by construction: R×0.64,
G×0.92, B×1.28 at full strength is a net luminance change of about −11%, i.e. it slightly *darkens*.
It is a poor candidate for "white", which is part of why the sky fill is the better explanation.)

The package is OFF and unneeded on the GT curve, so this stays a post-mortem — but it is a
**design-level** finding rather than a tuning one: any future "paint the missing sky" attempt that
masks on darkness will re-classify unlit geometry as sky in exactly this way.

## 4c. Resolution lever 2: the larger `.rtex` was already on record

The row said *"find a larger `.rtex` (grep the accessed-files list / dump for `movie_` names)"*. No
grep was needed — **it is in our own notes from 2026-08-29**: RE8's shippable `.rtex` inventory
*"~30 entries incl. 1920×1080"*, sourced from `Ekey/REE.PAK.Tool Projects/RE8_STM_Release.list`.
`[reported 2026-08-29]`

1920×1080 against the current 1280×720 is **1.5× the linear resolution**, and that is the lever that
can add real detail — `rt_scale` (this morning) only removed our own downsample, because the
magnified patch is ~300 source pixels wide out of 1280.

**What I did NOT do is flip the constant.** Only the *size* is on record; the exact path string is
not. Guessing `movie/rtex/movie_1920_1080.rtex` wrong would make `create_resource` return nil and
leave the scope with no target at all — a visible regression traded for an unverified guess.

Instead, both sides now try large-then-known-good:

- **Lua** `make_holder()` walks a candidate list, largest first, and **falls back** to the
  known-good 1280 path if the larger one does not resolve. It logs which it took, and says
  explicitly when it fell back.
- **Plugin** `looks_like_mirror_target()` accepts **either** width, each with its own tight
  padded-height window (1280×~728 or 1920×~1080) rather than one loose window.

So one launch settles the path string at zero risk. `mirror RT: using …` names the winner.

⚠️ **What still holds the latch safe after widening it:** `ALLOW_RENDER_TARGET` already excludes
every streamed game texture (they arrive with `flags=0x0`), and the two widths keep separate height
windows. Widening a latch is exactly where a mis-latch could grab something else, so that is stated
rather than assumed.

**Not established:** whether a 1920×1080 mirror actually *helps*. The mirror is a `via.render.Mirror`
rendering the scene; more pixels should mean a sharper magnified patch, but the magnification factor
and the crop are unchanged, so the gain is the resolution ratio at best and could be eaten by the
mirror's own render cost. That is a flat-run judgement, not a static one.

## 5. What I did not do, and why

The starred `[PD]` row also asks for the **rotation** half natively — taking the rig handle from Lua
by the mailbox pattern and rotating local Y onto `n` in the plugin. I did not.

Two honest reasons, neither of them "it was hard":

1. **The Lua already does it, and with the axis fixed it is now correct by measurement.** Porting it
   today would build the same thing twice while the model itself is still unconfirmed. The headset
   test that confirms the model does not care which language the rotation runs in.
2. **The plumbing is a real design decision, not a mechanical port.** The Lua→plugin channel is a
   *text file* of virtual-key codes. Passing a managed-object handle through it means writing a raw
   pointer as text and having the plugin trust it, which needs a lifetime and validation story I
   would be inventing rather than deriving. That is a decision worth making deliberately.

**The sequencing this suggests:** test the axis-fixed Lua steering in the headset (it is deployed and
ready), pin the roll law flat with `roll_k`, and then port to native with both answers in hand —
rather than porting now and re-deriving them behind a rewrite.
