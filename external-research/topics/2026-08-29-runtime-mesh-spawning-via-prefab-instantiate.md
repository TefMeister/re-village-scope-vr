# Runtime mesh spawning in RE8: `via.Prefab` + `instantiate` — the answer to the M18–M26 wall

**Status: 🆕 new (2026-08-29, small hours). Directly answers the 2026-08-28 modding session's
top open question.**

## The question this answers

The 2026-08-28 session (see `re-village-scope-vr-modding-notes`
`2026-08-28-rig-mesh-hunt-and-clean-camera-retest.md`) established that a runtime-created
`via.render.Mesh` **will not draw in RE8** through five escalating recipes — borrowed
resources, borrowed `.mdf2` materials, a GameObject born in the rifle's folder, and finally
constructor calls on both the GameObject and the component. Every readable flag matched the
real rifle; the mesh never rendered. Pane control for the `via.render.Mirror` (the scope's
only working content producer) is blocked on exactly this, and the session named it the
project's linchpin.

## The answer, from public precedent

**Don't assemble GameObjects from components — instantiate a prefab.** RE Engine ships
`.pfb` files: complete, pre-authored GameObjects (mesh + materials + components + hierarchy)
that the engine spawns through its own registration path, so they arrive *born visible*.

The mechanism, described from alphazolam's **EMV Engine** source (the public REFramework
script collection whose Model Viewer / Prefab Spawner does exactly this, in RE8 among other
games — mechanism described in our own words, no code copied):

1. Create a `via.Prefab` managed instance (plain `sdk.create_instance` + constructor call).
2. `set_Path` it to a `.pfb` path (game-relative, i.e. strip `natives/stm/` and the trailing
   numeric suffix — same convention as `.rtex` paths).
3. Check `get_Exist` — confirms the prefab resolved before any spawn attempt.
4. Call **`instantiate(via.vec3, via.Folder)`** on it, passing a world position and a target
   folder. The engine builds and registers the whole GameObject itself.
5. Retrieving the spawned object: EMV samples the scene's `via.Transform` component list
   immediately before and after the call — the **newest object appears at index 0** — and
   treats "index 0 changed" as spawn-success. (Combine with this project's
   `snapshot_components` discipline; an index-0 read straight after the call is a tiny,
   safe read.)

Two corroborating claims from EMV's own README:

- *"In all games, PFB files (prefabs) can also be spawned, creating a new instance of the
  GameObject contained in the PFB"* — RE8 is explicitly in the supported-games list.
- On its component-list spawner: *"Spawning will not work well for complicated GameObjects
  with many components; use via.Prefabs for those."* — **public confirmation that raw
  component assembly (the M18–M26 road) is known-fragile, and prefabs are the sanctioned
  route.**

## RE8's prefab inventory (from Ekey's REE.PAK.Tool file list — 2,670 `.pfb` entries)

Highlights chosen for this project's needs (paths as game-relative):

| Prefab | Why it matters here |
| --- | --- |
| `environment/props/prefab/item/detailsearch/ri3042_detailsearch.pfb` | **A spawnable standalone copy of the F2 sniper rifle** — the "ghost rifle" the whole 08-28 session tried to build by hand. The `*_detailsearch` family are the small, clean item-inspection models (one per item, ~hundreds available) — ideal mirror hosts. |
| `character/it/prefab_resourceitem/ri3042/ri3042_inventory.pfb` | The rifle's own in-hand prefab. |
| `movie/prefab/c22e500_00_mirror.pfb` | **A cutscene MIRROR prefab** — plausibly a Capcom-assembled, working `via.render.Mirror` with a real pane mesh, ready to have its recipe read off a live object (this project's most productive method: the RenderOutput recipe and the M21 folder discovery both came from reading live objects). |

## What this unlocks — next modding-session experiments, in order

1. **Existence test:** spawn `ri3042_detailsearch.pfb` near the player. A visible object
   appearing = the wall is down.
2. **The steering test at last:** attach `via.render.Mirror` to the spawned object and drive
   its transform. Unlike the rifle, a spawned prop is *ours* — not joint-driven, not parented
   into a hand skeleton — so posing it cannot NaN anything, and truth 2 (pane follows the
   host mesh) finally gets a fair trial. If the pane steers: clip plane behind the scope,
   rifle out of frame, zero preserved — all three of the mirror's named limits fall at once.
3. **Read Capcom's mirror:** spawn `c22e500_00_mirror.pfb` and dump its components live
   (M21's `diff_getters` / F-report machinery already exists). If it carries a configured
   `via.render.Mirror` + pane mesh, its property values are the reference recipe.

Caveats to carry in: the `instantiate` overload EMV uses is `(via.vec3, via.Folder)` — reflect
it before calling per this project's standing rule; prefab resources may need a moment to
stream (hence the `get_Exist` check); cleanup is `via.GameObject.destroy`, proven safe on
2026-08-28.

## Sources

- alphazolam — EMV Engine (source read online via GitHub raw; README claims quoted above):
  https://github.com/alphazolam/EMV-Engine
- Ekey — REE.PAK.Tool, `Projects/RE8_STM_Release.list` (the RE8 file inventory):
  https://github.com/Ekey/REE.PAK.Tool
