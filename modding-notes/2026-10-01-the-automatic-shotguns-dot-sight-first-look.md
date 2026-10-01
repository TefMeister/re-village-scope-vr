# 2026-10-01: the automatic shotgun's dot sight, first look

*Dev PC, flat copy, Tefa at the PC. Tefa: "this weapon has a scope on it, no zoom, just the dot scope with a white thin
circle on it ... so that too will be usable in VR, just like the rifle scope". It is the automatic shotgun, not an
assault rifle (Tefa's correction).*

## What the game has `[verified-live 2026-10-01, n=1]`

- **The gun:** `ri3048_Inventory`, model materials `it02_022_Shotgun_03_A_Mat` and `_B_Mat`. Both are ordinary body
  materials (blood, rain, wetness settings). **No glass, lens or reticle material.**
- **No separate sight part:** the gun has no child objects, and nothing beside it under the player (`pl1000`) is a sight.
- **No sight point:** its nine named points are root, Body, Magazine, MagazineB_FK_0, Slide, Trigger, Cartridge,
  vfx_muzzle and vfx_muzzle2. In the gun's own frame the muzzle sits at (0, 0.071, 0.556), the second muzzle point at
  (0, 0.071, 0.658): **the barrel runs straight along +Z, 7.1 cm above the gun's origin.**
- **Aiming on a flat screen** (right mouse held): the gun stays low at the side and the game draws a **thin white circle
  in the middle of the screen**, its own crosshair (pictures in `dev-archive/recon/2026-10-01-shotgun-dot-sight/`).

## What it means for VR `[inferred-static 2026-10-01]`

The dot and the circle are a screen overlay, not part of the sight. In VR the screen centre is not where the gun points,
so the sight on the model has nothing in it. We have to draw them ourselves: a small dot with a thin ring, placed far
out along the barrel line (+Z from the muzzle height), so it sits on the aim line from either eye, and ideally only
visible through the sight's window. The window's position is not a named point, so it is measured from the model or set
by eye with a knob. Design to settle next (`MODEL: FABLE`): how and where to draw it (the plugin's own pass, as the scope
glass is drawn, or a game object), and the masking.
