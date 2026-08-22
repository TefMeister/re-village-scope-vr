# How the sniper scope works, and why VR breaks it

**Date:** 2026-08-22 · **Game:** Resident Evil Village (RE Engine, REFramework native VR)
**Status at time of writing:** mechanism fully identified, implementation path decided,
plugin scaffold built — verification of the scaffold pending one game restart.

## The symptom

Aim the sniper rifle in VR and instead of a scope you get a huge flat plane with a
crosshair hanging in front of your face. This is a known limitation across all of
REFramework's VR-supported games, not something unique to this setup.

## Recon without a headset

All of the investigation below was done flat on a monitor, deliberately: REFramework's
VR scope handling only activates when an HMD is present, so flat play shows the game's
*native* scope behavior, uncontaminated. A read-only Lua probe collected three things:

1. **Every GUI element name drawn**, flagging anything scope/reticle/zoom-ish. One
   practical lesson: you cannot hold a scope up and click a debug UI at the same time,
   so the probe auto-fires its dumps the moment it detects the scope is active
   (FOV drop, or the scope element drawn within the last 0.3 s) — no interaction needed.
2. **The primary camera's FOV every frame**, logging changes.
3. **Component dumps** of the player and of the scope GUI object (one API gotcha: a
   managed object's type comes from `obj:get_type_definition():get_full_name()` — these
   are REFramework-native methods on the object, not reflected calls; calling them via
   `:call(...)` fails silently inside a pcall wrapper and you get counts with no names).

## What the engine actually does

- The scope overlay is a GUI element named **`GUIScope`**, carrying exactly three
  components: `via.Transform`, `via.gui.GUI`, `app.GUIScope`. No render texture, no
  scene capture, no children. It is a mask and reticle — nothing more.
- Aiming down the scope smoothly narrows the **main camera's field of view from ~63°
  down to 24.37°** (~2.6× magnification), then draws `GUIScope` over the top.
- Therefore **no separate scope image exists anywhere in the game**. The "scope view"
  is just the entire world zoomed, with a mask on it.

That explains VR precisely: the FOV zoom cannot be applied to a stereo headset view
(and is nauseating where it leaks through), and REFramework's existing handling —
which world-positions GUI elements along the aim ray — leaves the fullscreen mask
floating as a giant flat plane. Both halves of the flat-screen trick fail in VR, and
there is nothing ready-made to borrow.

## Why the fix must be a native plugin

A real VR scope needs: (1) the main-camera zoom suppressed so the world stays 1:1;
(2) the `GUIScope` mask hidden; (3) a **second, magnified view rendered to a texture**;
(4) that texture on a quad at the rifle's scope lens, bore-sighted to the real bullet
ray. Steps 1, 2 and 4 are reachable from Lua. Step 3 is not: REFramework's Lua API has
no render-target, camera-creation, or render-pass functions at all — it is reflection
plus 2D drawing. Render infrastructure lives at the native layer, which is exactly what
REFramework's C++ plugin SDK exposes: initialization hands over the renderer type
(D3D11/D3D12), device, swap chain and command queue, plus per-frame callbacks
(`on_present`, the `BeginRendering`/`EndRendering` application-entry boundaries, device
reset). Andyalpa predicted a C++ plugin would be required before this recon was done —
he was right.

## Where it stands

A minimal scaffold plugin (written from scratch against the published SDK headers)
compiled first try and is deployed; it logs the renderer type and proves the frame
callbacks fire. Next milestones: own a render target and composite it visibly (M1),
get a magnified scene render into it (M2 — first checking whether the engine can be
driven to render a second camera view before building a manual pass), then the lens
quad, bore-sighting, zoom suppression and mask hiding in VR (M3).

## Lessons

1. **Recon flat when the flat path is the native one.** The monitor showed the true
   mechanism; a headset would have shown REFramework's overrides on top of it.
2. **Instrument for hands-busy capture.** If the state you need to inspect requires
   both hands on the controls, the probe must trigger itself from the state change.
3. **A silent pcall hides API misuse.** Guarded reflection code that "works but prints
   nothing" usually means the call itself is wrong, not the data missing.
4. **Measure before designing.** One FOV trace settled the entire architecture debate:
   there is no scope render to reuse, so the design must create one.
