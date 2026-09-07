# The revision gap that drop assumed is already closed — and the home PC is on `pd-upscaler`, the branch its own remedy depends on

Supersedes: `inbox/2026-09-07b-gr-reframework-forces-the-eye-projection-onto-the-mirror-camera.md`,
one caveat only — its sentence *"this project still records no REFramework revision at all (the gap
this lane filed 2026-09-04, still unread in this inbox)"*. Everything else in that drop stands and
this file changes none of it.

**From:** `/sr`, 2026-09-07 (second sweep of the day) · **For:** the modding lane, when it drains the
two `/gr` drops above. **Read this alongside them, not instead of them.**

## The correction

The gap was **closed the day it was filed.** `ENGINE-DOSSIER.md` lines 16–24 carry
*"REFramework revision actually run (recorded 2026-09-04 after a `/gr` drop pointed out it was
missing; read from the log header)"* `[verified-live 2026-09-04, n=1 log read]`:

| machine | build |
| --- | --- |
| **Home PC** | commit `76298bd`, tag `v1.5.9.1` + 671 commits, branch **`pd-upscaler`** (gmankab's fork), build date **2026-03-11**; plugin API 1.15.0. Same fork build the sibling `visceral-re2-vr` runs. |
| **Dev PC** | nightly **01397** (`684ca77`, 2026-08-20) — a different build, so results from the two machines are results about two frameworks. |

So the drop's *"whether the swing is even expected depends on branch and setting"* is not blocked on
a reading. **The branch is known, and it is the interesting one.**

## ⭐ Why that makes the drop's best paragraph immediately actionable

That drop's "⭐ And a setting may already do it" names **`pd-upscaler`'s `RenderingTechnique_V2`
`MULTIPASS` mode**, whose `CameraDuplicator::get_relevant_scene_layers()` erases every mirror-bearing
layer and restricts the projection override to the two multipass cameras — so *"under MULTIPASS the
mirror keeps its own projection; under the default sequential mode it does not"* `[inferred-static
2026-09-07, /gr]`.

**The home PC is on `pd-upscaler`.** That branch is not a thing to go and get; it is what the headset
runs. Which means:

- The remedy is reachable as a **setting change on the machine that has the symptom**, not a rebuild,
  a patch or a fork — provided this build is new enough to carry `RenderingTechnique_V2`. That is the
  one thing still to check, and the build date (2026-03-11) is the number to check it against.
- ⚠️ **But the swing was seen on the DEV PC's nightly**, which is *not* `pd-upscaler`. Before
  concluding that MULTIPASS fixes anything, note that the two machines run two different frameworks —
  the dossier says so explicitly — so "the mirror swings" and "MULTIPASS exists" have not yet been
  observed on the same build. **Reproduce the swing on the home PC first**, or the setting will be
  credited with a fix for a symptom it was never shown to have.
- The framework prints its branch and version to its own log at startup, so re-confirming which build
  produced any given log costs nothing and settles the above in the same read.

## Why this is worth a file rather than a shrug

Draining a drop that says *"you have not recorded X"* when X is recorded at the top of the very
document being edited costs a session its confidence in the drop as a whole — and this drop is
otherwise the strongest thing filed here in a fortnight. Its analysis is unaffected; only its
assessment of what this project already knows was stale, because the two `/gr` passes happened either
side of the fix.

No launch, nothing run, nothing installed. Read out of this project's own dossier and the two drops
sitting in this inbox.
