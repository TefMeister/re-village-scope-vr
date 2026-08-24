# 2026-08-24 (session 3) — WIN: native D3D12 hook + mesh-material bind solves the RT-backing problem

**This is the resolution to the RT-GPU-backing problem that has blocked this project since the M3
recon session (2026-08-23).** Screenshot proof: `screenshot2-mesh-material-CHECKERBOARD-VISIBLE-WIN.png`
— the title screen's character model visibly shows the test checkerboard pattern across its cloak.

## What was built

A new `hook` namespace in `Plugin.cpp` (see `Plugin.cpp.snapshot-after-d3d12-hook` for the exact
state at the moment of the win) hooks two `ID3D12Device` vtable methods — `CreateShaderResourceView`
(slot 18) and `CreateCommittedResource` (slot 27), both fixed, publicly-documented offsets from
Microsoft's own `d3d12.h`, nothing game-specific to reverse engineer. Four new hotkeys drive it:

- **F6** — arms a 90-frame capture window, then calls `create_resource("via.render.RenderTargetTextureResource", "movie/rtex/movie_1280_720.rtex")` **natively** (the plugin C API exposes this directly, same call M3/M4 used from Lua) and watches what the hooks observe.
- **F7** — writes a magenta/black checkerboard test pattern into whatever `CreateCommittedResource` captured, via a standard D3D12 upload-heap + `CopyTextureRegion`, reusing this project's own M1-proven copy mechanism.
- **F5** — redirects every `via.gui.GUI` component's `set_RenderTarget` to the written resource (the M3/M4 approach). **Confirmed to show NOTHING, even now** — see below, this is itself an important finding.
- **F4** — the new thing: tries `setMaterialTexture` on every `via.render.Mesh` in the scene (brute-force across a small material/texture-slot grid, since no weapon is in hand to know exact indices). **This is the one that worked.**

## The actual findings, in order

1. **F6 confirmed a real GPU allocation happens.** Every run: exactly one `CreateCommittedResource`
   call, `728×1280`, format 29 (`R8G8B8A8_UNORM_SRGB`), flags `0x1`
   (`D3D12_RESOURCE_FLAG_ALLOW_RENDER_TARGET`) — this **directly contradicts** the working
   hypothesis this whole investigation had been operating under since M3. The resource was never
   unbacked. (728 vs. the requested 720 height is very plausibly codec/macroblock padding from the
   movie-resource type being reused for this — a detail for later, not a blocker.)
   Note: the SRV hook also captures ~13,000 unrelated calls/window from what looks like a bindless
   descriptor-heap population loop running every frame — pure noise, silenced after the first run
   (no per-call log), `CreateCommittedResource`'s single relevant hit is the real signal.
2. **F7 confirmed the write succeeds** — no crash, no corruption, across every run (the
   `D3D12_RESOURCE_STATE_COMMON` before-state assumption for the transition barrier held up fine in
   practice).
3. **F5 (GUI `set_RenderTarget`) STILL showed nothing** — even with a confirmed-real, confirmed-written
   resource. This is the key clarifying result: **`set_RenderTarget` on `via.gui.GUI` was never the
   right binding API**, regardless of backing. All of M3's GUI-producer attempts and M4's Mirror
   attempts were chasing the wrong consumer the whole time — it's very possible `set_RenderTarget`
   means "this element renders *into* this target" (a producer role) rather than "display this
   texture" (a consumer role). Screenshot: `screenshot1-gui-redirect-no-visible-effect.png`.
4. **F4 (`setMaterialTexture` on a mesh) WORKS.** This was the *original* M3 mechanism (the
   "rifle-body atlas shown on glass" proof) — this session just never had a real, written resource to
   try it with until now. Screenshot: `screenshot2-mesh-material-CHECKERBOARD-VISIBLE-WIN.png` — a
   clear checkerboard pattern is visible across the title screen character's cloak, unmistakable, not
   present before F4 ran.

## What this means for the actual scope

**The mechanism is proven end to end**: create a real RT natively → write real rendered content into
it via `CopyTextureRegion` → bind it to a mesh's material via `setMaterialTexture` → it displays.
Every piece of that chain is now confirmed working, using this session's own evidence, not
assumption. The remaining work to ship the actual VR periscope scope is engineering, not unknowns:

1. Instead of a static checkerboard, render the actual desired scope image into the RT each frame
   (the M2a digital-zoom composite already renders a real image into `g.rt` — the missing step is
   copying/rendering that into the new natively-managed resource instead of the backbuffer corner).
2. Bind it specifically to the scope's own glass materials (mats 2/3, slot 1 = `Reticle_BaseAlphaMap`,
   per M3) instead of brute-forcing every mesh — needs the real scoped weapon in hand to test the
   exact indices (this session's brute-force across 941 meshes / material 0-3 / slot 0-1 was a
   deliberate shortcut to get *a* visible confirmation without needing gameplay access).
3. Confirm it also displays correctly in the actual VR path (the M3 VR mirror-accumulation guard is
   unrelated to this and should still apply).

## Cleanup

Old plugin backed up as `re_scope_vr.dll.pre-d3d12hook-backup` before deploying each new build. Game
process killed cleanly at the end. No save files touched (title-screen only). Deployed plugin is the
final hook-enabled build from this session (F4/F5/F6/F7 all present) — safe to leave in place, all
behavior is opt-in via hotkey, zero effect unless triggered.
