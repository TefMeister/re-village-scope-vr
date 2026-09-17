# /gs 2026-09-17: four `[inferred …]` tags are off-vocabulary

**From:** `/gs` sweep, home PC, 2026-09-17. **Owner:** modding.

`[inferred …]` is not one of the eight names, so each of these reads as a claim to a human and counts
as untagged to every tool (`/gs` check 3b) `[verified-numerically 2026-09-17, n=4 lines read]`:

| File | Line (at 2026-09-17) | Tag as written |
| --- | --- | --- |
| `engine-research/ENGINE-DOSSIER.md` | 1405 | `[inferred, n=1 log]` |
| `modding-notes/2026-09-13c-first-wear-of-the-exact-map-steering-off-is-the-closest-yet.md` | 39 | `[inferred, n=1]` |
| `modding-notes/2026-09-13d-the-headsets-real-lens-shape-two-frame-knobs-and-a-frame-dump.md` | 15 | `[inferred 2026-09-13 from the log; …]` |
| `modding-notes/2026-09-13g-the-crate-host-invisible-walls-and-the-wrong-rifle.md` | 102 | `[inferred from the above]` (undated too: both defects) |

**Fix:** reasoning from a log or other evidence is `[inferred-static YYYY-MM-DD]`, with the `n=` and the
source moved into the prose beside it. The first two also need a date. Line numbers drift; search
for `[inferred`. Modding notes are dated records, so if you would rather not edit them, fixing the
dossier line is the one that matters.
