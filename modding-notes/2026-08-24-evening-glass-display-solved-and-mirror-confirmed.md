# 2026-08-24 (evening, home PC) — the glass displays, and Mirror really renders

Session framing (user): *"it went all wrong at dev pc and i'm actually glad it did.
means we gotta work together, neither of us on our own is not gonna crack this."*
Run collaboratively start to finish — no autonomous agents, no automated input, the
user driving every in-game step. That is also what caught two of the four findings
below.

Two things that were open since M3 are now closed, and two of my own bugs cost the
session a crash each along the way. Both are written up honestly because the second
one only happened because I "fixed" the first one wrong.

## 1. The brute-force bind is gone (narrow + reversible + manual)

`bind_holder_to_mesh()` — every mesh in the scene, 5615 meshes / 44920
`setMaterialTexture` calls, no restore path, auto-firing on weapon detect from the
present thread — replaced by `bind_scope_glass()`:

- **Narrow:** starts from the equipped rifle's GameObject only. No rifle in hand, it
  does nothing. No scene-wide path remains in the file.
- **Reversible:** reads the original holder back via `getMaterialTexture` and saves it
  first. **A slot whose original can't be read is skipped, not written.** Never
  overwrite what you can't put back.
- **Manual:** numpad `*` / numpad `/`. Removing the keypress gate is what turned a
  proof of concept into an unattended game-wide overwrite.

Verified in real gameplay. Name-matching found both lens materials unaided:

```
glass: rifle mesh has 4 material(s) -- scanning for the lens
glass:   material[2] it02_070_Sniperrifle_01_Lens_Mat   <-- LENS
glass:   material[3] it02_070_Sniperrifle_01_Lens2_Mat  <-- LENS
glass: 2 slot(s) bound, 2 setMaterialTexture call(s) total
```

44920 -> 2.

## 2. DEVICE REMOVED — and the lesson is about "fixing" accidents

Full report: dev-archive `recon/2026-08-24-FAILURE-device-removed-unlatched-capture/`.

The D3D12 capture hook never *identified* our resource. It stored "the last Texture2D
allocated while armed" and hoped. What kept that working was an accident:
`check_and_report()` disarmed after ~1 frame, freezing the pointer just after our own
allocation landed. **It was acting as a latch and nobody knew.**

I spotted that as a race and removed it. The race was protective. 47 streamed game
textures then each took a turn, the last being a 1024x1024 BC7 with no
`ALLOW_RENDER_TARGET`, and the blit built a PSO for it and drew into it — illegal in
D3D12, `DXGI_ERROR_DEVICE_REMOVED`, hard freeze.

It also **re-explains the earlier dev-PC corruption better than the brute-force bind
did.** Same pointer drift there; the difference is it landed on a legal RT format, so
the scope image was written into a real game texture every frame instead of killing the
device. "All the colours went low-poly / cell shaded" fits *the game's own textures
being overwritten* far better than a reticle-slot swap does. Same bug, two costumes.

Fix: identify by the signature of what we asked for (Texture2D + `ALLOW_RENDER_TARGET`
+ 1280 wide + height 700..768), **latch on first match**, then store nothing further and
disarm. Plus an independent guard in the blit refusing any target that isn't a legal,
non-block-compressed render target — device removal is now unreachable, not merely
unlikely.

> **Lesson worth keeping:** before removing something that looks like an accident, ask
> what it was holding up. And never write into a GPU resource you have not positively
> identified — "the last thing the hook saw" is not an identification.

## 3. THE GLASS DISPLAYS OUR RENDER TARGET (display: solved)

Confirmed with the PiP overlay forced off (`composite mode -> force-OFF`), so nothing
else could account for it, and then nailed down by pressing **F9**: the reticle drawn on
the glass *changed shape*, because `style` is derived from the zoom index
(`Plugin.cpp`: `style = zoom_idx == 0 ? 0 : (zoom_idx == 1 ? 1 : 2)`). Nothing else in
the game can do that.

The open problem since M3 — our pixels onto the scope's own glass, in world, in real
gameplay — is done.

**Test-setup lesson, and it was the user's catch:** you cannot inspect the glass while
the companion hides the rifle at ADS *and* the distance-scaled PiP fills the screen. The
first attempt looked like "no change" purely because of that. F10 (fixed this session —
it arrives as `WM_SYSKEYDOWN`, which is why it had never once worked) parks the overlay,
and `draw_flat_overlay` gates *only* the swapchain overlay, so `g.rt` and the blit keep
feeding the glass while you look at it.

## 4. via.render.Mirror WORKS — the "dead end" verdict is overturned

The glass showed **the actual room** — fuse box, gauges, breaker switches, all matching a
reference screenshot taken without the scope. A genuine scene render, not a backbuffer
crop.

**And `registerScene` was never called.** No `via.render.layer.Scene` accessor resolved
(`via.SceneView` exposes only `get/set_RenderType`), so the script skipped it.
`createComponent` + `set_RenderTarget` alone is sufficient for Mirror to produce.

The 2026-08-24 dev-PC verdict rested on two claims that are both now falsified by this
project's own later findings: (a) "a Lua-created RT never gets real GPU backing" —
overturned by the D3D12 hook the same day; (b) it was judged by redirecting 41 GUI
elements to its RT and seeing nothing — but `via.gui.GUI.set_RenderTarget` was later
shown to mean "renders into", not "displays from". **Mirror was tested as a producer
through a display path that never displayed anything.** It was never dead.

### What Mirror is, precisely

A **planar reflection**. Hence both artefacts seen on the glass: the image is *mirrored*
(upside down) and *clipped at the mirror plane* (the grey half). Both are the component
doing its job.

Internals dump came back **completely empty** — zero fields on `via.render.Mirror`,
`via.Component` or `System.Object`. Its entire surface is 8 methods
(`registerScene`/`unregisterScene`/`isRegisteredScene`/`get_Visible`/
`get`+`set_LightWeightMode`/`get`+`set_RenderTarget`). **No plane, normal, clip or FOV
control exists.** Reflection geometry is therefore steerable *only* through the host
GameObject's transform — currently the rifle's root, which can't be rotated without
rotating the gun.

## Where it stands

- **Display:** solved. 2 material calls, reversible, verified live.
- **Content:** solved in principle — the engine renders the real scene into our target.
- **Geometry:** open. A planar reflection is not a scope view, and Mirror has no knobs.

Next step is a read-only TDB scan (numpad `+`, plugin-side) listing every type exposing
`set_RenderTarget`. Since M3 this project has been finding RT producers one at a time and
arguing about each; the type database can just be asked. If a camera-like producer exists
in RE8 it is in that list. If the list is only GUI + Mirror, then Mirror on a steerable
transform is the road — reflect the bore direction with `n = normalize(d - b)`, which is
literally how a periscope works — and we stop wondering.
