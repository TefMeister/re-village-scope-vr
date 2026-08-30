# 2026-08-24 (same day, session 2) — Candidate 2 groundwork: no managed-reflection bridge to a native GPU resource

**Goal:** find a way to reach the real `ID3D12Resource*` backing an already-displaying texture (the
reticle slot, or any equivalent working texture) from the plugin's native side, so it can be
overwritten directly via `CopyTextureRegion` — reusing the exact mechanism the M1 milestone already
proved works for the backbuffer composite, sidestepping the RT-backing problem entirely (candidate 1,
same day, was confirmed a dead end for the same reason M3 was).

## What was tried

- `re8_scope_m5_texture_native_recon.lua`: reflected `via.render.Texture` and
  `via.render.TextureResource` — **neither type exists in this game's TDB** (not just missing
  methods — the types themselves aren't there; the real name is `via.render.TextureResourceHolder`,
  already used since M3). Also tried loading a real on-disk texture path via
  `sdk.create_resource("via.render.TextureResource", ...)` — **this "succeeds" (returns non-nil)
  regardless of type name or path validity**, same as every prior `create_resource` call in this
  project's history; the returned object's `:get_type_definition()` and `:call()` both fail
  (`method 'call' is not callable`), meaning **the raw object `create_resource` returns is not a full
  reflectable managed object at all** — it's some lighter-weight handle that only supports the
  specific follow-up calls this project has already used on it (`add_ref`, `create_holder`), not
  general reflection. Worth remembering for any future session working with `create_resource`
  results: don't expect `:call()`/`:get_type_definition()` to work on them.

- `re8_scope_m5_texture_native_recon2.lua`: since `get_methods()`/`get_fields()` only return members
  *declared directly* on a type (not inherited ones — the same gotcha this project already hit on the
  native C SDK side, 2026-08-23 lens-rides-the-rifle notes), walked the **full parent-type chain** of
  `via.render.TextureResourceHolder`: `TextureResourceHolder → via.ResourceHolder → System.Object`.
  **Confirmed, not guessed: the entire reflected API across all three levels is `get_ResourcePath`
  plus generic `Object`-level methods** (`Equals`, `GetHashCode`, `ToString`, etc.) — **there is no
  native-resource accessor anywhere in this chain.** Also tried to find a *live, already-bound*
  texture on an on-screen GUI element (`get_Texture`/`get_Material`/`get_MaterialTexture` on
  `via.gui.GUI`) as an alternative route in — none of those method names matched anything (silent,
  no hits), meaning GUI's real texture-binding accessor has some other name not yet found.

## Conclusion

**The specific approach of "bridge a Lua/managed-reflection-visible texture object to its native GPU
resource pointer via a getter method" is a dead end** — there is no such getter anywhere in the
reflected type hierarchy for texture resources in this game. This isn't a case of not having tried
hard enough on this one path; the full inheritance chain was dumped and it's genuinely not there.

This does **not** mean candidate 2's underlying idea (native GPU-side hijack of an already-working
texture) is dead — it means **reflection is the wrong tool for finding the resource pointer.** Two
real alternatives, neither attempted yet:

1. **Hook the native D3D12 call site where the engine itself creates/binds the resource** (e.g.
   `ID3D12Device::CreateShaderResourceView`, or `CreateCommittedResource` at texture-load time) and
   capture the resource pointer as a side effect of the hook, correlating by resource dimensions or a
   nearby resource path string — **this project already has proven, working experience with exactly
   this class of technique** (the M0 scaffold and M1 composite both work by hooking native D3D12 call
   sites, not by reflecting on managed objects). This is the natural next attempt, and it's a bigger,
   more self-contained engineering task than "add a getter call" — plan a session around it
   specifically rather than treating it as a quick follow-up.
2. **Blind native structure offset-hunting** on the object `via.render.TextureResourceHolder` (or
   whatever native class actually owns the resource pointer) — walking raw memory near a live
   instance looking for a COM-vtable-shaped pointer, the technique other sessions in this whole
   multi-project effort have used elsewhere (e.g. the Psychonauts investigations). More effort, less
   architecturally clean than option 1, but a fallback if hooking doesn't pan out.

**Recommendation: option 1 (native D3D12 hook) is the better use of a dedicated next session.** It
reuses proven infrastructure instead of introducing a new, riskier technique.

Cleanup: game process killed, both recon scripts removed from `reframework/autorun/` after the
session (title-screen-only, no gameplay/saves touched), only the real companion + built plugin remain
deployed.
