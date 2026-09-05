# The ownership check now records its own token, and scope resolution is a settings number

`/pd`, home PC, 2026-09-05. **The game was not launched; nothing here was run.** Two `[PD]` rows
from the 2026-09-05 00:55 OPEN block. The third `[PD]` row (build the winning steering model
natively) is deliberately **not** touched: its shape depends on the outcome of the `[FLAT]`
steering sweep, which has not run.

## 1. The bind-order guard's ownership check

### What was wrong

`glass_bind_is_ours()` read each bound slot back with `getMaterialTexture` and compared the result
against `hook::scope_holder` — **the pointer we pass in to `setMaterialTexture`**. The engine is
under no obligation to hand that same managed pointer back, and the symptom says it does not: the
guard answered "not ours" on every pass and re-bound every 1.36 s for an entire session with no
visible effect (Tefa: no blinking). Nothing was wrong with the bind. The **check** was wrong.

### The fix

Each `GlassBind` now carries a new field, `ours`: what `getMaterialTexture` returned **immediately
after our own `setMaterialTexture` on that slot**. The guard compares a later read-back against
that instead of against the holder.

This is correct in both worlds. If the engine does round-trip the pointer, `ours == holder` and the
old comparison is subsumed; if it does not, the new one is the only one that could ever have
worked. A slot whose post-bind read-back failed stores `nullptr` and the guard treats it as "cannot
tell — leave it alone", matching the conservative style already used for a missing type definition
or a missing method.

No reference is taken on `ours`: it is compared as a pointer value and never dereferenced, and a
ref here would leak down the `forget_scope_glass()` path, which drops binds without restoring them.

### ⚠️ It also *measures* the diagnosis instead of assuming it

The bind now goes through one helper, `bind_slot_and_record()`, which logs both pointers:

```
glass:   material[N] slot M ownership token: holder=0x... read-back=0x... (<verdict>)
```

with the verdict spelled out as one of *"same pointer — the engine round-trips the holder"*,
*"DIFFERENT — the read-back, not the holder, is the token"*, or *"UNREADABLE"*.

**This matters more than the fix.** "The ownership check is a false negative" is currently
`[hypothesis]` — inferred from a re-bind that repeated harmlessly, not from anything measured. The
next run settles it in one line without any further work:

- **`DIFFERENT`** ⇒ the diagnosis was right, and the guard should now stop re-binding.
- **`same pointer`** ⇒ **the diagnosis was wrong.** The pointer does round-trip, the old comparison
  should have worked, and the 1.36 s re-bind has some other cause — most likely something else
  overwriting the slot between passes, which is a different and more interesting bug.
- **`UNREADABLE`** ⇒ that slot can never be ownership-checked, and the guard will leave it alone
  by design.

Note the guard's *behaviour* is only expected to change in the first case. If the log says "same
pointer" and the re-binding continues, that is not this change failing — it is this change
correctly reporting that we were chasing the wrong thing.

### One behaviour change beyond the fix, stated rather than buried

The old check opened with `if (holder == nullptr || g_glass_binds.empty()) return false;`. I
dropped the holder half, because the holder is no longer what the comparison uses. So in the corner
case *"binds exist, our texture is still installed, but `scope_holder` has gone null"*, the guard
used to answer "not ours" — logging *"our bind was replaced"* and calling `bind_scope_glass()`
every 1.36 s — and now answers "ours" and stays quiet.

That is the better answer (the guard's own stated job is *"strictly to take a bind back, never to
create one"*, and our texture really is still on the slot), and the old path was harmless anyway:
`bind_scope_glass()` opens with its own null-holder check and returns after one log line. Checked
rather than assumed. In practice `scope_holder` is stored once at creation and not cleared, so this
case is close to unreachable — it is recorded because it is a real difference, not because it is
expected to happen.

`[compile-verified 2026-09-05]` — VS2022 Release, zero warnings, both exports
(`reframework_plugin_initialize`, `reframework_plugin_required_version`) intact.

## 2. Scope resolution — `rt_scale` in the settings file

### What was wrong

Tefa, 2026-09-04: the scope picture is *"very low resolution"*. The OPEN row names two structural
levers. This is the first: the compositor render target is a fixed **480×360**, and the reticle
draws into it too.

### The lever

`rt_scale` is now a key in `reframework\re_scope_vr_settings.txt`, multiplying the shipped 480×360
and clamped to `[1, 8]`. Default `1.0`, and the existing settings file has no such key, so **nothing
changes until it is set** — Tefa's tuned values (GT curve 0.134, cropY 0.60, atmosphere package
off) are untouched.

Set `rt_scale=2` for 960×720, `rt_scale=3` for 1440×1080. **The RT is created once at D3D12 init,
so a change needs a restart, not a keypress.** The plugin logs the applied size when the scale is
not 1.

**One multiplier rather than independent `rt_w`/`rt_h`, on purpose.** `ps_main` draws the lens
circle, the vignette and all three reticle styles in **normalised** coordinates (`c.x`, `c.y`, `r`
— e.g. the fine cross is `abs(c.x) < 0.0028`, the vignette ring `r > 0.45`), so every one of them
scales for free at any resolution — but only while the aspect stays 4:3. Independent width and
height would let one typo turn the lens into an ellipse. `[verified-numerically 2026-09-05]` — read
out of the shader source, no resolution-dependent pixel constant anywhere in the lens, vignette,
reticle or source-mode indicator.

### ⚠️ The honest limit, recorded in the code and in the log

**This cannot add detail the source never had.** The magnified patch is only about 300 source
pixels wide, so raising the RT removes *our own* downsample and nothing else. Expect "less mushy",
not "sharp". Real new detail needs the other lever on the row — finding a larger `.rtex` for the
mirror latch to prefer — which is untouched here.

The runtime log says as much on every scaled run, so the number cannot be turned up in the belief
it does more than it does.

## Build and deploy

Before building my changes I built the **pristine** tree first: 140,800 bytes, matching the
deployed `re_scope_vr.dll` exactly. `[verified-numerically 2026-09-05]` That confirms the source
here is what is actually running and that these changes are the only delta — worth doing, because a
mismatch would have meant silently reverting the last live session's work.

Deployed: `reframework\plugins\re_scope_vr.dll`, 142,336 B, hash-verified against the build output.
Previous kept as **`re_scope_vr.dll.pre-bindtoken-rtscale-backup-2026-09-05`** (140,800 B) — restore
that file to undo both changes in one step.
