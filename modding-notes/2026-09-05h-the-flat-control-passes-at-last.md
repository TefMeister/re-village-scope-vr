# The flat control passes at last, and the eye-box is confirmed at n=2 (2026-09-05 evening, home PC, `/lm`)

Tefa launched and loaded a level; everything after that was driven from outside. The game was
**left running** — the next step is a VR run in the same session, not a relaunch. Evidence:
`dev-archive/recon/2026-09-05h-the-control-passes/`.

## 1. ⭐⭐ The control passes — the steering correction is finally a no-op on-axis

Flat ADS, on-axis confirmed by the plugin's own readout (`local=(0.00,0.00,-0.22)`,
`aim=(964,541)` — dead centre of 1920×1080). With `model 2` and `steerk 0.5`:

```
steer: ray from the LENS ANCHOR (Body joint + mount), 35.4 deg from the parked rig.
steer: model=corr k=0.500 bore=(1.00,-0.09,-0.01) eye->mirror=(1.00,-0.08,-0.00)
       arc=0.7 deg -> applied 0.3 deg
```

**`arc = 0.7°`, applied `0.3°`** — and the picture is the ordinary correct scene: upright reeds,
warm daylight, crosshair centred. Not the snow-and-fallen-log wreckage the two previous attempts
produced. `[verified-live 2026-09-05, n=1 launch, 12 consecutive steer lines all under 1°]`

The whole progression, measured rather than argued, all on-axis in flat ADS:

| the ray aimed at | arc from the bore | picture |
| --- | --- | --- |
| the rig's parked position (original) | **35.3°** | replaced entirely |
| the rifle transform's root (first fix — the grip) | **50.1°** | replaced entirely, worse |
| **the Body joint + mount offset (this)** | **0.7°** | **unchanged** |

Better even than the 3.9° predicted from the plugin's `joint=` field, because the mount offset lands
the anchor essentially on the bore in this pose.

**What this does and does not mean.** It means the correction is now the identity where it must be,
so the *implementation* is finally sound and a headset run can no longer be wasted re-discovering a
35° input error. It does **not** yet say the imaging law is right: `k = 0.5` and the half-angle model
are untested, because on-axis is exactly the case where every value of `k` behaves identically. That
is what the headset is for.

## 2. ⭐ The eye-box, confirmed at n=2

Second launch, same result on both lens materials:

```
eye-box HOLD [2]: 0.500 written every frame for ~1.5 s, reads back 0.100
eye-box HOLD [3]: 0.500 written every frame for ~1.5 s, reads back 0.100
```

`[verified-live 2026-09-05, n=2 launches, n=2 materials]` — so `EyeDistortionRange` genuinely cannot
be written through `setMaterialFloat`, and the earlier single-launch reading was not a fluke. Nothing
re-asserts it; our write simply never arrives.

## 3. Why the fix needed no new plumbing

The board's row read "publish the plugin's lens anchor to the Lua". It turned out not to need
publishing at all: the anchor is **the weapon's `Body` joint plus the mount offset
`(0, 0.151, 0.099)` in that joint's own frame**, which is the plugin's own construction and which the
Lua can compute directly. A cross-process channel dissolved into four lines of Lua.

The joint is cached and dropped on a rifle change, and if it is ever missing the ray falls back to
the weapon root **and says so loudly**, because that fallback is the 50.1° error above and must never
pass silently.

## 4. Automation, scored (§5a)

- **Menu → gameplay: not exercised** — Tefa had already loaded a level.
- **Commands: PROVEN** — command file plus numpad-by-virtual-key, whole cold order driven from
  outside.
- **Character + camera: not exercised.**
- **Self-close: not used** — the game was deliberately left running, because the next step is a VR
  run in the same session rather than a relaunch.

## 5. What is NOT established

- **The imaging law.** `k = 0.5`, its sign, and the half-angle model are all untested — on-axis
  cannot test them, by construction.
- Whether the correction behaves sensibly *off*-axis. That is the headset's job and the first thing
  it should look at.
- The px/deg gain, still. Unchanged from this afternoon: the noise floor swamps it.
