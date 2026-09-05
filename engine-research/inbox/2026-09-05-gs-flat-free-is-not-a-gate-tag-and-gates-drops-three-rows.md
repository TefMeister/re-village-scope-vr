Supersedes: `claude-memory/status/re-village-scope-vr.md`, the three `[FLAT, free]` gate tags introduced 2026-09-05 12:05

# `[FLAT, free]` is not a gate tag — `/gates` is silently dropping three RE Village rows

Filed by `/gs`, 2026-09-05, home PC. Read-only sweep; nothing was edited.

## What is wrong

`claude-memory/status/re-village-scope-vr.md`'s `OPEN` block carries three rows tagged
**`[FLAT, free]`**. The gate grammar admits exactly four names — `PD`, `USER`, `FLAT`, `VR` — so
`gate-scan.sh --check` rejects them:

```
re-village-scope-vr          bad tag [FLAT,] - must be PD, USER, FLAT or VR
```

`/gates` then **drops those three rows entirely** and prints
`!! THE BOARD IS INCOMPLETE - 1 problems, so the counts above are a FLOOR, not the truth`.

The affected rows are the bind-guard identity probe, resolution lever 2, and the atmosphere
post-mortem — **all three of which are "read one log line on any launch"**, i.e. precisely the
cheapest items the board exists to surface. They are currently invisible on it.

## Who did it, and when

**This session did, an hour before filing this.** The `/pd` pass at 12:05 (`5ea05bb`) added them.
Worse: the `/lm` pass at 11:40 (`e8d55fe`) had *just* cleaned this same block — its commit message
is literally *"bad tags fixed"* — and the `/pd` pass put bad tags straight back in a new form.

Recorded plainly because the pattern matters more than the instance: `[FLAT, free]` was written
because it is **more** informative to a human than `[FLAT]`. That is exactly the failure mode
`/gs` check 3b describes for confidence tags — *"reads as a tag to a human, counts as nothing to
every tool"* — and it turns out to apply to gate tags too. The extra word cost three rows their
place on the board.

## The fix (one word each, modding lane)

Change the three `[FLAT, free]` to `[FLAT]` and move "free" into the prose, e.g.
`[FLAT] **(free — any launch answers it)** …`. The block already uses that shape elsewhere:
`[FLAT] (cheap, optional)` and `[FLAT] (deferred behind VR)` both parse cleanly, because the
qualifier sits **outside** the brackets.

Verify with:

```
bash claude-memory/tools/gate-scan.sh --check
```

Clean when it reports no violations. `[verified-numerically 2026-09-05]` — the violation, the
dropped rows and the "BOARD IS INCOMPLETE" banner were all reproduced from `origin/main` this
session.

## Worth noting for the convention

The `OPEN` block grammar has no way to say "this row is free" — a qualifier that is genuinely
useful and that three separate rows wanted. If that keeps recurring, it may be worth a convention
decision rather than repeated cleanups. Not proposing one here: `CONVENTIONS.md` is modding's and
the vocabulary is deliberately fixed.
