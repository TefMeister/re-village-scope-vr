# Three `[inferred …]` tags in `modding-notes/` read as confidence claims and count as nothing

Filed by `/gs`, 2026-09-19, dev PC (thirty-first run). **Read-only sweep; nothing was edited.**
All three lines read out of the working tree today `[verified-numerically 2026-09-19]`.

`inferred` is **not one of the eight names**. The vocabulary is `verified-live`,
`verified-numerically`, `compile-verified`, `measured`, `inferred-static`, `reported`, `hypothesis`,
`disproved`. A tag outside it looks like a graded claim to a human and is **invisible to every
tool** — including the check that is supposed to notice untagged claims, which passes a document
whole if it has any valid tag at all.

## The three

| file | line | as written | should be |
| --- | --- | --- | --- |
| `modding-notes/2026-09-13c-first-wear-of-the-exact-map-steering-off-is-the-closest-yet.md` | 39 | `` `[inferred, n=1]` `` | `` `[inferred-static 2026-09-13]` `` |
| `modding-notes/2026-09-13d-the-headsets-real-lens-shape-two-frame-knobs-and-a-frame-dump.md` | 15 | `` `[inferred 2026-09-13 from the log; the new build prints IMPROPER explicitly]` `` | `` `[inferred-static 2026-09-13]` `` — keep the "from the log" detail in the prose beside it |
| `modding-notes/2026-09-13g-the-crate-host-invisible-walls-and-the-wrong-rifle.md` | 102 | `` `[inferred from the above]` `` | `` `[inferred-static 2026-09-13]` `` |

⚠️ **The third one carries both defects at once** — an invented name *and* no date. That is the exact
case the UNDATED bucket of check 3b was re-labelled for on 2026-09-05, after an earlier label reading
"usually prose about a tag" caused a real one to be waved through.

⚠️ **The precision belongs in the prose, never inside the tag.** `[inferred, n=1]` and
`[inferred from the above]` are both trying to say something true and useful about *how well* the
claim is known — that is the right instinct, and the wrong place for it. Put the qualifier in the
sentence and leave the tag as one of the eight names, or the tool cannot count it.

## One thing that is NOT a defect, so nobody re-files it

`modding-notes/2026-09-17b-the-flicker-session-set-up-then-stopped-for-a-restart.md:14` also matched
check 3b, in the DATED bucket:

> tag `[inferred, n=1 log]` became `[inferred-static 2026-09-13]` with the source in the prose.

**That line is a changelog recording a fix that was already made, and it is correct as written.**
A changelog has to quote the old tag verbatim, date and all, which is precisely why the check has a
"quoted in correction prose" bucket — but that bucket keys on words like *retagged*, *now reads* and
*supersedes*, and this line uses **"became"**, which is not in the list. So a correctly-documented
fix landed in the bucket that says "fix these".

**That is a tooling gap worth one word** (`tools/gs-scan.sh`, check 3b's correction-language list),
and it is the same self-reinforcing error the 09-05 split was built to remove: a lane that does the
right thing and writes it down gets a permanent false positive for it. Noted here rather than filed
separately because the fix is in the modding lane's own tool.

Lane: /gs
