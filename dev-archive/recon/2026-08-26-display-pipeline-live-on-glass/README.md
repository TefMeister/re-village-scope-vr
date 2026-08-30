# 2026-08-26 evening (home PC) — the display pipeline is LIVE on the scope glass

User-driven flat-screen session, real gameplay, F2 rifle with the High Magnification Scope
mounted. Two milestones and one precisely-characterized remaining problem.

## Milestone 1 — the reticle layer fills the glass (T3/T4, Lua)

- T4's float sliders originally skipped every `float4` shader variable (only scalar floats
  made the list) — `Reticle_UV_Scale_Offset`, the single most important knob, was never on
  a slider. Fixed (staging `d90f8a4`).
- Second bug behind "slider moves, nothing changes": `setMaterialFloat4`'s TDB signature is
  `(UInt32, UInt32, via.Float4)` — an engine value type, not REFramework's `Vector4f`. The
  call threw and the script's `safe()` wrapper swallowed it silently. Fixed by building a
  real `via.Float4` via `ValueType.new`, with every write verified by immediate read-back
  and loud logging (staging `156bf41`).
- With writes landing: `[3.2] Reticle_UV_Scale_Offset` on `Lens2_Mat` visibly controls the
  reticle layer's size and position on the glass. At (-0.1, -0.1) the layer **fills the
  entire lens** (screenshot 03). Negative scale mirrors the sample. UV scale works inverse:
  smaller magnitude = bigger picture.
- `[2.x]` sliders (Lens_Mat) produced no visible change with the high-mag scope mounted —
  consistent with Lens_Mat belonging to the OTHER (stock) scope attachment's mesh part,
  currently hidden. Unconfirmed; swap scopes to verify.

## Milestone 2 — the native plugin's render target displays LIVE on the glass

- Plugin un-parked (`re_scope_vr.dll.off-for-m8` → `re_scope_vr.dll`; byte-identical to
  staging `plugin/build/Release`, the post-failure-fixes build).
- On rifle detect the plugin auto-created + latched its target (`1280x728 fmt=29 flags=0x1`,
  latch closed for the session) and began the continuous blit.
- numpad `*` bound the glass cleanly: 4 materials scanned, `Lens_Mat`/`Lens2_Mat` matched,
  slot 1 bound on both, originals saved, **2 setMaterialTexture calls total**.
- **User-verified LIVE**: image on the glass moves with the world and changes color with the
  environment; F9 changes zoom preset and reticle style on the glass; numpad `/` cleanly
  restores stock. Screenshot 05.

## The remaining problem, now named: content feedback (Droste on the glass)

The plugin's image source is a backbuffer capture — but the backbuffer now contains the
glass showing that capture, so the loop feeds itself and converges to a hazy, environment-
colored mush ("a recording of a recording of a recording" — user). The doubled crosshair is
the same loop (drawn reticle + captured drawn reticle). **A screen-copy can never feed a
surface that is part of the screen.** Content must come from a genuine second scene render;
`via.render.Mirror` (proven producing into a created RT on 2026-08-24) is the designated
next source.

## Also this session

- 10-second freeze on "bind" traced in the log to a numpad `+` mispress (VK_ADD = the
  RT-producer TDB scan, 114,234 types walked on the game thread, 9.3 s). Not a bug; the
  key sits next to `*`. Screenshot 04 shows that attempt: overlay only, glass unchanged.
- Provenance rule paid off twice: read the log before theorizing (found the mispress),
  verify writes by read-back (found the silent float4 failure).

## Later the same night — FIRST TRUE SCOPE IMAGE (Mirror content on the glass)

Lua buttons 2+3 (attach `via.render.Mirror` to the rifle + bind glass to the Mirror's
holder) + the now-working UV/emissive sliders put a **live, right-way-up, recognizable,
non-recursive scene render on the glass**: the Duke at his caravan (06 = actual scene,
07 = through the scope). Two artifacts, both understood: the grey half = the planar
mirror's clip plane slicing the view (geometry — host the mirror on the controllable rig
instead of the rifle root); the blown-out lighting = raw un-tonemapped HDR render
(grading — correct at copy time in the plugin compositor's shader).

**💥 Crash gotcha:** `set_LightWeightMode` on a live, attached, rendering Mirror crashes
the game instantly (~23:25). If ever tested again, set it BEFORE attaching. No harm —
all state was runtime-only.

**Decision:** next build is the plugin compositor — mirror texture → glass target per
frame with exposure/tonemap, un-flip, zoom-preset crop, and the reticle drawn on top;
mirror hosted on a rig for clip-plane/aim control.

## Files

01 stock painted lens during ADS · 02 UV scale up = layer shrinks · 03 UV (-0.1,-0.1) =
layer fills the glass · 04 the `+` mispress (overlay only) · 05 plugin RT live on the glass,
feedback haze + doubled reticle · 06 actual scene (the Duke) · 07 Mirror content on the
glass (Duke visible; clip + exposure artifacts). Log: `re2_framework_log.txt` 22:19–23:2x
(22:50:57 latch, 22:51:10 scan freeze, 22:59:54 clean bind, ~23:25 LightWeightMode crash).
