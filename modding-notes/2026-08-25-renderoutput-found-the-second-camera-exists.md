# 2026-08-25 — the second camera exists after all

Continuation of the same night. Full session artifacts + preserved log
transcripts: dev-archive `recon/2026-08-25-renderoutput-found-camera-takeover/`.

## The one-line version

**RE Engine has a second-camera path. This project's founding assumption that it
doesn't is simply wrong**, and it took one read-only scan to prove.

## How the question got asked properly

Since M3 we found render-target producers one at a time — `via.gui.GUI`, then
`via.render.Mirror` — and argued about each on its own. But every type in the game
is catalogued, and the plugin SDK exposes `tdb()->get_num_types()` /
`get_type(i)`, so the catalogue can just be searched:

```cpp
for (uint32_t i = 0; i < tdb->get_num_types(); ++i)
    if (tdb->get_type(i)->find_method("set_RenderTarget"))
        LOGI("  [SET] %s", tdb->get_type(i)->get_full_name().c_str());
```

114,234 types, ~1.3 seconds, **eight hits**. Six were special-purpose (blood
splatter, decals, face wrinkles, texture spreading, GUI, Mirror). The seventh was
`via.render.RenderOutput`.

> Months of one-at-a-time discovery answered by one exhaustive query. Worth
> remembering the next time a question is being approached by accumulation.

## Don't design it — copy the working one

`via.render.RenderOutput` is a `via.Component`, and the scene's single live
instance sits on a GameObject called **`MainCamera`**, alongside:

```
via.Transform            where it is / which way it faces
via.Camera               what it sees (FOV, near/far)
via.render.RenderOutput  where the picture goes
...then ~40 optional post-process components
```

And the line that matters most:

```
get_RenderTarget = nil
```

The main view has **no** render target *because it draws to the screen*. Setting
one is therefore exactly how a view is diverted into a texture — verified against
Capcom's own camera rather than assumed. Plus `get_RenderOutputID = 1` (ours must
differ) and `get_ClipingEnable = false`, so the clipped half that a planar Mirror
forces on us is simply not a constraint here.

**A scope = Transform + Camera + RenderOutput, sat on the scope, aimed down the
bore, handed our render target.**

## The camera works. That's the problem.

Attaching a `via.Camera` to the rifle got it promoted to the scene's **primary
camera** — the main view rendered from the rifle, viewpoint inside Ethan's hands,
weapon "gone" because we were looking out of it.

`RenderOutputID = 2` was not the leak. The takeover came through the primary
slot, and **`via.SceneView` has `get_PrimaryCamera()` with no setter** — read-only,
not undoable from Lua, restart is the only exit. (I had claimed a rescue button
would fix it without restarting; that was wrong, asserted before checking, and is
corrected in the script and the commit.)

An earlier SceneView dump filtered method names for "layer"/"render".
`get_PrimaryCamera` contains neither, so **my own filter hid the one entry that
mattered.**

> **Lesson: don't filter a list before you know what you're looking for.**

## The free seat — and the question that got it checked

```
via.CameraType: Game 0, Debug 1, Scene 2, SceneXY 3, SceneYZ 4, SceneXZ 5, Preview 6
cameras alive in this scene: 1
  'MainCamera'  CameraType=0  DebugCamera=false  FOV=51.32  near 0.01  far 4000
```

Editor leftovers — three are orthographic layout views. The entire level holds
**one** camera, and types 1..6 have **zero** users, so joining one displaces
nothing.

That got counted rather than assumed because the user asked: *"doesn't that mean
we take something else's place and overwrite something else in game?"* Worth
recording that **the same question, unasked, is what caused both of the previous
day's failures** — the brute-force material bind and the unlatched GPU capture
were each "we took something else's place". An ID is an identity (collide and you
displace); a type is a category (join and you inherit its behaviour). Different
cautions, both needed.

## Where it stands

- **Display** — solved (our pixels on the scope's own glass, F9-verified).
- **Content** — solved twice over (Mirror proven; a real camera proven, too well).
- **Geometry** — the only open piece: keep our camera unpromoted, then mount it on
  the scope axis instead of the rifle root.

Next session is four clicks: pick a camera type → 7 → 3 → 8. Six types to try, a
restart between any that hijack the view, and `via.render.Mirror` steered by
`n = normalize(d - b)` as a proven fallback if all six turn out to be editor-only.
