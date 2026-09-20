# The two "steady switches" are QUESTIONS, not switches — and the measured scatter is ~zero (2026-09-20, live, flat, Tefa at the keyboard)

One session, no headset. Tefa equipped the rifle, ran `SPREAD-0-FLAGS.bat`, held the aim button three
times, and later fired four shots. Log: `spread-kill-log.txt` (the whole `[spread-kill]` stream,
verbatim).

## What worked

- ⭐ **Capture without firing works.** `onEquipWeapon` is **not** on `app.WeaponGunCore` — the tool said
  so and fell through to `updateScope`, which caught the gun 8 seconds later
  `[verified-live 2026-09-20, n=2 captures]`. The zero-shot route is real.
- ⭐ **The scatter measurement is live and sound.** Shot #1 read **0.023°** and shots #2–4 read
  **0.000°**. A broken quaternion read would have produced the *same* number every time; a value that
  varies once and then settles is genuine data. That is the validity check, arrived at by accident.

## What it says — and the main hypothesis is DISPROVED

**`enableRestrictAimShake()` and `enableReduceRecoil()` take NO arguments and return `System.Boolean`**
`[verified-live 2026-09-20]`. They are **questions the gun asks itself**, not setters. The whole
"call them with `true` and leave them on" plan (dossier §9bb) cannot work as written.

⭐ **The tool refused to call them** rather than guessing, which is the only reason this is a finding
instead of a silent no-op we would have believed. The signature check earned its place on its first
outing.

**And aiming does not touch them.** Across three deliberate aim-button holds and four shots:

| Flag | Value | Ever changed? |
| --- | --- | --- |
| `isRestrictAimShake` | **`true`**, from the moment the rifle was drawn | **no** |
| `isReduceRecoil` | **`false`** | **no** |

So *"hold RG for it to turn accurate"* is **not** these two flags being flipped
`[verified-live 2026-09-20, n=3 aim holds + 4 shots]`. Aim shake is already restricted all the time,
including at the hip.

**`isDiffusion` and `diffusionRadius` are not fields of `app.WeaponGunCore`** — both read `nil` on the
live object `[verified-live 2026-09-20]`. They live on the weapon **spec** (§9az:
`app.ItemSpecificationData.SpecUnit.WeaponSpec.GunSpec`), which still has to be reached.

## ⚠️ The part that is NOT established, and it matters

**Nothing proves those four shots came from the sniper rifle.** The tool logged
`captured the gun in your hands … capture #2` at 16:25:35, two seconds before the first shot — a
**second, different** `WeaponGunCore` object. Tefa had said the save had no rifle ammo
(*"not shooting as i am in a save with no bullets left"*), so a different weapon is the likely
explanation. **The tool does not record which weapon it has hold of, and that is a hole in it.**

⛔ **So do not conclude "the sniper rifle has no spread".** What is established is that *some* gun
scattered by essentially nothing on four shots. The obvious and important reading — that the rifle has
no diffusion cone at shot time, and the inaccuracy Tefa sees is the aim moving rather than the bullet
being thrown off — **is `[hypothesis]` until the weapon is identified.**

## Next, in order

1. **Make the tool say which weapon it has** — log an identifier on capture and on every shot. Until
   then every scatter number is unattributed. (`app.WeaponGunCore` has `get_Inventory`,
   `get_isPlayerEquip`, `get_usingBulletIndex`; the exe also shows `CurrentWeaponID` on the player's
   weapon-handling component.)
2. **Dump the live gun's whole field list** (`SPREAD-2-READ.bat`) — free, needs no ammo, and it will
   name whatever identifies the weapon rather than making us guess method names.
3. **Reach the weapon spec** for the rifle and read `IsDiffusion` / `DiffusionNum` / `DiffusionRadius`.
4. **Re-run the four shots with the rifle confirmed in hand**, and with ammo.

## What this kills

- The `steady on` command as built. It would have called nothing. Left in place but it must not be
  reported as a working lever.
- The idea that the aim button's accuracy lives in `isRestrictAimShake`.

## What it opens

- `enableRestrictAimShake()` being a **question** means the lever is to **hook it and force the
  answer**, not to call it — but since it already answers `true` at the hip, that particular answer is
  not what aiming changes. The same trick on `enableReduceRecoil()` (permanently `false`) is untried
  and is about recoil, not spread.
- If the scatter really is ~0 for the rifle, **the whole spread framing is wrong** and the job becomes
  the aim's own movement. That would also explain why `DiffusionNum` looked like a shotgun feature.

Credit: **praydog** (REFramework). The test was run by Tefa at the keyboard.
