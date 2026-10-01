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

## Correction, the same evening (Tefa): what is actually wanted

*"i want this to have the same scope picture as the rifle does, but instead of a cross, it has a thin white circle on the
lens and no zoom effect"* `[reported 2026-10-01]`.

So the section above ("draw a dot far out on the barrel") is NOT the plan. The plan is the sniper scope's own system on the
shotgun's sight:
- the same live scope picture on the sight's lens (the rifle camera, or the mirror picture where that is dark),
- **no zoom:** the camera's field of view matched to what the eye sees through the sight (1x), not the rifle's 20°,
- **a thin white circle** as the reticle instead of the cross.

What makes it different from the rifle `[inferred-static 2026-10-01]`: the shotgun's model has **no glass material** for the
picture to go on (the rifle's lens is its material 2/3). So the picture needs a surface: the mod's own spawned pane (the
`pane`/`spawn` code the rifle used before the glass bind) placed in the sight's window, or another way to give it one. The
sight window's position is not a named point, so it is measured or set by a knob. Also: the scope code recognises only the
sniper rifle (`ri3042`), so the shotgun (`ri3048`) has to be added as a second scoped weapon.
