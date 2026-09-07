# The §9g projection unknown has a `[PD]` route: read the mirror's own render layer

**From:** `/gr` (estate sweep, 2026-09-07) · **For:** the modding lane, to fold into
`ENGINE-DOSSIER.md` §9g (and the board's ⭐ `[VR]` row)

**Full write-up:** [`external-research/topics/2026-09-07-the-mirrors-own-render-layer-can-answer-the-projection-question-without-a-headset.md`](../../external-research/topics/2026-09-07-the-mirrors-own-render-layer-can-answer-the-projection-question-without-a-headset.md)

## The dead end this is aimed at

Dossier **§9g**, quoted:

> "**Two unknowns hid inside 'project into the mirror's render'.** (1) `via.render.Mirror`'s
> projection: does it render with the viewing camera's projection (then the 1920×1088 target holds a
> 0.933-aspect eye view anamorphically, and NDC maps 1:1 onto the texture), or does it render its own
> 16:9 projection at the same size … Flat cannot tell the projections apart (0.7 %); VR can (1.9 %)."

That routed the question to a headset launch trying four candidate mappings. Two have now been run
and both still swing.

## What this session found — in our own record, not on the web

**§9g treats the Mirror as the thing that holds the projection. It does not.** This project's own
2026-08-30 finding is that `via.render.Mirror` is a stub and the **`via.render.layer.Scene`
instance created per mirror is the real control panel** — the finding that produced the clipping
kill, and the one the cross-engine library carries as *"A mirror's real control panel is its own
render layer"*.

That layer's **full method list is already printed in two of our own recon logs** (2026-09-06 flat
and 2026-09-06d VR) `[verified-live 2026-09-06, n=2 launches]`, and it carries:

- `via.Camera get_Camera()` — is the mirror's camera the main/eye camera, or its own?
- `via.Size get_Size()` / `get_FilterSize()` / `get_PostSize()` — the size it actually renders at
- `System.UInt32 get_ViewID()` — once per frame, or once per eye?
- `System.Single get_HorizontalScreenScale()` + `get_UpdateHorizontalScreenScale()` — the exact
  shape an anamorphic squeeze would take
- `via.render.HMDResolutionType get_HMDResolutionType()` — the layer type is VR-aware by design

**No value of any of them has ever been read or logged** `[verified-numerically 2026-09-07]` — the
logs dump the type surface and stop. The layer resolver that would do the reading is already live
and captures 4 instances in a flat launch and 10 in a VR launch. L5 already fetches the layer camera,
purely as a guard ("refuses to write if it's shared with the main camera"), and never prints it.

## Suggested dossier change

In **§9g**, add that the projection question has a **static route that precedes the four-candidate
sweep**: instrument the existing layer resolver to print `get_Camera` (and whether it equals the main
camera), `get_Size`, `get_ViewID`, `get_HorizontalScreenScale` and `get_HMDResolutionType` for the
layer matching our mirror, and read it on a flat launch already queued. Record the reading table
from the topic file. Keep the `[VR]` row — this may reduce it to a confirmation rather than replace
it, and a flat launch cannot observe a VR-only `ViewID` split.

⚠️ Two stated ways for this to be wrong, both in the topic file and both free to check in the same
log line: the captured layer may not be the one rendering our mirror at read time (several may claim
it in VR — which is itself the per-eye answer), and a shared camera object does not prove a shared
projection, so read the size and the horizontal scale alongside it.

Claim strength: **`[hypothesis]`** on the route, `[verified-live]` on the method list existing and
`[verified-numerically]` on no value ever having been read.

## Nothing public exists on these type names

Searched 2026-09-07; the queries reached REFramework's site and repo, community guides,
`elliotttate/vrframework` and a Capcom RE Engine rendering session, and returned **no coverage of
`via.render.layer.Scene`'s VR getters at all**. Recorded as "no public coverage found", not as proof
none exists (research rule 7).
