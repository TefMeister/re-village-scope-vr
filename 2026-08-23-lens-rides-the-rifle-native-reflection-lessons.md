# 2026-08-23 — The lens rides the rifle (M2b step 1) + three native-SDK lessons

**Result (user-verified in-game, flat screen):** the M2a scope lens now leaves its
corner park and pins itself to the rifle's muzzle — "very nice and steady,
doesn't lag behind at all." 283 consecutive locked ticks in the log; projected
pixel coordinates glide smoothly with camera and weapon motion.

## Architecture that got there

- **Game thread** (`on_pre_application_entry("BeginRendering")`): resolve the
  primary camera's pose and the equipped weapon's muzzle joint through the
  native reflection SDK, project the joint, publish a lens rect via atomics.
- **Render thread** (`on_present`): the existing M2a composite consumes the
  rect — lens placement AND crop center follow it (magnifier-over-the-rifle
  behavior). Corner park + screen-center crop while unresolved.
- **Projection is our own pinhole model** — camera position + rotation
  quaternion + `get_FOV`, our quaternion math, X-right/Y-up/−Z-forward. No
  engine matrix conventions involved; the log's `local=` triple verified the
  axis signs empirically (z negative with the weapon in front — correct).

## The resolution chain (RE Village / Ethan)

`app.PropsManager` → field `<Player>k__BackingField` → player GameObject →
`getComponent(System.Type)` with `app.PlayerUpdater` → `get_playerGun`
(returns the **app.PlayerGun component**) → `get_equipWeaponObject` →
**`app.WeaponGunCore`** → `get_muzzleJoint` → `get_Position`.
Camera: `via.SceneManager` (native singleton) → `get_MainView` →
`get_PrimaryCamera` → its GameObject transform for position/rotation.
(Chain studied from REFramework's RE8VR mod — praydog — and re-expressed;
study-not-copy.)

## Three lessons about the REFramework C/C++ plugin SDK (the hard-won part)

1. **Primitive float returns come back double-promoted in the invoke buffer.**
   `get_FOV` read as `.f` gives garbage (`-0.0`); the raw qword was
   `0x404F800000000000` = 63.0 **as a double**. Read `.d` and cast. By-value
   struct returns (via.vec3, via.Quaternion) are NOT promoted — raw floats in
   the buffer, memcpy works.
2. **`find_method` on a runtime type does not resolve inherited methods**
   (unlike Lua's `obj:call`, which walks the hierarchy). `get_GameObject` /
   `get_Transform` silently failed on `app.WeaponGunCore` (parent chain:
   WeaponShootableCore → WeaponCore → ItemCore) while the same calls succeed
   from Lua. Fix: walk `get_parent_type()` ourselves (`find_method_deep`).
3. **`get_equipWeaponObject` does not return a GameObject** despite the name —
   it returns the `app.WeaponGunCore` object itself. Its `get_muzzleJoint`
   (declared directly on WeaponGunCore, so no inheritance issue) is a better
   lens anchor anyway: it is the weapon's true barrel reference and doubles as
   the bore-sighting datum for the aim-point work.

## Diagnostics pattern that paid off

Per-tick stage tags naming the exact null link (`player-null`,
`getcomp-null`, `transform-null`, …) + one-shot "deep" dumps (type full names,
parent chains, filtered method/field lists, raw return bytes) fired on first
reaching a state. Three short game launches went from "stuck at the first
link" to fully working with zero guessing.

## Bonus recon (user, same session)

The F2 rifle has **fully modeled iron sights** under the scope (front post +
rear notch — screenshot verified). A "scope as an earned upgrade" mod
(scopeless rifle first, scopes purchasable) is art-complete on Capcom's side;
mechanics = hide scope mesh part (`app.ItemModifier`/`app.WeaponConfigure`
path) + suppress ADS FOV zoom & GUIScope when scopeless + shop-table work.
Parked as a Visceral-RE8 idea.

## Next

1. Aim-point-centered crop: muzzle joint rotation → barrel axis → project the
   bore ray's far point (one-shot axis-candidate log to pick the right local
   axis), so the lens shows where the bullet goes, not just where the muzzle is.
2. Body-joint + hand-tuned offset as the visual mount point (lens on the scope
   body, not the barrel tip).
3. M3 VR: per-eye composite, FOV-zoom suppression, GUIScope hide.
