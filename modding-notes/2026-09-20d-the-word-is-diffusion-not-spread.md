# The spread number was found on 2026-09-17 and nobody read it

**2026-09-20, home PC (RTX), `/lm`, two launches, flat, no headset.** Game launched, probes run,
game closed. No gameplay, no wearer.

## ⚠️ The headline is not what I first wrote

My first draft of this note said the 2026-09-17 probe had missed the field because it searched for
*spread / accuracy* and Capcom's word is *Diffusion*. **That is wrong, and the background reader
caught it before it reached the dossier.** Verified myself rather than taken on trust
(`plugin/src/probes.cpp:93`): the word list already contained

```
"spread", "scatter", "dispers", "accura", "deviat", "recoil", "diffus", "blur", "random",
"stabil", "sway", "bloom", "shake", "reticle", "aimassist", "aimrate", "focus"
```

**`diffus` was in there all along.** The vocabulary was never the gap.

## ⭐⭐⭐ What actually happened, and it is worse than a missed word

The 2026-09-17 probe **found it**. It is in the repo, in
`dev-archive/recon/2026-09-17-the-nine-builds-checked-in-the-headset/launch3-spread-probe.txt`,
**line 73**:

```
71  field IsDiffusion : System.Boolean
72  field DiffusionNum : System.Int32
73  field DiffusionRadius : System.Single      <-- the number, three days ago
74  field RecoilXAngle : System.Single
```

That file has sat in the repo since. Everything since — "spread is not a weapon field", "it lives
on the player or in the shot code", tonight's whole dig — was built on not having read past the top
of it.

**Why it was missed is structural, not careless.** The probe printed a starred summary first
(`*** isReduceRecoil`, `*** isRestrictAimShake`) and then the full dump. The summary was about
**part B**, the live weapon object, and for part B it was correct. That correct narrow result got
written up as the conclusion of the whole probe, while **part A — the type scan, 90 lines earlier in
the same file — held the answer.** The file even says `CAPPED -- more exist` at the end.

⚠️ **Third time in two days.** The `swing-unchanged` filename, the `+0.2111` I left out of the
arithmetic, and now this. All three: evidence present and unread, not evidence missing. **The
bottleneck on this project is reading what we already collected, not collecting more.**

## What tonight added on top

Two launches, six plus four types dumped `[verified-live 2026-09-20, n=1 each]`:

- ⭐⭐ **`app.WeaponGunCore.setupDiffusion(via.vec3, via.Quaternion, via.Quaternion) -> void`** —
  the function that installs the scatter on a shot. A position and two rotations, which reads like
  *(origin, intended direction, scattered direction)*. **It is a method, so it is hookable** — that
  is a far better lever than editing a data table, because it is where the decision is made.
- ⭐ **`app.ExclusiveModeData.WeaponCustomData`**: `IsDiffusionPowerUp`, **`DiffusionRadiusRate`
  (Single)**, `DiffusionAddNum`. A **rate multiplier on the radius** — the obvious scalar to take to
  zero, and the cheapest possible test if it is applied to the sniper.
- ⭐ **`app.CameraSniperParam.SniperZoomLevel`** — a whole sniper-specific shake block:
  `ShakeRateMax/Min`, `CheekPadShakeRateMax/Min`, `StandShakeStopSecond`, `CrouchShakeStopSecond`,
  `MoveShakePowerUpSecond`, `CamRotInputForceShakeRate`, plus `Fov` and `RotateSpeedRate`.
- `app.BulletDefault` carries `isDiffusion`, `diffusionNum` and **`isCenterBullet`** but **no
  radius** — so the cone is resolved at creation, one bullet being the centre.

## ⚠️ There are now TWO candidate mechanisms, and they are not the same fix

1. **Diffusion** — an actual cone applied at shot time (`setupDiffusion`, `DiffusionRadius`,
   `DiffusionRadiusRate`).
2. **Sniper aim shake** — the camera block above, which moves the aim *before* the shot leaves.

**Nothing yet says which one Tefa is seeing**, and they want different fixes. `[hypothesis]` A
shotgun is the obvious reason `DiffusionNum` exists at all, so a sniper may well have
`IsDiffusion = false` and get its scatter entirely from shake.

**The deciding read needs the rifle equipped** — `IsDiffusion` / `DiffusionNum` / `DiffusionRadius`
for weapon 6000. That is gameplay, not a headset.

⚠️ `app.ItemManager` **does not exist** in this game `[verified-live 2026-09-20]`, so the spec table
is not reachable through the manager name I guessed. The route runs through the live weapon
(`app.PlayerGunPl6000` holds `Inventory`) or through `findSpecByWeaponID`.

## Tooling

`reframework/autorun/re8_spread_dig.lua` — read-only, own command file, `DIG-SPREAD.bat`. Loaded and
ran first time; all 14 Lua API calls in it were checked against working scripts before the launch.
Output rescued to `dev-archive/recon/2026-09-20-spread-dig-diffusion-found/` (635 lines over two
files) before the next launch wipes the log.

⚠️ A `spec` command was added mid-session to hunt for the table's owner. **It has never run** —
autorun scripts load at startup and the relaunch happened before it was written. Untested code.

## Automation this session (the five capabilities)

| | |
| --- | --- |
| self-launch | ✅ twice, `LAUNCH-VILLAGE.bat` via Steam, unattended |
| menu → gameplay | ✖️ not attempted — the dig needed none |
| commands | ✅ the probe's own command file |
| character + camera | ✖️ not attempted |
| self-close | ✅ twice, `WM_CLOSE`, 15 s each |

⚠️ Closed with `WM_CLOSE`, not the in-game menu. Nothing was loaded either time — the game sat at
boot — so there was no save to corrupt, but it is recorded rather than glossed. **Menu→gameplay is
the gap that blocks the deciding read**, and it is the next session's first job.

Credit: **praydog** (REFramework), **gmankab** (the `pd-upscaler` fork).
