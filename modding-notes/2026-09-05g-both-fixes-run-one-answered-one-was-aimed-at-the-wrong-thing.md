# Both fixes run: the eye-box is answered, and my steering fix was aimed at the wrong thing (2026-09-05 evening, home PC, `/lm`)

One flat launch, driven end to end, closed gracefully through `WM_CLOSE`. Plugin **149,504 B** and
the two fixes built earlier this evening, both previously unrun. Evidence:
`dev-archive/recon/2026-09-05g-both-fixes-run/`.

## 1. ⭐ The eye-box is settled, and it is the unhappy answer

The hold test wrote `0.5` every frame for ~1.5 s and read back on the last frame, on both lens
materials:

```
eye-box HOLD [2]: 0.500 written every frame for ~1.5 s, reads back 0.100
eye-box HOLD [3]: 0.500 written every frame for ~1.5 s, reads back 0.100
```

`[verified-live 2026-09-05, n=2 materials, 1 launch]`

Against the three-way table this was built to decide:

| reading | predicted | observed |
| --- | --- | --- |
| min clamp at 0.1 | ladder passes `0.500` through | ❌ killed by the ladder |
| game re-asserts every frame | a held write **wins** and reads back `0.500` | ❌ **killed by this test** |
| **the write never lands** | held write changes nothing, reads back `0.100` | ✅ **this** |

**So `EyeDistortionRange` is not reachable through `setMaterialFloat` at all.** Holding it at frame
rate for a second and a half moves it exactly as far as writing it once did: nowhere. That is
consistent with `set_material_float_verified` reporting failure under every encoding it tries.

What that leaves: the variable is read-only through this API, or it is driven from somewhere the
material does not expose, or we are writing an instance the renderer does not sample. **What it does
NOT leave is a writer to hunt** — a per-frame writer would have lost the race against a per-frame
hold, and it did not, because there is nothing to race. The row stays closed.

## 2. ⚠️ My steering fix was live, and aimed at the wrong thing

The fix landed and can be seen landing — the new log line says so:

```
steer: ray from ANCHOR, not the parked rig (they differ by 44.0 deg)
steer: model=corr k=0.500 bore=(0.99,0.00,0.11) eye->mirror=(0.64,-0.77,0.07)
       arc=50.1 deg -> applied 25.1 deg
```

**The arc got worse, not better: 50.1° against the 35.3° it replaced.** `[verified-live 2026-09-05,
n=1]`

The reason is in the vector. `eye->mirror` is now `(0.64, −0.77, 0.07)` — dominated by **−0.77 in Y**,
i.e. pointing steeply *downward*. I aimed the ray at **the rifle transform's own origin**, which is
the weapon root, down at the grip — not at the scope. The board's row said "the lens anchor" and I
implemented "the rifle position". Those are not the same thing, and they are about 45° apart.

**The flat control caught it in one launch, for the second time today.** That is twice this cheap
on-axis test has stopped a wrong steering model before it reached a headset.

### The right target was already in the log the whole time

The plugin publishes the lens anchor in its own world line as `joint=`. From the same on-axis frame:

```
cam=(38.60,-34.64,100.87)  joint=(39.62,-34.71,100.98)
```

Normalised, `eye → joint` is `(0.992, −0.068, 0.107)` at 1.03 m, against a bore of
`(0.994, 0.000, 0.110)`.

| ray aimed at | angle from the bore, on-axis |
| --- | --- |
| the parked rig (before) | **35.3°** |
| the rifle transform origin (my fix) | **50.1°** |
| **the plugin's lens anchor (`joint=`)** | **3.9°** |

`[verified-numerically 2026-09-05, from one on-axis frame]`

**3.9° is what "on-axis" should look like**, and the residual is honest — the lens anchor sits a few
centimetres off the bore line because the scope is mounted above the barrel.

So the next attempt is not a guess: **the Lua needs the plugin's lens-anchor world position.** The
plugin already computes it every frame from the weapon's Body joint plus the mount calibration; the
Lua has no route to it today. That is the `[PD]` row — publish it (a shared array, the same shape as
the VR bridge in the sibling project, or a joint lookup on the rifle transform that lands in the same
place) and re-run this control.

## 3. What went right about the process

Both of tonight's answers came from **controls that were designed to fail loudly**, not from features:

- the eye-box ladder and hold each named, in advance, which read-back meant which world — so the
  answer needed no interpretation;
- the flat on-axis control is a test the correct implementation *must* pass trivially, which is why
  it catches wrong ones cheaply.

Neither cost a headset session. The steering has now been wrong twice in ways that looked entirely
plausible in code, and been caught twice in minutes.

## 4. What is NOT established

- Any steering model, live. None has yet been given a correct ray.
- Whether `k = 0.5` is right — untestable until the ray is.
- Why `setMaterialFloat` cannot reach `EyeDistortionRange`; only that it cannot.
- Anything in a headset.
