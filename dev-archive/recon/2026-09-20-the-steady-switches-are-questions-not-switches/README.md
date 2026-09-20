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

---

## ✅ RESOLVED THE SAME HOUR — the weapon was identified by Tefa, and the answer is the opposite

Tefa, minutes later: *"i now loaded a save with bullets, took 5 shots aim button held down, then
reloaded and took 5 hip fire shots too"* — so shots 1–5 are aimed, shots 6–10 are hip, and the
16-second gap between #5 and #6 is the reload.

| | shots | min | average | max |
| --- | --- | --- | --- | --- |
| **AIMED** (1–5) | 5 | 0.000° | **0.005°** | 0.023° |
| **HIP** (6–10) | 5 | 2.157° | **8.429°** | **14.930°** |

**The hip average is ~1,800× the aimed average** `[verified-live 2026-09-20, n=10]`. So the spread is
real, enormous, and applied as a cone at `setupDiffusion` — not aim drift and nothing to do with the
picture. The caution above was right to hold, and wrong about which way it would fall.

The measurement also validated itself: five exact zeros running, then five different large values. A
broken quaternion read cannot do that. The `[hypothesis]` on (intended, scattered) is promoted to
`[verified-live 2026-09-20, n=10]`.

**Fix written and deployed the same hour, NOT YET RUN:** both arguments are pointers, so re-pointing
the scattered one at the intended one in the pre-hook sends the shot along the aim. Applied after the
measurement so the log still shows what was cancelled. Which of the two is "intended" cannot be
learned from the log (on an aimed shot they are identical), hence `SPREAD-4-ZERO-ON.bat` and
`SPREAD-4-ZERO-SWAP.bat`, and the test is which sends hip shots straight.

Full write-up: dossier §9bd.

---

## ⛔ DISPROVED, SAME EVENING — re-pointing the argument slots does NOTHING

Tefa ran `zero on` (2 hip shots) then `zero swap` (8 hip shots) and reported *"still wild with both"*.
**"Still" is the operative word — the numbers are unchanged, not wrong-way-round:**

| | shots | min | average | max |
| --- | --- | --- | --- | --- |
| no override at all (earlier) | 5 hip | 2.157° | **8.429°** | 14.930° |
| `zero on` + `zero swap` | 10 hip | 0.034° | **8.649°** | 16.137° |

