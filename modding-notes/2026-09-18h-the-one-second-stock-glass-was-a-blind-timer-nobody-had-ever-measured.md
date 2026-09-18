# The one-second stock glass was a blind timer nobody had ever measured

**2026-09-18 · `/pd`, dev PC (DESKTOP-V8GTSIR) · STATIC ONLY — THE GAME WAS NOT LAUNCHED AND NOTHING
HERE HAS BEEN RUN IN THE GAME.**

Board row closed: *"the one-second stock glass on switching back to the rifle"* (`[PD]` ⭐).

---

## The complaint

Put the sniper rifle away, take it out again, and for about a second the scope shows Capcom's own
dark glass with the orange reticle instead of our picture. Then it snaps to ours
`[reported 2026-09-14, n=1 wearer; screenshot]`.

The *other* half of that switch — the flash when the rifle is put **away** — was fixed on
2026-09-17 with `swdelay 1500`, which holds our glass on the way out and worked on 11 of 11
switches `[verified-live 2026-09-17, n=11]`. This note is the way back **in**, which was untouched.

## What was actually in the code

`world_tick.cpp` scheduled the re-bind blindly:

```cpp
static const unsigned long long kDueMs[2] = { 1000, 5000 };   // press 1 of 2, press 2 of 2
```

Two presses, at a fixed one second and a fixed five seconds after the rifle returns, the pattern
copied from what `bringup` needed. The second is a safety net for when the first is too early.

**The important part is not that 1000 is too big. It is that 1000 was never compared with
anything.** No line in the log has ever said when the glass would actually have gone back on, so
the number is a guess from 2026-09-14 that has been treated as a measurement ever since — and
simply shrinking it would have replaced one guess with a smaller one. A press that lands too early
does not retry; it fails silently and the stock glass then stays up **until the +5 s press**, which
is four seconds worse than the fault being complained about.

There is also a case the old schedule got wrong in the opposite direction. Since 2026-09-16 the
restore is deferred while the rifle is being put away, so switching away and straight back leaves
our glass **never taken off** — and the old code still fired both presses, each of which restores
the stock texture and re-binds ours for no reason.

## What it does now

Try on the very next tick, and keep trying every ~150 ms until the bind takes or six seconds have
passed — then say, in the log, how long it really needed:

```
[re-scope-vr] auto re-bind: rifle back in hand -- binding the glass as soon as it will take
[re-scope-vr] auto re-bind: press 1 at +0 ms
[re-scope-vr] auto re-bind: the glass took after 16 ms, 1 press(es)
```

The decision is a pure function in `src/auto_rebind.h`, in the same shape as `rebuild_gate.h`, so a
test can run it against scripted timelines instead of a transcription of it. The four numbers are
named in `rsv.h` (`kAutoRebindFirstMs` 0, `kAutoRebindRetryMs` 150, `kAutoRebindGiveUpMs` 6000,
`kAutoRebindMaxTries` 40) rather than sitting inline, which is also one small piece of the
code-shape row.

**Why retrying is safe, from the shipped bind path** (`glass_bind.cpp`, read this session):

- `bind_scope_glass()` refuses outright when the holder, the rifle or the mesh is missing, and
  binds nothing when it refuses — so a failed early attempt costs a log line, never a wrong bind,
  and `glass_has_binds()` stays false so the next attempt happens.
- It opens with `restore_scope_glass()`, so attempts can never stack overwrites.
- It only ever touches the equipped rifle's own mesh and saves every original first, so an early
  attempt has exactly the same blast radius as a late one.

The two cheap preconditions (the holder exists, the rifle is in hand) are checked before a press is
issued, purely so a per-tick retry cannot fill the log with refusals. They are a courtesy, not the
safety.

## What is established, and what is not

- **`[compile-verified 2026-09-18]`** the plugin builds clean with the rework
  (`re_scope_vr.dll`, sha256 `d883b41990035d99…`, 235,520 bytes), and is **deployed** on the dev PC
  with the previous build kept beside it as `re_scope_vr.dll.bak-2026-09-18f`.
- **`[verified-numerically 2026-09-18]`** `tools/auto_rebind_test.cpp` — **45/45 checks**, compiled
  against the shipped header. The suite was proved able to fail by mutating that header **nine**
  ways (the old +1 s press restored; one press and no retry; `first_ms` ignored; the holder
  precondition dropped; a queued press overwritten; the retry gap off by one; the try cap made dead
  code; success made to outrank cancellation; the deadline made never to fire). **All nine were
  caught**, and the header was restored and re-run at 45/45 afterwards.
- ⚠️ **`[hypothesis]` — the glass is bindable sooner than +1 s.** That is the claim this rework
  exists to *test*, not a result. It is entirely possible the log comes back saying every switch
  needs ~1 s anyway; that would be a real answer too, and it would mean the delay lives somewhere
  else entirely. **Nothing here has been run with the game up.**
- ⚠️ **Not established: that the retry cannot be noisy in practice.** A rifle whose mesh never
  resolves would log up to forty refusals over six seconds. No such case has been seen, and the two
  preconditions cover the two failures that have been; this is a judgement, not a measurement.

## The one check to run next time the game is up

Bind the glass (numpad `*`), switch to another weapon, switch back, and read the log for:

```
auto re-bind: the glass took after N ms, K press(es)
```

- **N well under 1000** — the row is answered and the second of stock glass is gone. Record N; it
  is the first real measurement of this.
- **N around 1000 or more** — the delay is **not** the timer, and the rework has bought nothing but
  the number. The next question is what the bind is waiting for, and `press 1 at +0 ms` followed by
  several refusals in the log will say which precondition it is.
- **`GAVE UP … the glass is still stock`** — a regression; the old blind schedule would also have
  failed here, but silently. Say so and read the refusals above it.
- **`the glass took after 0 ms, 0 press(es)`** — the deferred restore held and our glass never came
  off. Correct, and the old code would have re-bound twice for nothing.

## A mistake to record

The deploy backup was copied to `re_scope_vr.dll.bak-2026-09-18`, which **already existed** from an
earlier build the same day, so that older backup was overwritten before it was noticed. The new
backup was renamed to `…-2026-09-18f` to fit the existing a–e run. Nothing important is lost — every
build is reproducible from the source in `staging`, and the *currently* replaced build is safe in
`f` — but the next session should use a fresh letter and check first.

## Files

- `plugin/src/auto_rebind.h` — new; the decision, with the reasoning above it.
- `plugin/src/world_tick.cpp` — the schedule swapped in; `auto_rebind_t0` / `auto_rebind_n` gone.
- `plugin/src/rsv.h` — the four named constants.
- `plugin/tools/auto_rebind_test.cpp` — new; 45 checks.

(Source lives in the private `staging/re-village-scope-vr/` monorepo, as ever.)
