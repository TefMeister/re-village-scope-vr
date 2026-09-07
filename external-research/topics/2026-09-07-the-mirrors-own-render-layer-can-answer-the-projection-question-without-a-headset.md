# The mirror's own render layer can answer the §9g projection question — statically, with no headset

**Status:** 🆕 new · **Priority:** high — it proposes a `[PD]` route to the one unknown the board
currently schedules a headset launch for, and the machinery it needs is already built and running.

## Why this was looked up

The board's ⭐ `[VR]` row is the most expensive item on this project: finish the crop-mapping sweep
with `cropmode 1` and `cropmode 3`, having already spent a headset launch on modes 2 and 0 with the
same answer both times — Tefa, 2026-09-06 23:15: *"it is still acting the same, moving around the
pipe of the scope, and the picture inside is moving where i look and tilt"*
`[verified-live 2026-09-06, n=1 observer, 2 of 4]`.

Those four candidates exist because dossier **§9g** could not separate two unknowns:

> "(1) `via.render.Mirror`'s projection: does it render with the **viewing camera's** projection
> (so in VR the 1920×1088 target holds a 0.933-aspect eye view **anamorphically**, and NDC maps
> 1:1 onto the texture), or does it render **its own 16:9** projection at the same size?"

§9g's honest conclusion is that flat cannot tell the two apart (0.7 %) and VR can (1.9 %), so the
question was routed to the headset. This session went looking for a public answer, found none —
and then found that **the question may not need a public answer, because the object that holds it
is already in our own hands.**

## The finding: the layer that renders the mirror exposes its own camera, size and view ID

