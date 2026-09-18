# Ethan cannot be hidden from the mirror alone — so hide him only while the scope is up

**2026-09-18, dev PC `DESKTOP-V8GTSIR`, `/pd`, Opus. THE GAME WAS NOT LAUNCHED AND NOTHING HERE
HAS BEEN RUN.** Everything below is static reading of the shipped binaries plus code that
compiles and passes its own suite against a stubbed engine.

Board row worked: the `[PD]` ⭐⭐⭐ row at the head of `status/re-village-scope-vr.md` — *"keep
Ethan out of the scope picture"*, Tefa's loudest complaint of the 2026-09-17 headset night:
*"Ethan's clothing really keeps getting in the way of everything"*.

The row asked three static questions. Two are answered, one is not.

---

## (a) Can our Lua flip REFramework's `HideUpperBody` / `HideLowerBody` / `HideArms`?

**No — and it does not matter, because the same strings show how to do the job directly.**

The three names are real and they are in the deployed `dinput8.dll`, but they are the **config
keys and menu labels** of praydog's own VR menu (`Hide Upper Body`, `Hide Lower Body`,
`Hide Arms`, `Auto Hide Upper Body in Cutscenes`, `Auto Hide Lower Body in Cutscenes` sit beside
them as the ImGui labels). They are **not** in the Lua binding surface:

- the full `sol` usertype field list for `class RE8VR` runs `get_weapon_object`, `get_localplayer`,
  … `left_hand_position_offset`, … `weapon`, `updater`, `inventory`, `transform`, `player`,
  `re8vr` — **no hide field anywhere in it** `[inferred-static 2026-09-18]`;
- the `reframework` Lua table exposes version / key / UI helpers and `save_config`, with **no
  config get or set** `[inferred-static 2026-09-18]`.

So there is no way to reach those toggles from a script. **But the mechanism behind them is an
ordinary engine call we can make ourselves**, and the string block spells it out completely:

```
app.PlayerMeshController           <- reached via get_playerMeshController
  UpperBodyMesh  LowerBodyMesh  LArmMesh  RArmMesh
  UpperBodyShadowMesh  LowerBodyShadowMesh  LArmShadowMesh  RArmShadowMesh  HeadShadowMesh
  set_DrawDefault(bool)   set_DrawShadowCast(bool)
```

`[inferred-static 2026-09-18, read from the deployed dinput8.dll and from re8.exe's type strings]`

Doing it ourselves is **strictly better than the menu toggle**, which is what makes this worth
building rather than just documenting: the menu setting is not saved across launches and costs the
player their body for the whole session, whereas a call we make can be **timed** — body gone only
while the scope is actually up.

### Two things the game exposes that REFramework does not touch

Read off `app.PlayerMeshController` in the same block `[inferred-static 2026-09-18]`:

- **`FaceMesh`, `HairMesh`, `WeaponMesh`, `OtherMeshList`** — more mesh handles than REFramework's
  three toggles reach.
- **`IsAimSniperRifle`** — *the game's own flag for "the sniper scope is up"*, sitting on this very
  type next to `IgnoreDepth` / `disableIgnoreDepth`. If it reads true when the scope is raised,
  it is a far better trigger than anything we could infer, and it is the first thing `bodyprobe`
  prints. ⚠️ **Adjacency in a strings blob is ordering evidence, not proof that this field hangs
  off this type at runtime.** That is exactly what the probe is for.

---

## (b) Can the player's meshes be kept out of the mirror pass alone?

**No. No such flag exists.** This is the load-bearing negative of the session, and it is the reason
the answer had to become a timing trick rather than a masking trick.

- The **whole per-pass draw family** on the mesh side is `DrawDefault`, `DrawShadowCast`,
  `DrawFarCascadeShadowCast`, `DrawEnvmap`, `DrawVoxelize` (with `DrawDepthOcclusionFlag` readable)
  `[inferred-static 2026-09-18, re8.exe type strings]`. **None of them is planar-reflection
  specific.**
