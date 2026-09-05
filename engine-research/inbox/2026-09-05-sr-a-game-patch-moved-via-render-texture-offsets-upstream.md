# A game patch moved `via.render.Texture`'s offsets, and REFramework only fixed it today — the surface is exactly the one this project builds on

From: `/sr` sweep, home PC, 2026-09-05. Read firsthand from the merged pull request and the GitHub
API; nothing was cloned, downloaded or installed.

## The finding

[REFramework PR #1822](https://github.com/praydog/REFramework/pull/1822), by **porlock2**, opened and
merged on **2026-09-05**. It changes one file — `shared/sdk/Renderer.hpp` — and only the **static
offset accessors** for `via.render.Texture`.

What happened upstream: a **March 2026 update to Resident Evil 4 (title version 1.5.9.0)**
re-laid-out `via.render.Texture` to match Street Fighter 6's layout. The description field moved to a
different base, and the D3D12 resource container moved from `0xA0` to `0xB8`. REFramework kept
reading the old offsets. The fix is a per-title branch selecting the new values; the contributor
states the offsets were **measured, not estimated**.

`[reported 2026-09-05]`

## Why this lands in your inbox rather than someone else's

**Those accessors are the surface your M2 work sits on.** A magnified scene rendered into a render
target, composited back, is texture-descriptor and resource-container territory — the two things this
patch moves. Nothing here says your build is broken; RE Village is not RE4 and the fix is explicitly
title-scoped. What it says is that **`via.render.Texture`'s internal layout is per-title *and*
per-game-version**, and that a framework's offset table is an assumption with a date on it.

Two concrete things worth knowing given what your dossier now records:

1. **Your home-PC build is the fork at `76298bd`, built 2026-03-11** — three weeks *before* the RE4
   layout change landed on 2026-03-31. So it carries the pre-change path by construction. Irrelevant
   while you are on RE Village, and immediately relevant the moment anything targets a title that has
   re-laid-out a struct.
2. **The dev PC's nightly (`684ca77`, 2026-08-20) also predates the fix**, so on this one point the
   two machines agree — which is worth writing down precisely because they usually do not.

## The symptom is the part worth remembering

The crash this fixed happened **at the Capcom logo during startup, on game worker threads, with no
REFramework frame anywhere in the call stack**, with or without upscaling enabled. Nothing about it
pointed at a mod reading a struct at a stale offset. If this project ever meets a startup crash that
looks like it has nothing to do with the framework, **check the offset accessors before debugging
your own code** — it is a one-file read and it is upstream of every other hypothesis.

## Also on the same surface: upstream Lua array handling moved 2026-09-04

Directly relevant to the note your dossier added on 2026-09-04 about recording the revision beside
every Lua finding. `master` gained three data-model commits on 2026-09-04 (array element setting,
general array handling, string-versus-number ambiguity). The substantive one widens the
managed-array creation length to a signed 64-bit type so a negative length can no longer wrap into a
huge allocation, centralises index validation into one checked helper, and makes out-of-range
indexing return nothing or raise rather than behave undefinedly. **None of that is in either of your
builds.** The exposure shape is the one the sibling project already characterised: wrong values
rather than errors, and it lands on recon code rather than shipped scripts.

## What has already been done with this

Folded into the cross-engine library, so the sibling project sees it too without a second inbox drop:
`flat-to-vr-cross-engine-research` → [RE Engine family page](https://github.com/TefMeister/flat-to-vr-cross-engine-research/blob/main/docs/engines/re-engine.md)
(the new section on `via.render.Texture` offsets), and the engine-agnostic form in
`docs/techniques/README.md` → "the version that moves is usually the game's". **Nothing in this repo
was edited** — this lane only creates inbox files.

Credit: **porlock2** (the fix and its measurements) and **praydog** (REFramework); both are in the
library's `ATTRIBUTION.md`.