On 2026-08-30 this project established `[verified-live 2026-08-30, n=1 game]` that
`via.render.Mirror` is a stub — register/unregister a scene, a visibility flag, a render target —
and that **the real control panel is the `via.render.layer.Scene` instance the engine creates per
mirror**, reachable only by an observe-only hook that retains every `this` it sees. That is how the
clipping kill was found (`modding-notes/2026-08-30-abi-root-cause-clipping-kill-layer-control-panel.md`),
and it is generalised into the cross-engine library as
[*"A mirror's real control panel is its own render layer"*](https://github.com/TefMeister/flat-to-vr-cross-engine-research/blob/main/docs/engines/re-engine.md).

**That layer's full method list is printed in our own logs, and it speaks directly to §9g.** From
`dev-archive/recon/2026-09-06-sharpness-and-stranded-latch/launch1-filtered-log.txt` and
`dev-archive/recon/2026-09-06d-2560-authored-target-vr/launch-key-lines.txt`
`[verified-live 2026-09-06, n=2 launches — one flat, one VR]`:

| accessor on `via.render.layer.Scene` | what reading it would settle |
| --- | --- |
| `via.Camera get_Camera()` | **§9g unknown (1), close to outright.** If the layer's camera **is** the main/eye camera object, the mirror renders from the viewing camera and the anamorphic reading is the live one. If it is a **distinct** `via.Camera`, the mirror has its own camera — and that camera's own getters then hand over FOV and aspect instead of them being inferred. |
| `via.Size get_Size()`, `get_FilterSize()`, `get_PostSize()` | the pixel size the layer actually renders at, against the 1920×1088 (now 2560×1448) target it writes into. A size whose aspect is the **eye's** ≈0.933 rather than the target's 16:9 is the anamorphic case, measured rather than deduced. |
| `System.UInt32 get_ViewID()` / `set_ViewID(...)` | whether the mirror renders **once per frame or once per eye**. §9g never separated this from the projection question, and it changes what "the crop swings when I tilt" means. |
| `System.Single get_HorizontalScreenScale()`, `get_UpdateHorizontalScreenScale()` | a per-layer **horizontal** scale factor is the shape an anamorphic squeeze would take, and it has a live-updating companion flag. If it is not 1.0 in VR, it is a term the crop maths does not currently carry. |
| `via.render.HMDResolutionType get_HMDResolutionType()` | the layer type is **VR-aware by construction** — an HMD resolution mode is a field on the *render layer*, not only on the eye path. |

Also on the list, unrelated but worth having: `get_MultiResolutionFlip`, `get_SharedTag`,
`get_ResizeFrame`, `get_LODBias`, `get_DistortionType`, `get_Cutscene`.

## What is and is not already done

**Built:** the layer resolver is live and captures instances every launch — `LAYER captured:
via.render.layer.Scene @ …` appears **4 times in the 2026-09-06 flat launch and 10 times in the
2026-09-06 VR launch** `[measured 2026-09-07, n=2 logs]`. The capture is the hard part and it works.

**Not built:** *no value of any of those accessors has ever been read or logged.* The logs print the
**method list** — the type's surface — and stop there `[verified-numerically 2026-09-07]`. A grep
across every recon log in the repo finds the accessor names only inside `FULL method list` dumps,
never beside a value; the same grep finds the 10 `LAYER captured` lines, so it was capable of a
positive.

The one existing consumer of the layer's camera is **L5**, which "reads the layer camera first and
**refuses to write** if it's shared with the main camera" — a *guard* on the far-clip sky
experiment. So the code to fetch the camera exists; what is missing is that its answer is never
printed, and nobody has connected that answer to the crop question.

## ⚠️ Why this is a proposal and not a result

The claim here is **`[hypothesis]`**, deliberately, and it has two ways to be wrong:

1. **The layer we capture may not be the one rendering our mirror at the moment we read it.** Ten
   instances are captured in a VR launch; the match is by `get_Mirror` address against our own
   mirror, and that match has only ever been exercised for the clipping kill. If several layers
   claim our mirror in VR — one per eye would be the interesting case — that is itself the answer
   to `get_ViewID`, but it means "the layer's camera" is not a single object.
2. **A shared camera object does not by itself prove a shared projection.** RE Engine can hand the
   same `via.Camera` to a pass that then overrides its projection. So read `get_Size` and
   `get_HorizontalScreenScale` **alongside** `get_Camera`, and treat agreement across all three as
   the verdict rather than any one of them.

Neither risk costs a launch to check: all of it comes out of the same log line.

## The concrete next step this unlocks

A **`[PD]` item** — static, compile-verifiable, no game running: extend the existing layer resolver
so that, whenever it captures the layer matching our mirror, it prints one line carrying
`get_Camera` (address, plus whether that address equals the main camera's), `get_Size`,
`get_FilterSize`, `get_PostSize`, `get_ViewID`, `get_HorizontalScreenScale` and
`get_HMDResolutionType`. Then **one flat launch already on the board** reads it, and the table is:

- layer camera **==** main camera, `Size` aspect ≈ the eye's, `HorizontalScreenScale` ≠ 1.0
  → the **anamorphic** reading; candidates built on the shared projection are the right family.
- layer camera **≠** main camera, `Size` 16:9 → the mirror has **its own** camera; read that
  camera's FOV and aspect and compute the mapping **directly** instead of choosing among four.
- **more than one** layer matching our mirror with **different `ViewID`s** in VR → the mirror runs
  **per eye**, which no current candidate models, and the swing has a cause none of the four
  addresses.

Any of the three is worth more than another headset launch, and the third would explain why modes 2
and 0 behaved identically.

⚠️ **This does not retire the `[VR]` row.** It may reduce it from a four-way sweep to a
confirmation, or it may leave it exactly as it is. It is offered as the cheaper thing to do first,
not as a replacement — and note that a flat launch cannot read a VR-only `ViewID` split, so the
per-eye branch above still needs the headset to be *confirmed*, only not to be *guessed at*.

## Sources

- **Our own record**, which is where this actually was:
  `re-village-scope-vr/modding-notes/2026-08-30-abi-root-cause-clipping-kill-layer-control-panel.md`
  (the layer's API and the capture method);
  `dev-archive/recon/2026-09-06-sharpness-and-stranded-latch/launch1-filtered-log.txt` and
  `dev-archive/recon/2026-09-06d-2560-authored-target-vr/launch-key-lines.txt` (the full method
  list, flat and VR); `engine-research/ENGINE-DOSSIER.md` §9f/§9g (the question).
- [flat-to-vr-cross-engine-research → `docs/engines/re-engine.md`](https://github.com/TefMeister/flat-to-vr-cross-engine-research/blob/main/docs/engines/re-engine.md),
  *"A mirror's real control panel is its own render layer"* — the library page that made the
  connection visible, itself generalised out of this project.
- **praydog — REFramework** (<https://github.com/praydog/REFramework>, <https://reframework.dev/>):
  the framework whose type dumps produced the method list above.

## The public web has nothing on this — and the search was capable of finding it

Two searches for the RE Engine type and accessor names by name (`via.render.layer.Scene` with
`ViewID` / `HorizontalScreenScale` / `HMDResolutionType`; and REFramework render-layer per-eye view
IDs) returned **no coverage of these type names at all** `[checked 2026-09-07]`. The searches were
not blind — they reached the right space, returning REFramework's own site and repository, community
REFramework guides, Elliott Tate's `vrframework` and a Capcom RE Engine rendering conference session
— so the absence is about **these engine internals being undocumented publicly**, not about the
query missing. Per research rule 7 that is recorded as "no public coverage found", not as proof none
exists.
