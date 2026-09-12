# The constant tilt gets a knob that measures its own value, and the goat toggle turns out not to be free (2026-09-12 night, home PC `RTX`, `/pd`)

**The game was not launched and nothing here has been run.** Built, tested on the host, deployed
and hash-stamped.

Closes all three `[PD]` rows queued by tonight's `/lm` wear session — two as built, one as
*corrected*, because it was not the simple change the row claimed.

Deployed install was verified current first: a rebuild hashed **identical** to the installed
`re_scope_vr.dll` (`8cb612d6…`) before any edit, so the stamp was the newest build.

---

## 1. ⭐⭐ The constant tilt: `mrolloff`, and the measurement that sets it

Worn at `mrollk -0.5`: *"the picture is at a wrong angle more persistently"*
`[verified-live 2026-09-12, n=1 wearer]`. The cancel is the **excess over the baked pane**, so it
is zero by construction whatever roll the baked picture itself carries — **a fixed tilt is
invisible to it by design, not by accident.**

- **`mrolloff <deg>`** — a constant added to the applied angle, last and unconditional (it is the
  part neither measurement can see, so it must not be gated on either being valid). Harness → pane
  file → plugin, persisted. Sentinel for "not commanded" is **−999**, not −9, because **0 is a real
  value here** unlike the 0/1 knobs beside it.
- **⭐ The knob's value is measured, not guessed.** The plugin now computes the roll the **baked
  pane alone** gives against the rifle's up — the same quantity the cancel subtracts — and prints
  it once a second as `baked-roll`. It is **never applied**; it exists to be read.
  **If it reads non-zero and steady with the rifle held still, `mrolloff` is minus that number.**

That inversion matters: the row could have been "add a knob and sweep it in the headset", which is
three wears. It is now "read one number off the log, set the knob to minus it, one wear."

## 2. ⭐ Is the plugin's recomputed normal the one the Lua actually applies?

The per-tick normal (v3, tonight) assumes the plugin's joint anchor and muzzle axis reproduce the
Lua's `"eye"` model — which uses its own `anchor_pos` and can flip the bore (`flip_d`). If they
differ, the cancel's **magnitude** is off by exactly that angle, and that is the *other* reading of
"−1 over-corrects, −0.5 under-corrects" — indistinguishable from a wrong coefficient in the
headset, trivial to tell apart in a log.

`n-vs-lua` now prints the angle between the two, once a second, **as planes**: a normal's sign is
arbitrary, so the Lua's is flipped to the same side before measuring, or a perfect match would read
180°. `n/a` when steering is off or the Lua has not published — a meaningful reading, not a blank.

**Neither number is acted on.** Both are diagnostics; the applied angle is unchanged by this work
except for the offset knob, which defaults to 0.

## 3. ⚠️ The goat row was NOT the free cosmetic change it was written as

The row said *"hide the goat rig prop's mesh — cosmetic; the pane must stay."* Checking before
doing it: `rig_mesh_draw()` has existed since M19, but **the producer's own comment has asked since
2026-08-27 whether the mirror keeps producing with its host mesh hidden**, and nothing in the
dossier or the notes answers it. I could not find a single run that tested it.

So hiding it by default could blank the scope, and the row as written would have shipped that.

**Corrected to a one-command test instead:** `fn goat_hide` / `fn goat_show`, published to the
harness (the function existed; nothing driven could reach it). Default unchanged — the prop stays
visible. `[hypothesis]` that hiding is safe; one command each way settles it.

## 4. Verification

- Build clean. **All three numeric suites re-run against the changed source:**
  `mirror_roll_test` **176/176**, `crop_follow_test` **40/40**, `roll_math_test` **20/20**
  `[verified-numerically 2026-09-12]`.
- Both Lua files pass `luac -p`, and both `string.format` calls were run against dummy arguments:
  the pane file is **26 lines** and carries `mroll_off`; the harness log line takes its 18.
- **The C log line was arity-checked by tokenising the call**: 35 format specifiers, 35 arguments,
  and the last five line up (`%.2f`→`mroll_k`, `%d`→`src`, `%.1f`→`off`, `%s`→`baked_str`,
  `%s`→`ndiff_str`). `LOGI` is a variadic wrapper so the compiler does **not** check this, and this
  session added three fields to that line. ⚠️ Two earlier attempts at this check produced confident
  wrong numbers — one matched a different `crop-follow:` `LOGI` earlier in the file, the other was
  fooled by the string literals inside the *arguments* (`fresh ? "" : " HELD"`). A checker that
  cannot be wrong about which call it read is the point.
- **Interaction check:** the offset is added at the single site that already sums
  `roll_k·rifle_roll + mroll_k·mirror_roll`, so nothing else writes the applied angle. `baked-roll`
  and `n-vs-lua` are stores to atomics read only by the logger.

## 5. The next wear, in order, and what each outcome means

```
(rig up, model 0, steer 1 as usual)
cropfollow 1          <- the log line prints once a second; read it, then cropfollow 0
```

| what `baked-roll` reads, rifle held still | what it means |
| --- | --- |
| non-zero and steady (say −18°) | ⭐ that IS the constant tilt. Set `mrolloff 18` and look: the picture should sit level. |
| ~0 and steady | the tilt is **not** the baked pane's roll. Next suspects: `roll_k` (the rifle's own roll vs the camera, measured at 3–6° today and never applied — try `1.0`), or a fixed compositor-to-glass offset, which `mrolloff` still corrects empirically. |
| jumping about | the rifle is not being held still, or the bore axis is unstable — re-read before concluding. |

| what `n-vs-lua` reads | what it means |
| --- | --- |
| ~0° | the recomputed normal IS the Lua's. The strength is a genuine coefficient question: sweep `mrollk` between −0.5 and −1. |
| tens of degrees | ⭐ the magnitude is wrong for a *reason*. Fix the anchor/`flip_d` mismatch rather than tuning `mrollk`, which would only paper over it. |
| `n/a` | steering off or the Lua has not published — not a result. |

Then, separately, one command: `fn goat_hide` → picture survives? keep it. Picture dies?
`fn goat_show`, and record that the mirror needs its host mesh drawn.

## 6. What is NOT established

- **That `baked-roll` is the constant tilt.** It is the most likely source and it is now measured;
  the wearer's report and the number have not been put side by side.
- **That hiding the prop is safe** — see §3. Explicitly untested, by anyone, since 2026-08-27.
- **That the recomputed normal matches the Lua's.** That is what §2 exists to find out; today only
  the instrument was built.
- Nothing here changes the applied picture: `mrolloff` defaults to 0 and the two new numbers are
  read-only.
