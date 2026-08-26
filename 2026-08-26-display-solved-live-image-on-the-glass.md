# 2026-08-26 (evening, home PC) — display SOLVED: our live image on the scope glass; content problem named

One session, three results: the reticle layer stretches to fill the glass, the native
plugin's render target displays live on it, and the one remaining problem now has a precise
shape. Evidence: dev-archive `recon/2026-08-26-display-pipeline-live-on-glass/`.

## 1. The reticle layer is a full-glass display surface

T1 (morning) proved the lens is painted and slot 1 (reticle) is the only surface we control.
Tonight T4 proved that surface can be **stretched to cover the entire lens**:
`Reticle_UV_Scale_Offset` (`[3.2]` on `Lens2_Mat`) at (-0.1, -0.1) fills the glass with the
reticle layer, screenshot-proven. Its four components are (scale.x, scale.y, offset.x,
offset.y); smaller magnitude = bigger picture; negative = mirrored. `Reticle_Emissive`
controls the layer's brightness (0.02 on Lens2_Mat by default — near-invisible).

Two real bugs stood between the sliders and this result:

- **float4 variables never made the slider list** — the T4 builder only accepted scalar
  floats, so T3 printed `Reticle_UV_Scale_Offset` but no slider existed. (User caught it:
  "there is no Reticle_UV_Offset".)
- **`setMaterialFloat4` takes `via.Float4`, not `Vector4f`.** The TDB signature is
  `(UInt32, UInt32, via.Float4)` — an engine value type. Passing `Vector4f` threw, and
  `safe()` swallowed the throw: slider moved, nothing happened, no error anywhere. Fix:
  `ValueType.new(sdk.find_type_definition("via.Float4"))` + `set_field` x4, and **every
  write verified by immediate `getMaterialFloat4` read-back** with a loud log on mismatch.

**Lesson (added to the provenance family): a write that can fail silently must be read back.**
`setMaterialTexture` returning `true` while doing nothing (2026-08-25) and
`setMaterialFloat4` throwing into a swallowed pcall (tonight) are the same failure wearing
two masks. The T4 write path now proves every write; new code touching material variables
should copy it.

Side observation, unconfirmed: `[2.x]` (Lens_Mat) sliders did nothing visible with the
high-mag scope mounted — plausibly Lens_Mat is the *stock* scope attachment's lens (hidden
mesh part), since the scope variants are mesh parts of one rifle model. Swap scopes to test;
the plugin already binds both materials, so the mod works either way.

## 2. The native plugin's RT displays LIVE on the glass — user-verified

Plugin restored from its `.off-for-m8` parking. numpad `*` in real gameplay: 4 materials
scanned, both lens materials matched by name, slot 1 bound on each, originals saved — **2
`setMaterialTexture` calls** (the brute-force era did 44,920). User-verified live: the
image **moves with the world**, changes with the environment, **F9 changes zoom preset and
reticle style on the glass**, numpad `/` restores stock cleanly. The display half of the
scope problem — open since M3 — is closed.

Operational notes: the 10-second "freeze" on first bind attempt was a numpad `+` mispress
(VK_ADD runs the 114k-type RT-producer scan on the game thread, 9.3 s — the key sits next
to `*`). Reading the log found it in one minute; the alternative was an evening chasing a
phantom hang. The latch fired clean at rifle-detect (`1280x728 fmt=29`, closed for session).

## 3. The remaining problem: content feedback ("recording of a recording")

With the glass live, the plugin's content source is now provably wrong for it: the source is
a backbuffer capture, the backbuffer contains the glass showing that capture, and the loop
converges to hazy environment-colored mush with a doubled reticle (drawn + captured-drawn).
User's words: "like a recording of a recording of a recording." **A screen-copy can never
feed a surface that is part of the screen.**

The fix direction is already proven piecewise: `via.render.Mirror` renders the real scene
into a created RT (2026-08-24, room visible on glass), the plugin owns a latched, writable,
glass-bound target (tonight), and the D3D12 blit can transform between textures (M1/M2a).
Next milestone: **Mirror as producer, plugin as compositor** — copy the mirror's texture
into the scope target with un-mirroring, zoom crop, and reticle. Interim shortcut worth one
test: bind the glass to the Mirror's holder directly and use `Reticle_UV_Scale_Offset`'s
negative-scale mirroring + sub-1 magnitude zoom to un-flip and magnify at the material
level, no new plugin code.

## State at session end

Runtime-only throughout — restart restores stock everything. Plugin now ACTIVE (un-parked)
at `reframework/plugins/re_scope_vr.dll`. Lua script = staging `main` (`156bf41`). Latch
closed per session; numpad `*`/`/` bind/restore; numpad `+` = the slow TDB scan (avoid).
