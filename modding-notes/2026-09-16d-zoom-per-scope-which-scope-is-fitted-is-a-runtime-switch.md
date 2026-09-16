# 2026-09-16d — zoom per scope: which scope is fitted is not on disk, so the plugin now logs a scope signature (`/pd`, dev PC, Opus, NO LAUNCH)

**The game was not launched and nothing here has been run.** Three small files were read out of the
game's own archives into a scratch folder to answer this; none of them is committed.

## 1. The row

*Zoom per scope: less magnification for the stock scope, more for the high-magnification scope.*
Every test so far used the high-magnification scope only. The plugin today has one zoom for both,
chosen from a fixed list and cycled by hand.

To pick a zoom per scope the plugin first has to know **which scope is fitted**. Nothing in the
project records how to tell.

## 2. What the game's files say `[inferred-static 2026-09-16]`

Read with `dev-archive/tools/ree_pak_extract.py`:

- The rifle's in-hand prefab (`ri3042_inventory.pfb.17`) references exactly **one mesh**,
  `it02_070_Sniperrifle_01.mesh`, one material file, and a configuration file. The pickup copy
  (`ri3042_detailsearch.pfb.17`) references the same mesh.
- That material file (`.mdf2.19`) holds four materials: `A_Mat`, `B_Mat`, **`Lens_Mat`** and
  **`Lens2_Mat`**. Both lens materials use `Weapon_SniperScopeLens2.mmtr` and the same reticle
  texture, `Reticle_Low_ALBA`.
- The configuration file (`ri3042configuration.user.2`) only names a collider, `app.WeaponGunCore`
  and a sound monitor. No scope part.
- The mesh itself (`.mesh.2101050001`, 1.6 MB) names the same four materials and nothing about parts.

**So, unless the high-magnification scope is a separately attached object, both scopes are one mesh
and the difference is a runtime switch** `[hypothesis]`. The two obvious candidates are which lens
material is switched on, and a part-visibility switch on the mesh. The logs on disk only ever show the
high-magnification scope, where both lens materials are present and both get bound.

## 3. What was built (compile-verified, deployed on the dev PC, NOT run)

One read-only log line on every glass bind. The auto re-bind makes that every time the rifle comes
back to the hands:

```
[re-scope-vr] scope-signature: materials-enabled [m0=1 m1=1 m2=1 m3=1] parts=...
```

- `materials-enabled` uses the same enable read the tube mode already uses on this mesh.
- `parts=` reads part-visibility bits **only** if the mesh exposes both a part-enable call and a part
  count. Neither is verified to exist, so the line says `absent` or `present-but-no-count` otherwise.
  The count guard is there so the probe never reads past the end of an engine array.

Plugin 0 errors, 0 warnings. All six suites still pass. A comment-only rebuild gave the identical
hash, which confirms the build is reproducible. Dev-PC install re-stamped 14/14.

## 4. What is NOT established

- That the scopes differ in either of those two switches. If both lines come out identical, the
  difference lives somewhere else. The next places to look are a second attached object on the
  rifle, or a field on the weapon object itself.
- The zoom values themselves. Tefa's ask is "less for stock, more for high-mag". The plugin comment
  records 2.40× measured for stock and 2.58× for high-mag in flat play. The numbers to use in the
  headset are Tefa's call once both are visible.

## 5. NEXT (one flat or VR launch; the detection is flat-testable)

1. Rifle in hand with the **high-magnification** scope, `bind`: copy the `scope-signature` line.
2. Swap to the **stock** scope in the inventory (if the game allows detaching the part), rifle back
   in hand: copy the line again.
3. Different lines = the detection is known. The next `/pd` wires it to a zoom per scope, with two
   knobs. Identical lines = §4's first point.
