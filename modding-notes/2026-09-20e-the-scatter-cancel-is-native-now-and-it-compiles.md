# The hip-fire scatter cancel is native now, and it compiles (2026-09-20, `/pd`, home PC `RTX`)

**The game was not launched. Nothing here has been run.** Built, deployed, and waiting on one flat
test.

## Why this moved out of Lua

Four attempts from the Lua tool failed, and the last two failed for one reason: **a value-type
argument cannot be written from Lua.**

| attempt | result |
| --- | --- |
| `steady` — call `enableRestrictAimShake(true)` | the method takes **no arguments** and returns a bool; there was never anything to call `[verified-live 2026-09-20]` |
| `zero` / `swap` — re-point the `args[n]` slot | **no effect**: 10 hip shots, 8.649° avg against 8.429° with nothing on `[verified-live 2026-09-20, n=10]` |
| `skip` — `SKIP_ORIGINAL` on `setupDiffusion` | **inconclusive** — a logging-order bug in my own tool silenced the SHOT lines whenever it was on |
| `spec` — override `GunSpec.get_diffusionRadius` | **no effect**, and the trace then showed **why**: those getters are **never called** at firing time `[verified-live 2026-09-20, n=2]` |
| `fix` — `sdk.to_valuetype(...):write_float(...)` | raised no error and **changed nothing** on 3 shots — it hands back a **copy**, not a window `[verified-live 2026-09-20, n=3]` |

That is both of the two routes Lua offers. In the plugin, `argv[n]` **is** the address of the real
quaternion, so the write is an assignment that cannot silently fail. This is also the project's
standing preference — Lua was the right way to *find* the mechanism, and it did that job well.

## What was built

**`plugin/src/spread_fix.cpp`** (new, 190 lines), hooking
`app.WeaponGunCore.setupDiffusion(via.vec3, via.Quaternion, via.Quaternion)`.

- **It checks the argument layout before it writes anything.** `arg_tys[3]` and `arg_tys[4]` must
  both report `via.Quaternion`, or it refuses and says so once. A wrong index here would overwrite
  the shot *position*, which is far worse than a scattered bullet, so this is not left to assumption.
- **It measures, writes, then re-measures** — `scatter 8.412 -> 0.000 deg … APPLIED`. A write that
  does not take prints `WARNING -- the write did not take`. ⭐ **Every attempt from here on has to
  prove its own effect in the log**; three earlier ones each cost a round trip to establish nothing.
- **It counts calls seen against calls applied**, so "it changed nothing" can never again be confused
  with "it never ran" — the distinction the Lua attempts kept failing to make.
- **Rifle-only by default**, and it reuses a filter that is already correct: `world_tick` publishes
  `g_weapon_go` as non-null **only** when the scoped rifle is held (`world_tick.cpp:419`), so this
  tests `argv[1] == g_weapon_obj && g_weapon_go != nullptr` rather than walking the object graph a
  second time. `spread_all 1` widens it to any gun in hand.
- **Off by default.** Nothing changes until it is switched on.

**Live switching, so deciding the direction costs seconds not three relaunches.** `spread_fix_tick()`
polls `reframework/data/re_scope_spread.txt` twice a second. ⚠️ Its **own** file on purpose: the pane
file is steady-state and rewritten by the Lua producer, so a value poked in there would be
overwritten, and the settings file only takes effect at boot.

**`spread` and `spread_all` are also settings keys** — and they are **written** by `save_settings()`
as well as read. Read-only would have meant the next settings save silently erased a hand-added
line, which is precisely the class of record failure this estate keeps getting bitten by.

## ⚠️ What is NOT established

**Which of the two rotations is the one the rifle is pointing along.** On an aimed shot they are
identical, so no log can tell them apart, and the obvious test is **disproved**: comparing each
against `get_muzzleJoint` put *neither* near the barrel (15.0/13.1, 15.1/11.0, 10.9/9.5 degrees), so
that joint is in another frame `[verified-live 2026-09-20, n=3]`.

Hence two modes and one flat test. **The wrong mode scatters shots exactly as the game already does**,
so the failure is harmless and obvious. `[hypothesis]` that either mode fixes it at all — the write
landing is certain, its *effect* on the bullet is not.

## The one test, and what each outcome means

Rifle in hand, from the game folder:

| run | expected log | what it means |
| --- | --- | --- |
| `RIFLE-STRAIGHT-A.bat`, fire from the hip | `scatter N -> 0.000 deg mode=1 APPLIED` | the write landed. If shots go **straight**, done. |
| …and shots come out **random** | same log | the write landed but we kept the wrong rotation → run B |
| `RIFLE-STRAIGHT-B.bat`, fire from the hip | `… mode=2 APPLIED` | if straight, B is the shipped default |
| either, but `WARNING -- the write did not take` | — | the hook reached the wrong memory; **stop**, do not tune |
| no `spread-fix` lines at all | — | the hook never installed; read the install line at boot |

`RIFLE-STRAIGHT-OFF.bat` restores the game's own scatter at any time.

## Build and deploy

`cmake --build . --config Release` — **0 errors, 0 warnings** `[compile-verified 2026-09-20]`.
Deployed to `reframework/plugins/re_scope_vr.dll` (240,640 bytes, sha256 `10a93d94d61c10de…`), the
previous build kept beside it as `re_scope_vr.dll.pre-spread-fix-2026-09-20`, and re-recorded with
`deployed.sh record`. The switch file is created holding `0 0`, i.e. off.

⚠️ **Two build fixes worth remembering:** `API::get()` returns a `unique_ptr&`, not a pointer
(`auto& api`, as `world_tick.cpp:65` already does); and `find_method` does not resolve inherited
methods on `app.WeaponGunCore`, which is why `find_method2`/`find_method_deep` exist.

Credit: **praydog** (REFramework).
