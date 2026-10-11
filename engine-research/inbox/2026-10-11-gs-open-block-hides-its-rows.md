# /gs 2026-10-11: the board's OPEN block shows no jobs to /gates

From: /gs sweep, 2026-10-11. For: the modding lane (owner of `claude-memory/status/re-village-scope-vr.md`).

`gate-scan.sh --check` reports **"OPEN block has no rows"** for this project `[measured 2026-10-11]`.
The first line under `OPEN (2026-10-10):` is not a tagged row (it starts with a tick or a star, not
`[PD]`/`[USER]`/`[FLAT]`/`[VR]`), and the parser stops reading there. So every real row below it is
invisible to `/gates`, and the gate board understates this game's open work.

Same fault as Bulletstorm's 2026-10-08 drop.

**Fix (one line):** move the done/decided note out of the OPEN block (into the log below it), or put it
after the tagged rows, so the block starts with a `[TAG]` row. Then re-run `gate-scan.sh --check`.