- `via.render.Mirror` has **zero fields anywhere in its chain and eight methods, none geometric**,
  and none a layer or draw mask `[verified-live 2026-08-25, n=1,
  `dev-archive/recon/2026-08-25-renderoutput-found-camera-takeover`]`.

So there is no way to say *"draw this mesh in the main view but not in the mirror"*.

**The one untested member of that family is `DrawEnvmap`** — named for cubemap probes, not planar
reflections, so it is expected **not** to help `[hypothesis]`. It costs nothing to find out, so
`bodyprobe` reports it per mesh alongside `DrawDefault`.

**Therefore: hiding is all-or-nothing per frame, and must be timed instead of masked.**

---

## (c) What clips the mirror, for the ground when crouched?

**Not answered, and left on the board.** It is geometry — the pane plane sinking below the terrain —
not a flag, so it does not yield to the kind of reading done here.

---

## What was built

New module `staging/re-village-scope-vr/scripts/re8scope/body.lua` (313 lines), plus two harness
words. It is deliberately **two commands, not one**, because everything in (a) is
`[inferred-static]` and must be measured before it is trusted:

| word | what it does |
| --- | --- |
| `bodyprobe` | **READ-ONLY, changes nothing.** Finds `app.PlayerMeshController` by three routes and says which one worked, then lists every one of the 11 mesh fields as present or absent with its `DrawDefault` / `DrawShadowCast` / `DrawEnvmap`, and prints `IsAimSniperRifle` and `IgnoreDepth`. **One launch turns every `[inferred-static]` claim above into a measured one.** |
| `bodyhide <0\|1\|2> [set]` | `1` = auto (gone only while the scope is up, back when lowered), `2` = hide now and hold, `0` = off and put it back. Optional set: `body` (default, with the shadow meshes), `arms`, `shadow`, `all`. |

Design points that matter:

- **`bodyhide` refuses to write to a mesh field the probe has not seen.** If it is called first it
  runs the probe itself, and if the probe finds nothing it changes nothing and says so.
- **Restoring puts back the value that was there**, per mesh — not a hardcoded `true` — so a mesh
  the game had already hidden stays hidden.
- **Auto is edge-triggered**: it writes on the scope going up and coming down, and only *reads* in
  between. While hidden, a mesh that something else turns back on is re-asserted and **counted**,
  and the count is in `bodystatus` — so if REFramework's own `AutoHide…Cutscenes` logic fights us,
  that shows up as a number rather than as a flickering picture. `[hypothesis — the fight is
  anticipated, not observed]`
- **Three routes to the mesh controller** (`re8vr.player:getComponent`, `get_playerMeshController`,
  a scene walk), logged so the next session can drop the two that lose — the standing rule about
  building several routes and measuring which the game obeys. The scene walk goes through
  `snapshot_components`, so it survives the list decay that made three earlier sessions' scans
  "prove" things were absent.
- **No fallback trigger, on purpose.** The producer's shared state says whether the *rig* is alive,
  never whether the player is looking down the scope, and the harness's `ads` flag **drives** the
  trigger rather than reading it `[inferred-static 2026-09-18]`. If `IsAimSniperRifle` does not
  read, auto says so and does nothing, and `bodyhide 2` tests the rest of the mechanism honestly.

### Verification

`tests/body_hide_test.lua` — **27/27**, driving the *shipped* `body.lua` against a stubbed engine
`[verified-numerically 2026-09-18]`. It covers inert-on-load, the probe-first guard, save/restore
fidelity, edge-triggering, the re-assert counter, all four set words, absent fields and a missing
controller.

**The suite was proved able to fail**, three separate ways — restore hardcoded to `true` (fails 2b,
2c), the edge trigger removed (fails 3a, 3d, 4b), and the module booting in auto instead of off
(fails 0a, 0b, 0c). Each break was reverted and the suite returned to 27/27.

