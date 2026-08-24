# 2026-08-24 — Dev PC set up for this project; candidate 1 (Mirror) tested negative

**Where:** dev PC. Turns out RE Village was already installed there — the "home PC only" note in
this project's status board was simply stale. REFramework (nightly 01397, `684ca77`) and the VR pack
were installed fresh, and the scope plugin was built clean on the first try from
`re-village-scope-vr-staging/plugin/` using the dev PC's VS2022 Build Tools + bundled CMake. Deployed
and confirmed running. **The dev PC can now work this project on its own — no headset needed for any
of what follows, all done on a flat monitor.**

## The open problem, recap

Since the M3 recon session (2026-08-23), the scope has been stuck on one thing: getting a render
target's actual pixel data to show up when bound to the scope's own glass material. The API calls
all succeed — `set_RenderTarget`, `registerScene`, binding to the glass — but nothing ever appears.
Three candidates were queued to try next: (1) `via.render.Mirror` as a producer, (2) a plugin-side
native hijack of the reticle texture's already-working GPU backing, (3) `app.RecordSys`.

## What happened today

**`app.RecordSys` (candidate 3) doesn't exist** in this game's type database at all — confirmed via
reflection, not a maybe. Ruled out cleanly.

**`via.render.Mirror` (candidate 1) is real, and its API is exactly what the design assumed**:
`registerScene`, `set_RenderTarget`, `get_Visible`, all reflectable and callable. Attaching one
required finding the exact `createComponent` overload signature via reflection (guessing the
signature string throws — REFramework needs the precise reflected form), and attaching it to a
GameObject that's actually live in the current scene rather than a bare `sdk.create_instance` orphan.
Once attached to the title screen's `FadeInOutBlack` object, both `set_RenderTarget` and
`registerScene` reported success, and `get_Visible` returned true.

**Then the same wall as M3, again**: redirecting GUI elements to the Mirror's render target — first
one at a time, then all 41 present on the title screen at once — produced **zero visible change**,
confirmed by screenshot comparison. Whatever's missing isn't "the right producer type" — a
successfully-registered Mirror scene capture has the exact same non-appearance problem an existing
GUI's own render pass did in M3. The render target itself never gets real GPU-backed content, no
matter what API path creates or feeds it.

One correction to record: the 2026-08-22 note that "REFramework's Lua API has NO render-target/
second-camera/render-pass functions" isn't quite accurate — `via.render.Mirror`'s render-target API
is real and fully reachable from Lua. It just doesn't solve the actual problem, so the practical
conclusion from back then (this needs native C++ work) turns out right anyway — just for a more
specific reason than originally stated.

## Where this leaves things

Two of three candidates are now closed out (one dead, one a confirmed-same-dead-end). **Candidate 2
— a plugin-side native hijack of the reticle texture, which already has proven working GPU
backing — is the clear best remaining lead**, and it's not a shot in the dark: this project's own M1
milestone already proved the exact mechanism it needs works in this codebase (plugin-side D3D12
`CopyTextureRegion` into an existing GPU resource — that's literally how the very first working pixel
got into RE Village's frame). The remaining work is native, not Lua: resolve the reticle texture's
live `ID3D12Resource*` from the plugin's own reflection SDK access, and copy real rendered content
into it directly.

Full script-by-script detail and screenshots: dev-archive
`recon/2026-08-24-mirror-candidate-tested-negative/`.
