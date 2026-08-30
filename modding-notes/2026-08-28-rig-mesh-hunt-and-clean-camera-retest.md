# 2026-08-28 — the rig-mesh hunt (M18–M26): three closed questions, one that resists

One live evening session, ten build→test→log rounds, user driving the game. The mirror pane
is still not steerable — but the session turned several long-standing maybes into facts.

## Closed for good

**1. The RenderOutput + via.Camera path is dead, on clean evidence this time.**
The 2026-08-25 "camera contributes nothing" control was contaminated twice over: it ran on a
GameObject created with `create(System.String)` — which this session proved is born in **no
folder** (unregistered) — and it was judged through a glass-display path later shown to have
never displayed our texture at all. M25 re-ran it properly: rig born in the rifle's folder
(`pl1000`, via `create(System.String, via.Folder)` — read-back verified), working display
(plugin latch → glass), and **no mirror**, so nothing else could produce a pixel. Result:
frozen image. The component pair does not render to an RT in RE8, however its host is
registered.

**2. The mirror ignores its host's transform absolutely.** Position and rotation offsets,
registered rig or not, driving pose-copy verified by quaternion read-back — the image never
changes. Production is gated by the host GameObject's **draw flag** (hiding the GO freezes
the RT; disabling only the mesh component does nothing).

**3. `via.GameObject` has no folder setter.** `get_Folder()` is the type's only folder
method; membership is fixed at creation. Any experiment on a `create(System.String)` object
is an experiment on an unregistered object — worth re-checking older negatives against.

## Still open: a runtime-created mesh will not draw

Five recipes, each fixing the previous one's real defect, all invisible:
borrowed mesh resource only (MaterialNum=0, component born disabled) → + borrowed `.mdf2`
material + enable (flag-identical to the rifle on every readable property) → reborn
in-folder → the getter-only trio `DynamicMesh`/`MaterialsUpdatable`/`PartsUpdatable`
identified as birth-time states → **the EMV Engine recipe** (public source: `.ctor` on the
GameObject, `.ctor()` on the component, holders via `create_instance("…Holder", true)` +
`.ctor()` + `write_qword(0x10, resource_address)`). The ctor route erased the
`GeometryHandle` mismatch but left the updatable trio false and the mesh undrawn. EMV as
transcribed is not sufficient in RE8 — research task: verify EMV's model viewer in RE8
itself, and how RE8 mods that ADD geometry (not swap files) get it on screen.

## Tools + fixes that proved out tonight

- **The AddRef'd latch (plugin) held under fire**: repeated rig teardowns/rebuilds froze the
  scope image instead of killing `on_present` — last session's crash is structurally gone.
- **`M21 diff_getters`** — walk the parent chain, call every zero-arg `get_*` on ours and
  Capcom's, print only disagreements. Found the folder defect in one press. Reusable
  anywhere in RE Engine.
- **Rig survives Reset Scripts** (findGameObject reuse in `create_rig`) — and
  `sdk.create_resource` is path-cached engine-side, so the plugin's latched mirror source
  stayed live across a holder rebuild.

## Where the scope goes next

The mirror remains the only producer, its content near-final through the compositor, its
pane unaimable until a runtime mesh can be made to draw (or another pane mechanism is
found). Next session: (a) /gr research on RE8 runtime mesh spawning; or (b) accept the
rifle-hosted mirror and attack the remaining artifacts (clip half, lens paint layers) in
the compositor and via the T4 material sliders.

Evidence: dev-archive `recon/2026-08-28-M18-M26-rig-mesh-hunt/`; staging Lua has all
M18–M26 buttons; everything in-game was runtime-only, one restart restores stock.
