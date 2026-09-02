# Three compositor defects, found flat and fixed statically

**2026-09-02, home PC.** Found during the first live run of the virtual numpad
panel; fixed in a `/pd` pass afterwards with the game closed. **Nothing in this
entry has been run** — the build is `[compile-verified]` and deployed, not tested.

---

## 1. The picture was ~1.76× too tall

A village well read as a tower. Invisible for nine days because every judgement
until then had been made on mountains and sky, where a vertical stretch has
nothing straight to betray it. The first man-made object in the scope showed it
instantly.

### The chain, worked rather than guessed

`ps_main` sampled with both extents equal (`uvHalf.x == uvHalf.y == 0.5/zoom`) —
a patch that is **square in UV**. A square UV patch of a non-square source is a
**rectangle in pixels**, and that is the entire bug. But the naive "so it's off
by the source aspect" is only accidentally right, because two more stages
distort in between:

| Stage | Factor | |
| --- | --- | --- |
| sample | `(Wr·Hs)/(Ws·Hr)` | square-UV patch of 1280×728 into a 4:3 RT |
| blit | `(Wt·Hr)/(Ht·Wr)` | RT 480×360 → full engine target |
| lens | `Ht/Wt` | square UV patch shown on a round lens |
| **product** | **`Hs/Ws`** | **= 728/1280 = 0.569 → 1.758× too tall** |

**The RT and the engine-target dimensions cancel completely.** The net error is
exactly the *source's* own aspect, whatever the intermediate buffers are.

That result mattered practically, because the engine target is **784×1170 —
portrait**, which was read off the blit's own log line rather than assumed. A
first pass at this had guessed the target was landscape 1280×728; the arithmetic
happened to land on the same 1.758 either way, which is precisely the kind of
coincidence that lets a wrong model survive. `[measured 2026-09-02]` for the
target dimensions; `[inferred-static]` for the lens stage, which is the one link
still not read from data — see §4.

### The fix

One line of sampling: `half_u = half_v / src_aspect`, with `src_aspect` taken
from the **live** source descriptor rather than a constant, so it stays right if
the mirror ever allocates at another size.

**Narrowed u rather than widening v, deliberately.** Both restore correct
proportions; they differ in which axis keeps its field. Widening v would pull in
more of the mirror's bad vertical region — the same one `mir_cy` (numpad 1/3)
exists to slide away from. So vertical framing is untouched and the horizontal
field narrows. If magnification then feels wrong, that is a zoom-preset tweak,
not a re-derivation.

Logged once per distinct source, so a wrong picture can always be traced to the
number actually used instead of the one derived here.

## 2. The white-balance knob was dead

`crop[10] = wb_s * g_wb_amount` sat **inside** `if (g_atmo_on ...)` — the sky
ladder's gate. The ladder persists **off** once cycled past its top rung, which
had happened on 09-01. So on this machine the knob shipped dead: the log
cheerfully printed `wb=0.5 … 1.0 … 2.0` while the shader was handed a hard zero.

The two corrections share a *cause* (the mirror renders with no atmosphere pass)
but are independent *effects*, so they now gate independently — WB on EV alone,
sky fill on the ladder as before.

**This is why "I pressed it and nothing happened" was true and the log
disagreed.** A knob that reports its own value is not evidence that the value
reaches the pixels; only a read-back at the far end is.

## 3. Bind order could silently disable everything

The Lua `m6` script's **E** button binds the lens to the **raw mirror holder**
and overwrites whatever was there — its own comment says as much. So numpad `*`
pressed *before* P10 → E → D left the raw 8-bit resolve on the glass:

- **black sky** — the 8-bit resolve snapshots before the sky pass (the 08-31
  finding, re-confirmed);
- **mirrored and upside-down** — none of the compositor's flips apply to it;
- **every knob apparently inert** — because the compositor really was rendering
  into an RT that nothing displayed.

It presents as a totally broken mod. It cost most of a session, and **the same
trap is already recorded on 08-31 run 2** — which is the argument for fixing the
mechanism rather than writing the order down again.

`world_tick` now reads the bound slots back a few times a second and re-binds
**only if something replaced us**. `bind_scope_glass()` already opens with a
restore, so re-binding puts the stock texture back before re-reading it — the
saved original stays the true one and overwrites never stack. Silent unless it
acts; cleared by an explicit restore, so a deliberate un-bind still sticks.

---

## 4. What is NOT established

- **Nothing here has been run.** `[compile-verified 2026-09-02]` only.
- **The lens stage is still inferred.** Stages 1–2 were read from our own code
  and the blit's logged target size. Stage 3 — that the lens shows a *square UV
  patch* on a round lens — comes from the material dump
  (`Reticle_UV_Scale_Offset = 0.80, 0.80`) plus the assumption that the lens
  mesh's UVs are square. **The lens mesh UV layout has never been inspected.**
  If that assumption is wrong the correction will be off by whatever the real
  lens mapping is, in a way that shows up as a *residual* stretch or squash.
- **The falsification test is free and built in:** the reticle is drawn inside
  the RT and skips stage 1, so by this same chain it should currently be
  **1.33× too tall**, and the fix should leave it **square** without anyone
  touching reticle code. If the scene corrects and the reticle does not — or
  vice versa — the model is wrong somewhere and the residual says where. An
  earlier note claiming the reticle "measures 1.24×" was an eyeball of a
  screenshot carrying a measurement tag, and has been withdrawn.
- **Diagnostic that would show the derivation is wrong rather than a knob
  needing a nudge:** a residual that is *not* a clean ratio of 728/1280, or a
  scene that corrects while the reticle stays stretched. A uniform residual
  would instead mean the lens mapping is a fixed factor we can simply fold in.

## 5. Deployed state

`re_scope_vr.dll` 128,000 B, VS2022 Release, zero warnings, both REFramework
exports intact, hash-verified after copy. Previous DLL kept as
`re_scope_vr.dll.pre-aspect-backup-2026-09-02`. Source: `staging` `542ad43`.

**Next launch:** P10 → E → D → `*` (the guard now makes that order
non-load-bearing, which is itself worth confirming by pressing `*` first on
purpose once). Then look at a *building*, not a landscape.
