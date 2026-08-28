# 2026-08-28 (home PC, evening) — the rig-mesh hunt: M18 → M26, live session

One long user-driven live session chasing the board's opener ("rig with a mesh → steerable
mirror pane"). The pane is still not steerable, but the session closed several questions for
good and produced two structural fixes that held under fire. Ten rounds of build → in-game
test → log read, all same evening.

## What was proven (all log- or screenshot-backed)

1. **The plugin teardown crash is closed — validated live.** The AddRef-latch fix (staging
   `6bc95e7`) survived multiple rig teardowns and full rebuilds in one session; the scope
   picture froze (stale latch, by design) instead of killing `on_present` like 2026-08-27.
   `via.GameObject.destroy(via.GameObject)` works and is safe to call now.

2. **A runtime-created GameObject via `create(System.String)` is born with NO folder**
   (`get_Folder` = nil; the rifle lives in folder `pl1000`), and **via.GameObject has no
   folder setter** — `get_Folder()` is the only folder method on the type. Folder membership
   is decided at birth: `create(System.String, via.Folder)` exists and works (read-back
   non-nil). All M8–M11 rigs were folderless.

3. **The M11 "camera contributes nothing" verdict was re-tested CLEAN — and stands.**
   The original control ran on an unregistered (folderless) rig through a display path later
   proven broken, so it was condemned on contaminated evidence. M25 re-ran it properly:
   in-folder rig, working plugin-latch display, RenderOutput(ID=2)+via.Camera(Debug), NO
   mirror = no other possible producer. Result: frozen picture. **The RenderOutput+via.Camera
   component pair does not render into an RT in RE8 no matter how the host is registered.**
   This negative is now solid.

4. **The mirror ignores its host completely — position AND rotation, registered or not.**
   With the in-folder rig driving (pose copy verified by heartbeat quaternion read-back,
   which swung with every slider move), fwd/up/right and pitch/yaw all changed nothing.

5. **`M-off` (hide host GO) freezes the mirror's output; disabling only the mesh component
   does not.** The mirror's production is gated by the host GameObject's draw flag, NOT by
   the mesh component. (So the 2026-08-27 "pane comes from the host's mesh" truth is still
   only supported by the meshless-rig-fallback observation — tonight neither confirmed nor
   killed it, because no runtime mesh ever rendered.)

6. **A runtime-created via.render.Mesh never rendered, through five escalating recipes:**
   - M18: borrowed mesh resource only → MaterialNum=0, component born DISABLED.
   - M20: + borrowed material resource (`it02_070_Sniperrifle_01.mdf2`) + enable →
     MaterialNum=4, MaterialReady/Linked=true, flag-identical to the rifle on everything
     M19a reads. Still invisible.
   - M24: reborn in the rifle's folder (`pl1000`), full stack. Still invisible.
   - M23: the differing flags (`DynamicMesh`, `MaterialsUpdatable`, `PartsUpdatable`) are
     all **getter-only** — set at birth by something we hadn't found.
   - M26: the **EMV Engine recipe** read from public source (alphazolam/EMV-Engine,
     `EMV Engine/init.lua` `create_gameobj`/`create_resource`): `.ctor` on the GameObject,
     `.ctor()` on the component, holders built via `create_instance("<T>Holder", true)` +
     `.ctor()` + `write_qword(0x10, resource_address)`, MDF = mesh path with `.mesh→.mdf2`.
     Every step logged success. **Still no visible mesh.** Post-M26 M19a/M21 (22:50):
     MaterialNum=4 / MaterialReady=true / MaterialLinked=true — but `DynamicMesh`,
     `MaterialsUpdatable`, `PartsUpdatable` remain **false**. The ctor DID do something
     (the earlier `GeometryHandle` disagreement is gone — both sides now agree), just not
     the registration that makes a mesh draw. **The EMV recipe as transcribed is
     insufficient in RE8** — either their spawner does more elsewhere (their GameObject
     wrapper, name-collision renaming while destroy defers, prefab-based spawning), or RE8
     blocks runtime mesh spawning specifically. Open research question for /gr: does EMV's
     own model viewer actually spawn visible meshes in RE8, and how do RE8 model-swap mods
     put new geometry on screen?

7. **`sdk.create_resource` for an already-loaded path hands back the same live backing** —
   after Reset Scripts wiped the Lua holder ref and M24 re-created it, the plugin's latched
   mirror source (from the pre-reset holder) kept receiving the new mirror's frames
   (picture live). The resource chain is path-cached engine-side.

8. **M21, the property differ** (`diff_getters`: walk the type's parent chain, call every
   zero-arg `get_*` on both objects, print only disagreements) is the new workhorse —
   it found the folder difference in one press. Keep it for every "why is mine different
   from Capcom's" question in any RE Engine project.

## Where this leaves the scope

- Mirror = the only working producer; content is live and near-final through the compositor,
  but the pane/plane cannot be aimed by anything tried so far.
- The one untested lever for pane control remains "a host mesh that actually renders" —
  blocked on the invisible-runtime-mesh problem, which now resists even EMV's public recipe
  as transcribed. Next candidates: study EMV deeper (their spawn passes through their own
  GameObject wrapper — something in there may matter, e.g. name-collision renaming while
  destroy is deferred, transform init, or a component order detail), or verify EMV's model
  viewer actually works in THIS RE8 install and diff live against ours.
- The beige wash over tonight's scope screenshots is plausibly the lens material's own
  FakeSpecular/FrontHole paint layered over our slot-1 texture — the T4 sliders hold those
  knobs (polish item, separate from steering).

## State at session end

Deployed = staging (plugin `6bc95e7` build, Lua with M18–M26 buttons). Everything this
session did in-game is runtime-only; one game restart restores stock. Nothing auto-binds or
auto-attaches on launch. The M26 rig (invisible mesh, no mirror) was left in-scene with
drive on; it does not touch the rifle and dies with the process.