⛔ **So assigning to `args[n]` in a REFramework pre-hook does not reach these value-type arguments.**
That was an assumption stated as a mechanism (*"both arguments are pointers, so re-pointing the
scattered one at the intended one…"*) and it was wrong. It is kept in the tool only so the disproof
can be re-run.

⚠️ **And the framing given to Tefa was wrong too** — they were told that wild shots would identify
which of the two rotations was "intended". Both being wild means neither took effect, which is a
different thing. A test has to be able to tell "no effect" from "wrong choice", and that one could not.

⚠️ `weapon=?` — the `get_GameObject` route returned nothing, so the weapon still is not named. A second
attempt via `get_game_object()` is in place, untested.

## Two levers left, both on mechanisms that are reliable rather than assumed

1. **`skip on`** — return `SKIP_ORIGINAL` so `setupDiffusion` never runs. In the gun's method table it
   sits between `createBullet` and `createBulletImple` `[measured 2026-09-20]`, so the bullet is made,
   then diffused, then finished — skipping the middle step should leave it on the rotation it was made
   with. ⚠️ If the rifle stops firing or fires at a fixed spot, the step does more than diffuse.
2. **`spec on`** — override the RETURN of
   `app.ItemSpecificationData.SpecUnit.WeaponSpec.GunSpec.get_diffusionRadius` to `0.0` (and
   `get_isDiffusion` to false). Read-only getters, and overriding a return value in a post-hook is the
   most reliable lever REFramework has. ⭐ **This is also what a shipped fix should use** — zero the
   radius at source and the cone has nothing to open into. ⚠️ Global as built: every gun that asks
   loses its spread. Fine for a test, not for a release.

⭐ **`spec on` is falsifiable in the log, which the previous attempt was not:** if the number is really
read from there, the per-shot scatter itself drops to **0.000**. The tool also counts how many times the
spec getters answered, so "it changed nothing" can be told apart from "it was never asked".

Helpers: `SPREAD-5-SKIP-ON.bat`, `SPREAD-6-SPEC-ON.bat`, `SPREAD-7-ALL-OFF.bat`.

---

## ⛔ `skip` AND `spec` BOTH FAILED TOO — and the reason was in the data all along

Tefa: *"still randon i'm afraid"*. Log:

- **`spec on`** at 16:41:16, then five hip shots: **0.292°, 8.215°, 6.080°, 10.708°, 6.742°** — average
  ~6.4°, i.e. unchanged `[verified-live 2026-09-20, n=5]`. The spec getters were all found
  (`radius=true isDiffusion=true num=true`), so the hooks installed; but `status` was never run, so
  **whether the getters were ever ASKED is unknown** — the tool counted it and nobody read the counter.
- **`skip on`** at 16:40:24 → **no SHOT lines at all** before it was switched off at 16:41:09.

⚠️ **That silence was a bug in this tool, not a result.** The `SKIP_ORIGINAL` return sat **above** the
logging, so turning `skip` on silenced the very lines that would have judged it. **The `skip` test is
therefore INCONCLUSIVE, not failed.** Fixed: the skip is now the last thing the pre-hook does. Two
other flaws fixed with it — the bucket label only mentioned `zero`, so shots under `spec` were filed
as "as the game ships it"; and `spec off` printed the `spec on` wording.

### ⭐ The finding that should have stopped the guessing three attempts ago

**The two rotations handed to `setupDiffusion` already differ by ~8° at the moment it is called.** That
was in the very first measurement. So **the scatter exists BEFORE that function runs — it does not
create it, it receives it.** Which explains, after the fact, why nothing aimed at that function could
work: re-pointing its arguments, and skipping it entirely, were both attacking a step that only passes
the scatter along.

⚠️ **Three guesses in a row, each one plausible, each one aimed at the wrong place, while the
measurement was right every time.** The lesson is the one this project keeps relearning (§9az, §9bc):
**measure the mechanism before building a lever for it.** The per-shot numbers were trusted and
correct; every claim about *where the number comes from* was assumption.

## Next: a difference trace, which cannot come back empty

`trace on` (`SPREAD-8-TRACE-ON.bat`, read-only, 400-line budget) hooks the gun's whole firing path in
order — `shootCommon` → `gatherJoints` → `expendBullet` → `createBullet` → `setupDiffusion` →
`createBulletImple` `[measured 2026-09-20 from re8.exe]` — and logs **what the spec getters really
return** when asked.

**Then one aimed shot and one hip shot.** Aiming produces 0.005° and the hip produces ~8°, so the two
traces must differ somewhere, and wherever they differ is where the spread is decided. ⭐ Unlike the
three levers, this **cannot return "nothing happened"**: either the traces differ, or the deciding step
is not on this path at all — and that is itself a finding worth having.

⚠️ Still unresolved: the weapon is **never named** (`weapon=?` on every capture, both routes). And the
tool is now **785 lines**, at the code-shape soft limit — it must be split before anything else is added.

---

## ⭐⭐ THE TRACE PAID OFF — two things PROVEN, and the next attempt proves itself

One aimed shot (0.000°) and one hip shot (7.317°), `[verified-live 2026-09-20, n=2]`:

```
trace| expendBullet
trace| createBullet
trace| createBulletImple
trace| === setupDiffusion (the scatter is ALREADY in its arguments) ===
SHOT #1  scatter=0.000 deg      <- aimed
trace| shootCommon
```
…and the hip shot produced **the identical sequence**, differing only in the number: `7.317 deg`.

**Two hard results:**

1. ⭐ **The spec getters were NEVER CALLED — not once, on either shot.** No
   `GunSpec.get_diffusionRadius ->` line appears anywhere in the trace. So the spread is **not read
   from the weapon spec at firing time**, and that is *why* `spec on` did nothing
   `[verified-live 2026-09-20, n=2]`. Proven, where before it was "it didn't seem to work". ⚠️ A shipped
   fix must not go through those getters.
2. ⭐ **The call path is identical for an aimed and a hip shot**, and `gatherJoints` never appears at
   all. `shootCommon` fires *after* `setupDiffusion`, so it is the after-shot work (sound, recoil,
   ammo), not the decider. **The spread does not come from a different route being taken** — the same
   route carries a different number.

⛔ **So the scatter is computed by whatever calls `setupDiffusion`, before the call, and nothing on the
gun's own path reveals it.** That closes off guessing at this level entirely.

## What is left, and this time it cannot lie to us

We can **read** those two quaternions — the `valuetype` route has been right from the first shot. Only
**writing** failed, and only **one** way of writing was ever tried: reassigning the `args[n]` slot,
which does not reach a value-type argument.

**`fix on` (`SPREAD-9-FIX-ON.bat`) writes THROUGH the value type instead** — `write_float` at the four
offsets, falling back to field assignment, reporting which route took — and then ⭐ **re-reads the
arguments and measures the angle again**:

- `scatter after the write = 0.000 deg` → the write landed.
- `THE WRITE DID NOT LAND -- the number did not move` → it did not, and we know immediately.

**No one has to judge where a bullet went.** That is the property the last three attempts lacked, and
the reason they each cost a round trip to establish nothing.

⭐ **And the which-one-is-intended question is now settled numerically, not by trying both:**
`get_muzzleJoint` gives the barrel's own rotation, so whichever quaternion sits closer to the muzzle is
the direction the rifle points, and that is the one kept. The trace prints both angles.

## Code shape, honestly

Three disproved things were **removed from the working file**, per the code-shape rule, with their
write-ups left here: the `zero`/`swap` argument reassignment, the `steady` lever (both methods take no
arguments, so there was never anything to call), and the per-frame flag watcher (it proved across three
aim holds and 20+ shots that neither flag ever changes, and it was reading fields every frame).

⚠️ **Even so the tool is 832 lines, over our own 800-line soft limit.** The split is owed before
anything further is added to it, and is now a board row rather than a good intention.
