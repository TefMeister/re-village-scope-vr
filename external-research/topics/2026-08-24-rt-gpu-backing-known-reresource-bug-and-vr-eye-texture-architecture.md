# RT GPU-backing problem: a known REFramework resource-lifetime bug matches the symptom, and REFramework's own VR path isn't the model to copy

**Status:** 🆕 new — a concrete workaround to try, plus an architectural finding that narrows the
next-session candidate list rather than expanding it.

Follow-up pass specifically on the open M3 problem in `re-village-scope-vr-modding-notes/
2026-08-23-m3-recon-glass-hijack-proven-rt-backing-open.md`: a created `RenderTargetTextureResource`
binds to the scope glass "successfully" (no error, type checks pass, `set_RenderTarget`/
`setMaterialTexture` all report success) but the glass shows nothing — the RT never gets real GPU
content. A prior research pass (2026-08-24, logged in `STATUS.md` only) already swept REFramework's
docs, GitHub issues/discussions, and alphazolam's EMV-Engine for general terms
(`via.render.Mirror`/`RenderTargetTextureResource`/`registerScene`) and found nothing public
documenting GPU-backing registration for a created RT. This pass went narrower: REFramework's own
open-source internals (its own working render-target code) and its issue tracker specifically for
resource-lifetime bug reports, rather than general API-existence searches.

## 1. A REFramework GitHub issue describes almost exactly this symptom — and a concrete workaround

**Issue #1448, "REResource Issue(s)"** on `praydog/REFramework`
(`github.com/praydog/REFramework/issues/1448`) is an independent, ongoing (reporter says ~1 year of
investigation, unresolved as of this search) bug report about **resource holders that "succeed" at
being set but silently stop working**:

- Symptoms: meshes/materials go invisible, materials go missing on objects unrelated to the one being
  changed, occasional vertex corruption, and eventually crashes (null-pointer read / heap allocation
  failure) — reported concretely on Monster Hunter Wilds hair meshes and RE4 Remake material swaps.
- Suspected cause: **resource/resource-holder lifetime instability, likely garbage collection**, despite
  the reporter calling `add_ref()`. Their exact words: memory addresses stay stable while the
  functionality degrades — consistent with the engine's GC reclaiming or invalidating something the
  reflection API's ref-counting isn't fully protecting.
- **The most stable workaround found: call `add_ref()` on *both* the resource holder AND the
  underlying resource, and create the resource(s) early** (well before the frame you need them
  visible), rather than creating-and-immediately-binding. This only delays the failure in the
  reporter's case, not eliminates it, but it's a concrete, cheap thing to try that the M3 recon notes
  don't mention doing (the recon describes creating the RT and holder and binding them, not
  double-`add_ref()`-ing both objects, nor creating well ahead of the bind frame).

**Why this matters for M3:** it's a different failure mode than "RT needs pipeline registration we
haven't found" (the current working theory) — it suggests the RT *resource itself* might not be
surviving/staying valid between creation and the glass actually sampling it, for the same underlying
reason other modders are hitting invisible meshes/materials elsewhere in the engine. Worth testing
*before* the heavier Mirror-as-producer work: hold both refs, create the RT resource + holder at
plugin init (or several seconds before binding) instead of on-demand, and see if the glass shows
*anything* different (even garbage/stale content would indicate the earlier binding actually was inert
while this one attaches).

## 2. REFramework's own VR eye-texture path is NOT "engine renders a scene into an RT" — it's post-render backbuffer copy

Read REFramework's own D3D12 VR rendering code (`src/mods/vr/D3D12Component.cpp`, public source,
described here in our own words, no code reproduced) to see whether praydog's own working
render-target mechanism reveals the missing registration step. It doesn't transfer directly, and
that's itself useful information:

- Eye textures are created via a normal `CreateCommittedResource` D3D12 allocation, with RTV/SRV
  descriptor-heap entries set up for each — nothing exotic there, consistent with what the plugin
  side is already doing for the scope's RT.
- **Critically, there's no engine-side "draw this scene into this texture" registration at all.** The
  game renders normally to its own backbuffer; REFramework's VR component then does a **GPU copy from
  the already-rendered backbuffer into the eye textures** (command-list copy, post-render), and submits
  *those* to OpenVR/OpenXR. The "VR" part is a copy-and-resubmit step bolted onto a normal single-eye
  render, not a genuine second in-engine camera pass.

**Why this matters:** it means REFramework's own most successful render-target usage is architecturally
the *same family of technique* as the mod's own flat PiP scope (crop/copy the already-rendered
backbuffer) — which the M3 VR recon already proved **cannot work for the VR case** here specifically
because the composite gets fed back into the same frame it was captured from (the Droste/accumulation
bug that pivoted M3 toward Mirror-as-producer in the first place). So this isn't a shortcut back to the
backbuffer-copy approach — if anything it **reinforces that candidate 1 (`via.render.Mirror` as an
actual second-camera producer) is the architecturally correct direction**, because it's the only one of
the three candidates that would give a genuinely independent scene render rather than a copy of the
same frame. It also explains why searching REFramework's own code for "how do I register an RT with
the renderer" comes up empty: even its author's own most sophisticated render-target use didn't need
to solve that problem — VR eye output uses copy, not registration.

## 3. Still no public "in-world screen / second camera" RE Engine mod found

Checked again, narrower this time (in-world monitor/camera-feed/mirror mods specifically, not just
photo-mode/freecam mods which are a different technique — moving the *one* existing camera, not adding
a second rendered one). Found plenty of RE Engine photo-mode and fixed-camera mods (Otis_Inf's
photomode tools for RE3/RE2/Requiem; various Nexus third-person-camera and fixed-camera mods for RE2R/
RE4R/Requiem) but nothing that renders a second in-engine camera into an in-world surface. Consistent
with the 2026-08-24 sweep's conclusion (Nexus's RE Requiem "Scope Resolution Fix" confirming Capcom's
*own* scopes are FOV-crop, not second-camera RT) — reinforces that this remains genuinely unexplored
public territory, not a gap in searching.

## Sources (see [CREDITS.md](../CREDITS.md) for the full standing credit)

- praydog — REFramework GitHub issue #1448 ("REResource Issue(s)"), resource lifetime/GC bug report
  and workaround discussion.
- praydog — REFramework source, `src/mods/vr/D3D12Component.cpp` (VR eye-texture creation/copy
  mechanism, read for architecture only, no code reproduced).
- Otis_Inf (Frans Bouma) — RE Engine photomode tools (checked as possible prior art; different
  technique, not directly applicable).
- Nexus Mods RE Engine camera-mod authors (checked for an in-world second-camera precedent; none
  found).
