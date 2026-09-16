# 2026-09-16f — scoped spread: no spread field is named on disk, so the plugin now asks the game (`/pd`, dev PC, Opus, NO LAUNCH)

**The game was not launched and nothing here has been run.**

## 1. The row

*Scoped weapons need zero, or near-zero, spread.* Without holding RG first, bullets land well away from
the crosshair when aiming through the scope `[reported 2026-09-14]`.

## 2. What could be found without the game

Nothing that names the value.

- The rifle's own files, read on 2026-09-16 for the zoom row, reference one mesh, one material file, a
  collider and **`app.WeaponGunCore`**. There are no spread or accuracy numbers with names on them
  `[inferred-static 2026-09-16]`.
- RE Engine keeps field names in the type database, which lives inside the running game. The plugin
  can walk it; the files on disk cannot be read that way.
- One likely reading, not checked: "holding RG first" is the game's aim state. Its spread shrinks while
  aiming, and firing straight through the scope without that state uses hip-fire spread `[hypothesis]`.
  If so, the fix may be either a spread value or forcing the aim state while the scope is used.

## 3. What was built (compile-verified, deployed on the dev PC, NOT run)

**`spreadprobe`** (harness). It is read-only and writes nothing to the game. On the next game tick the
plugin logs:

- **A. The vocabulary.** Every `app.*` type whose name mentions gun, weapon, shoot, bullet, aim,
  reticle or sniper. Under each, every field or method whose name mentions spread, scatter, dispersion,
  accuracy, deviation, recoil, diffusion, blur, random, stability, sway, bloom, shake, reticle,
  aim-assist, aim-rate or focus. Capped at 160 lines; the log says when the cap is hit.
- **B. The live weapon in hand.** The type chain of the equipped weapon object, then every number or
  true/false field with its current value. It also goes one level into sub-objects whose names look
  like parameters. Lines with a spread-like name are marked `***`. Capped at 220 lines.

Plugin 0 errors, 0 warnings. All six suites pass. The shader check passes, the three Lua files compile,
and the stubbed bring-up test passes 29/29. Dev-PC install re-stamped 14/14.

## 4. What is NOT established

- That any spread field carries a spread-like name. If part A finds nothing useful, the values may sit in
  unnamed user-data arrays instead.
- That the live weapon object holds the value, rather than a shared weapon table or the player's aim
  component. Part B only looks at the weapon and one level below it.
- Enum fields are printed as a 4-byte number. A smaller enum can print nonsense; treat enum values as
  labels only.

**The diagnostic that would show the approach is wrong:** run `spreadprobe` hip-fire and again scoped
with RG held, and no part-B value differs between the two. Then the aim state's spread does not live on
the weapon object. The next place to look is the player's aim or shooting component, found through the
same player chain the plugin already walks.

## 5. NEXT (one flat launch is enough)

1. Rifle in hand, not aiming: `spreadprobe`. Copy all the `spread-probe:` lines.
2. Aim with RG held: `spreadprobe` again, and copy the lines.
3. Hand both to the next `/pd`. A field that changes between the two, with a spread-like name, is the
   one to pin, and pinning it is a small plugin change.