All other suites pass unchanged: `bringup_sequence` 29/29, `steer_axis` 61, `steer_corr` 71,
`hand_higher` 5/5, `producer_globals_check` PASS, `producer_split_check` **49/49** (48 before —
the extra check is this module's callback; see below).

---

## Three defects found on the way, all fixed

These were not the row, but each one was silently costing something.

1. **The dev PC's install was a whole milestone behind and nothing had noticed.** The installed
   producer was the **pre-split 6,758-line single file**, with no `re8scope/` folder at all, while
   staging HEAD has carried the 57-line entry plus 13 modules since 2026-09-17. The 09-17 board
   entry's *"the 09-16 builds are installed here"* was true of the **home PC**, not this one.
   `deployed.sh check` could not catch it — it answers *"is the install still what we stamped?"*,
   not *"is the stamp the newest build?"*, which is the limitation the board already records.
   **Fixed:** staging HEAD + this module deployed, old producer kept as
   `.bak-2026-09-18-pre-split`, all **28** files hash-verified against staging and re-stamped.
2. **`producer_globals_check.py` had the HOME PC's user folder hardcoded** as the path to
   `luac.exe` (`C:\Users\TD3KX\...`), so on this machine it died with `WinError 2` and **had never
   once run here**. Fixed to look on `PATH` first, then the logged-in account's own install, then
   the old path. It now runs, and it immediately earned its keep by catching a real global read in
   the new module (`re8vr`, REFramework's own — allow-listed with the reason written down).
3. **Two test suites errored when run the documented way.** `steer_axis_test.lua` and
   `steer_corr_test.lua` resolved their sources as `scripts/re8scope/…`, which only opens from the
   repo root, while every sibling suite is documented *"Run from scripts/"*. So
   `for t in tests/*.lua` from `scripts/` made exactly those two **error** while the rest passed —
   which reads like breakage, and would hide a real failure in either. Both now resolve relative to
   their own file and pass from both places (61 and 71 checks). **They were passing all along; only
   the invocation was wrong** `[verified-numerically 2026-09-18]`.

`producer_split_check.lua` was updated from 48 to 49 checks. It is a move-only guard asserting the
2026-09-17 split changed nothing, and `body.lua` is the **first deliberate addition since** — so its
three globals and its one `on_frame` callback were added to the expected lists, with the reason in
the file. Everything the split itself moved is still checked unchanged.

---

## What is NOT established

- **That any of this removes Ethan from the scope picture.** The mechanism is proven to be *callable
  and correctly sequenced*; whether `set_DrawDefault(false)` on those meshes actually takes the body
  out of a `via.render.Mirror` **reflection** is untested. A planar reflection re-renders the scene,
  so it ought to honour the same per-mesh draw flag — but that is `[hypothesis]`, and it is the whole
  bet. **If the body still appears in the scope with everything hidden, the reflection pass does not
  honour `DrawDefault`, and this route is dead** — which is worth knowing in one launch.
- **That `IsAimSniperRifle` means what its name says**, or that it lives on this type at runtime.
- **That the field names are right at all.** They are string-table reads.
- Whether hiding the body while scoped is even pleasant in a headset. It may feel worse than the
  clothing. That is Tefa's call, and `bodyhide 0` puts it back instantly.

## The one launch that decides it

Flat is enough — this needs no headset.

```
bringup
bodyprobe
```

- **`found app.PlayerMeshController via …` plus a list of meshes with `DrawDefault=true`** → every
  field name above is confirmed, and `bodyhide 2` is worth trying in the same launch.
- **`IsAimSniperRifle field=true`** while scoped (and `false` when not) → auto mode has its trigger
  and `bodyhide 1` is the real feature.
- **`IsAimSniperRifle field=nil` / `(no getter)`** → auto cannot work; `bodyhide 2` still tests
  whether hiding clears the picture, which is the question that actually matters.
- **`NOT FOUND by any of the three routes`** → the type name or the access path is wrong, and
  nothing else here can be trusted either.

Then, with `bodyhide 2` on: **does Ethan's clothing leave the scope picture?** That single yes/no
decides whether this is the answer to the row or a dead end.
