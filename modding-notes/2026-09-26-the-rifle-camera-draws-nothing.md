# 2026-09-26 — the rifle camera: the engine builds its layers and never draws them

Home PC, flat screen, Claude driving the game itself. Morning on Opus, afternoon on Fable. Evidence:
`dev-archive/recon/2026-09-26-rifle-camera-at-world-origin/` (morning) and
`dev-archive/recon/2026-09-26b-rifle-camera-draws-nothing/` (afternoon). Dossier §9cr.

## The short version

Yesterday's idea was a real camera of our own riding the rifle, so the scope picture would come from where the
rifle points instead of being cut out of the head's view (that cut-out is what smears when the rifle points off
to the side — Tefa asked exactly that today, and yes, that is the smear).

Today, step by step, with numbers rather than eyes:

1. **The camera sat at the centre of the map, not on the rifle** (0,0,0 vs the rifle at −100,−10.6,−30). Moving
   it onto the rifle every frame works, and switching its self-update on does not make it take over the player's
   view. `[verified-live 2026-09-26]`
2. **The brown smudged picture was never a picture.** The plugin had grabbed a working buffer that the engine
   allocated for our camera and never wrote: a cloud blob and horizontal streaks that flicker but ignore the
   camera entirely. The other copy — our real target — is a flat colour, cleared and never drawn into.
3. **Nothing makes it draw.** Not the pose, not self-update, not walking, not the main camera's 20 render
   components created on ours (no takeover, no crash), not a red background colour that reads back red but never
   reaches the glass, not a fresh 2560×1448 target.
4. Yet the engine takes the camera seriously: two Scene layers of ours, 13 render passes each, sized to our target,
   enabled, with the right near/far/aspect. The frame just never runs them.

So: a `via.Camera` + `via.render.RenderOutput` of our own is registered but not rendered in RE Village. The recipe
came from praydog's multipass duplicate for a newer engine build; that file is not in the current REFramework
tree, so the comparison could not be made. The question for research: what does an RE8-era object that renders a
camera into a texture carry (in-game monitors, the security cameras in the factory), and can we copy that.

## What is installed in the game folder now

`re8_scope_cam_probe.lua` and the harness dispatch for its words (`cammake`, `camkill`, `campose`, `camupdate`,
`camcopy`, `camlayer`, `camlayerout`, `camdump`, `camlua`). All inert until a word is sent; nothing runs by itself.
They stay while the question is open; take them out with the file when it closes.

## Method lessons, so the next session does not pay for them again

- **Do not `Reset scripts` mid-session on this project; relaunch.** A reset rebuilds the rig before the layer hooks are
  back, every layer tool then reports "no parent", and a second `rerig` freezes the glass on a dead texture.
- `camlua <one line of Lua>` runs from the command file with the camera, rifle, layer(view) and st in scope: every
  later experiment without a reset.
- The plugin's picture catcher only latches a FRESH allocation; each `.rtex` path allocates once per process. To
  re-latch, use a size not yet used this process.
- `set_Enable(false)` on a Scene layer does nothing (reads back true).
- The FOV we set (20) is overwritten to 26.23 within two seconds, every time; who does it is not known.
