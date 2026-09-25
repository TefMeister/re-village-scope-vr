# 2026-09-25 16:05 — the render layer order, with the scope up (home PC, VR, multipass)

Taken with the `layerorder` / `layerfields` / `layerapi` words of `re8_scope_layer_knobs.lua`, rifle out, in the Duke's room.
`[verified-live 2026-09-25, n=1 launch]`

- The parent `via.render.layer.Output` holds six children, in this order: OutputCommon · **Scene view=2, camera A, OUR mirror** ·
  Scene view=0, camera A (the main eye) · **Scene view=3, camera B, OUR mirror (the layer we capture)** · Scene view=1, camera B
  (praydog's cloned eye) · OutputOverlay. So one via.render.Mirror gets a Scene layer PER EYE CAMERA, and each mirror layer sits
  BEFORE its eye's layer.
- Native render-layer types carry no TDB fields (the field dump printed 0 for the layer, its mirror and its parent).
- `via.render.RenderLayer` has `getPriority()`, `get_Independent()`, `removeLayer(RenderLayer)`; `via.render.layer.Output` has
  `setLayerIndex(UInt32, UInt32)`, `get_BeginLayerIndex()`, `get_EndLayerIndex()`, `get_Mask()` — a reorder is possible from Lua.
- Hypothesis it feeds: if the frame's shadow-casting-light budget is handed out in this order, the two scope views claim it first
  and the eyes get the leftovers — Tefa's "the world is lit as seen from the scope". Next: `layermove` (setLayerIndex) puts the
  mirror layers after the eyes and Tefa judges the lights. `[hypothesis]`
