# 2026-08-24 (session 2) — Candidate 2's reflection-bridge approach is a dead end; a cleaner path forward is clear

Following up on the same day's candidate 1 result (Mirror confirmed real but hits the same
no-GPU-backing wall as M3), went straight at candidate 2: reach the native GPU resource behind an
already-working texture and overwrite it directly from the plugin's C++ side, reusing the exact
`CopyTextureRegion` mechanism the M1 milestone already proved works.

**The specific bridge — "get a native resource pointer off a Lua/reflection-visible texture object"
— doesn't exist.** Walked the entire type hierarchy of `via.render.TextureResourceHolder` down to
`System.Object`: the only real method anywhere in that chain is `get_ResourcePath`. No accessor for a
native handle, no D3D-anything. This was confirmed by dumping the full chain, not by one failed
guess.

Also learned, as a useful side note for future sessions: **the object `sdk.create_resource(...)`
returns is not a full reflectable managed object** — `:call()` and `:get_type_definition()` both fail
on it outright. It only supports the narrower set of calls this project has already been using on it
(`add_ref`, `create_holder`). Don't expect general reflection to work on a raw `create_resource`
result.

**This doesn't kill candidate 2's idea — it means reflection was the wrong tool to find the resource
pointer with.** The real next move is **hooking the native D3D12 call where the engine itself creates
or binds the texture's resource** (e.g. `CreateShaderResourceView`/`CreateCommittedResource`) and
capturing the pointer as a side effect — which is exactly the class of technique the M0/M1 milestones
already used successfully for the backbuffer and command queue. That's a bigger, self-contained piece
of native engineering, not a quick follow-up call — worth its own dedicated session rather than
squeezing it into this one.

Full detail: dev-archive `recon/2026-08-24-candidate2-texture-native-resource-recon/`.
