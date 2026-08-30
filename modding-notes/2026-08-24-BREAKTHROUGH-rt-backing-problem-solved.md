# 2026-08-24 (session 3) — BREAKTHROUGH: the RT-backing problem is solved

Since the M3 recon session (2026-08-23), the VR scope has been stuck on one specific, stubborn
problem: getting a render target's actual pixel data to display on the scope's glass. Every attempt —
redirecting a GUI's own render pass, attaching a `via.render.Mirror` and pointing it at the scene —
succeeded at every individual API call and still displayed nothing. Two full sessions concluded the
resource itself must never be getting real GPU backing.

**That conclusion was wrong, and today's session found out why.**

## The real story

Built a native hook into the plugin (`Plugin.cpp`) on the two D3D12 device calls that actually
allocate and view GPU textures — `CreateCommittedResource` and `CreateShaderResourceView`. Both are
fixed, public offsets from Microsoft's own D3D12 headers, nothing about the game itself needed to
reverse-engineer them. Four hotkeys drive the test:

- **F6** creates the exact same render-target resource M3/M4 always used, but natively this time, and
  watches the hook for what actually happens at the GPU level.
- **F7** writes a loud magenta/black checkerboard directly into whatever GPU memory got allocated.
- **F5** tries the GUI-redirect approach M3/M4 always used.
- **F4** tries the *other* mechanism M3 originally proved — binding a texture directly onto a mesh's
  material.

**F6 confirmed, directly, with hard evidence: the resource IS really allocated on the GPU** — a real
728×1280 texture, correctly flagged as a render target. Not a maybe, not an inference — a hooked D3D12
call caught it happening. Everything this project believed since M3 about the resource itself being
the problem was incorrect.

**F7 confirmed the write itself works cleanly** — no crash, no corruption.

**F5 (the GUI approach) still showed nothing** — even now, with a resource we know for certain is real
and full of our own pixel data. That's the piece that finally makes sense of two sessions of dead
ends: `via.gui.GUI`'s `set_RenderTarget` was never going to display anything, regardless of what's
behind it. It most likely means something closer to "this element renders *into* here" than "show this
texture" — the wrong tool for the job the whole time, API calls succeeding the whole way down.

**F4 (the mesh-material approach) worked.** Screenshot proof: the title screen's character model shows
a clear, unmistakable checkerboard pattern across its cloak. This is the exact mechanism M3 originally
proved back on 2026-08-23 (the "rifle-body atlas shown on glass" test) — this session just never had a
real, GPU-written resource to try it with until today.

## What's actually left

The mechanism end to end is now proven, not theoretical: create a resource natively → write real
rendered content into it → bind it to a mesh's material → it shows up. What remains is straightforward
engineering, not open unknowns:

1. Render the real scope image (the digital-zoom composite this project already has working) into
   this natively-managed resource each frame, instead of a static test pattern.
2. Bind it specifically to the scope glass's own material slots (already known from M3: materials 2/3,
   slot 1) instead of the brute-force "try every mesh" approach used to get this proof — that needs
   the real scoped weapon in hand, which today's session didn't have access to (fresh install, no
   save far enough into the game).
3. Re-verify in the actual VR path once the flat version is wired up for real.

Full technical detail, both screenshots, and the exact code: dev-archive
`recon/2026-08-24-candidate2-d3d12-hook-WIN/`.
