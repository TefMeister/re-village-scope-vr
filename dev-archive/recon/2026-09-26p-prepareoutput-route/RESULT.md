# RESULT (2026-09-26 21:09-21:20, /lm flat, Tefa watching)

`[verified-live 2026-09-26, n=1]`
- **The chain is right.** `clonepo` found the clone's Scene layer (13 children, PrepareOutput last), PrepareOutput +0xF8 →
  TargetState (1 rtv) → RTV → **Texture at RTV+0x88** (exactly the TDB-69 prediction) → resource 1114x835 fmt=87 (B8G8R8A8_UNORM,
  the DLSS render size).
- **But at Present that texture holds the MAIN view** (dump 2: the player's own view, rifle included). The PrepareOutput output
  is shared between the two scene layers: the clone's finished picture is written there and overwritten by the main view
  before Present. This is the "reused later in the frame" row of NEXT-RUN — why praydog copies during the layer draw.
  The REFramework plugin C API has no layer-draw callback, so the copy needs a D3D12-level hook (e.g. the command list's
  ResourceBarrier on that resource: copy it at the first transition out of RENDER_TARGET each frame) [design, hypothesis].
- **Tefa: the rifle-camera picture on the glass was UPSIDE DOWN** (they had said "right way up" earlier and corrected it:
  *"scope is upside down, i was wrong"*). Cause: the mirror-era flip_h + flip_v were still applied in clone mode. Plugin
  b736de79 skips both in clone mode; the stairs shot now shows carved panels with the snow on TOP of the ledge.
- Outdoors on the plaza the clone's own (ungraded) picture is readable, blue-tinted, brighter than the game view — not flat
  white there. The flat white was at the doorway, looking into a bright fog; `[n=1]`, depends on the view.
