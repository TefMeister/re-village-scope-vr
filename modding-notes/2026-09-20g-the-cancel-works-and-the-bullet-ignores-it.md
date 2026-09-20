# The cancel works perfectly and the bullet ignores it (2026-09-20, `/pd` + a flat test by Tefa)

No crash this time. The write lands exactly as designed, and the shot is still random.

```
layout GOOD -- argc=7, both rotations read and unit
shot #1 scatter  1.228 -> 0.056 deg  mode=1 APPLIED
shot #2 scatter 11.188 -> 0.000 deg  mode=1 APPLIED
shot #3 scatter  0.581 -> 0.000 deg  mode=1 APPLIED
shot #4 scatter 12.018 -> 0.000 deg  mode=1 APPLIED
```

Tefa: *"no crash this time, but still random"* `[verified-live 2026-09-20, n=4]`.

## Why, and it was already written down

§9bd recorded the firing order this morning: `expendBullet` → `createBullet` → **`createBulletImple`**
→ `setupDiffusion` `[verified-live 2026-09-20, n=2]`.

**The bullet is finished before `setupDiffusion` runs.** So that function cannot aim it. Its two
rotations track the aim state perfectly — which is precisely why they *measure* the scatter so well,
and why zeroing them changes nothing about where the shot goes.

## ⚠️ The pattern, which is now the main risk on this project

This is the **fifth** time in three days that the answer sat in evidence we had already collected:

| § | what was already there | what was done instead |
| --- | --- | --- |
| 9av | a filename saying `swing-unchanged` | the swing was re-investigated |
| 9ax | an omitted `+0.2111` in our own output | a "12° mystery" was written up |
| 9az | `DiffusionRadius` on line 73 of our own probe | three days of looking for the spread number |
| 9bc | the `enableRestrictAimShake` block six lines above the line being quoted | a data table was hunted for |
| **9bg** | **the call order, written into this dossier by me** | **built a fix for the last step as if it were the first** |

**The rule has to be mechanical, because good intentions have now failed five times: before choosing
where to intervene, re-read the trace and say out loud which step runs LAST.** Had that sentence been
written on the previous pass, this build and two of Tefa's test rounds would not have happened.

## Also unexplained: `argc=7`

The signature matched has three parameters, which would make `argc=5`. Either an overload was hooked
or there are more slots than the signature implies. **The extra two must not be assumed to be
padding** — mode 3 below reports every slot, and the install now logs the hooked method's real
parameter list.

## What is built and waiting

**Mode 3, "look only" — it writes nothing.** `re_scope_vr.dll` 245,760 bytes, sha256
`03167e7150ad3e16…`, 0 errors 0 warnings `[compile-verified 2026-09-20]`.

- classifies **every** argument slot of `setupDiffusion`, `createBullet` and `createBulletImple`,
  guarded, each marked `UNIT-ROTATION` or `not-a-rotation` with its length² and components
- logs the hooked methods' **real** parameter lists via `get_params()` — method introspection, which
  is the documented pointer `invoke()` uses, **not** the `arg_tys` handles that crashed §9bf
- stops itself after six shots

**The test is two shots: one aimed, one from the hip.** Aiming gives ~0° and the hip ~8°, so whichever
rotation differs between the two traces is the one carrying the scatter — and if it sits in
`createBullet` or `createBulletImple`, that is where the cancel belongs.

⚠️ **NOT DEPLOYED — the game was still running and held the old DLL open.** Installed remains the
§9bf build (`b65ad8bd…`). `UPDATE-RIFLE-PLUGIN.bat` copies the new one in, refuses while `re8.exe` is
running, and prints the before/after size so a failed copy cannot read as a successful one. Switch
file left at `0 0`.

## What tonight did NOT cast doubt on

The measurement (§9bd), that the write lands, that `off` is inert, and that the scatter is a real ~8°
cone. **Only the choice of step was wrong.**

Credit: **praydog** (REFramework).
