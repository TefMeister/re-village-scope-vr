# 2026-08-25 — RenderOutput found; the camera works, and takes over

Late-night continuation of the 2026-08-24 evening session (see
`modding-notes/2026-08-24-evening-glass-display-solved-and-mirror-confirmed.md`).
All of it user-driven, no agents, no automated input.

## Headline

**The premise that RE Engine offers no second-camera path is wrong.** A single
read-only scan of the type database settles it.

## 1. Stop guessing, ask the TDB (numpad `+`)

Since M3 this project found render-target producers one at a time and argued
about each. The plugin can enumerate every type via `tdb()->get_num_types()` /
`get_type(i)`, so it now just asks. 114,234 types walked; **eight** expose
`set_RenderTarget` (`log-tdb-scan-8-rt-producers.txt`):

| type | what it's for |
|---|---|
| `via.render.RenderOutput` | **where a view gets rendered — the lead** |
| `via.render.RenderTargetOperator` | generic RT operation, unexamined |
| `via.render.Mirror` | planar reflection (proven producing, 08-24) |
| `via.gui.GUI` | "renders into", not "displays from" |
| `via.render.Bloodshed` / `Stamp` / `Wrinkle` | blood, decal and face-wrinkle splatting |
| `via.render.TextureSpreader` | texture distribution |
| `via.gui.ImageFilter` | alt accessor |

## 2. Read the working example instead of designing one

`via.render.RenderOutput` derives from `via.Component` (so it is attachable), and
the scene's single live instance sits on a GameObject named **`MainCamera`**
beside `via.Transform` + `via.Camera`, then ~40 optional post-process components.
Full readout in `log-mirror-success-and-renderoutput-recipe.txt`. The decisive
line:

```
get_RenderTarget = nil
```

The main view has **no** render target *because it draws to the screen*. So
setting one is exactly how a view is diverted into a texture — confirmed on
Capcom's own camera, not inferred. Also `get_RenderOutputID = 1` (ours must
differ) and `get_ClipingEnable = false` (the clipped grey half a planar Mirror
forces on us is simply absent here).

**A scope is therefore: Transform + Camera + RenderOutput, on the scope, aimed
down the bore, handed our render target.**

## 3. The camera works — and takes the player's view

Attaching a `via.Camera` to the rifle got it promoted to the scene's **primary
camera**: the main view rendered from the rifle, viewpoint inside Ethan's hands,
weapon "gone" because we were looking out of it. `RenderOutputID = 2` was not the
leak; the takeover came through the primary-camera slot.

**`via.SceneView` exposes `get_PrimaryCamera()` with NO setter.** The slot is
read-only, a takeover cannot be undone from Lua, and a game restart is the only
way out. An earlier SceneView dump had filtered method names for "layer"/"render"
— `get_PrimaryCamera` contains neither, so the filter hid the one entry that
mattered.

> **Lesson:** don't filter a list before you know what you're looking for.

## 4. The free seat

```
via.CameraType: Game 0, Debug 1, Scene 2, SceneXY 3, SceneYZ 4, SceneXZ 5, Preview 6
cameras alive in this scene: 1
  'MainCamera'  CameraType=0  DebugCamera=false  FOV=51.32
  CameraType 0 : 1 camera(s)
```

Those names are editor leftovers — three are orthographic layout views. **The
entire level contains exactly one camera**, and types 1..6 have **zero** users, so
joining one displaces nothing. This was checked rather than assumed because the
user asked the right question ("doesn't that mean we take something else's
place?") — the same question, unasked, is what caused both of the previous day's
failures.

Remaining risk is the inverse of the one feared: an editor-only camera type may
not render at all at runtime. Hence a picker rather than one hardcoded guess.

## Next session — exact steps

Reset Scripts → pick a camera type → **7** (RenderOutput on the rifle, ID 2, our
RT) → **3** (bind glass) → **8** (camera with the chosen type) → look at the glass
*and* at your own screen.

- View hijacked ⇒ that type behaves like `Game`; restart, try the next.
- Glass shows a real forward view ⇒ the scope is essentially solved; what remains
  is mounting it on the scope axis rather than the rifle root.
- Nothing at all ⇒ that type is editor-only; try the next.

Fallback if all six fail: steer `via.render.Mirror` by its host transform,
`n = normalize(d - b)` — a periscope. Already proven to produce a real picture.

**Standing rule: leave nothing auto-binding or auto-attaching between sessions.**
