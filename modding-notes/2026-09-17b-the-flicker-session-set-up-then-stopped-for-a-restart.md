# 2026-09-17b — the flicker session: set up, then stopped for a PC restart (`/ms`, home PC `RTX`, Opus)

**The game was never launched. Nothing here has been run.** The session was set up and then ended
at Tefa's request ("i need to restart pc") before step 1.

## Why this entry exists at all

So the next session does not repeat the set-up. Everything below is ready on `RTX` right now.

## What was done

- **Pre-flight clean.** All 19 installed files match the `RTX` stamp (`deployed.sh check`), which is
  the split build of 2026-09-17 morning. The `/gs` inbox drop was drained: the dossier's line 1405
  tag `[inferred, n=1 log]` became `[inferred-static 2026-09-13]` with the source in the prose. The
  three modding-notes hits in that drop were deliberately left alone — they are dated records of
  what was believed on the day, and rewriting them would be rewriting history rather than fixing a
  tag that a tool reads.
- **Four double-click helpers written** into the game folder and committed to `mod/helpers/`:
  `FLICKER-1-COUNT.bat` (`hold 1`), `FLICKER-2-HIDE.bat` (`hold 2`),
  `FLICKER-3-EIGHTBIT.bat` (`hold 1` + `src8 1`), `FLICKER-OFF.bat` (`hold 0` + `src8 0`).
  `[compile-verified 2026-09-17]` — the batch syntax is checked and the commands match the harness's
  own parser (`re8_scope_harness.lua`, `cmd == "hold"` / `"src8"`); none has been run.
- **`START-SCOPE.bat` and `FIX-SCOPE-GLASS.bat` are now in git for the first time.** They were
  written on 2026-09-14 for the Andyalpa tester package and existed only in this machine's game
  folder and inside that zip. That is the same one-place pattern that nearly lost the REFramework
  patch and did lose XIII's proxy source.

## Two things learned on the way, both worth keeping

1. **The harness applies *every* line of `re_scope_cmd.txt`**, not just the first (its own comment,
   line 8: "read … apply every line, delete the file"). So one double-click can send two commands,
   which is what the 8-bit test needs `[inferred-static 2026-09-17]` — read from the source, not run.
2. **`echo hold 1> file` silently drops the `1`.** `cmd` parses `1>` as a stream-1 redirect, so the
   file receives `hold` alone — which the harness would read as a command with no value and ignore.
   Every helper puts the redirect first. A first draft of these files hit exactly this and a second
   `printf` bug (`\re_scope` eating a carriage return), both caught by reading the written file back
   rather than trusting the write.

## Why the picture cannot be driven from inside the headset

Worth stating plainly, because it shapes every `/ms` turn on this project: the VR tuning panel
(`re8scope/panel.lua`) only offers the **numpad hotkeys** as buttons — exposure, white balance,
flips, crop slide. The harness words (`hold`, `src8`, `bringup`, `rerig`, …) have no panel button,
and a keyboard does not reach the game window in the headset. So a knob with no hotkey can only be
reached by writing the command file, i.e. by clicking something on the desktop through Virtual
Desktop. Hence the helpers. **A future `/pd` could add the flicker knobs to the panel** and remove
the desktop trip entirely; that is a genuinely cheap row and is now on the board.

## The session that was about to run

Unchanged from `2026-09-16-the-one-frame-flicker-read-from-the-code-and-three-knobs.md` §6, which
stays the authority. In short: `bringup` and count flickers by eye → `hold 1` and compare the log's
spike count with what was seen → `hold 2`, is the flicker gone → `hold 1` + `src8 1`, is it gone
*and* do the spikes stop (⇒ the pooled buffer is the cause) → next launch `fn rtex_hdr`.

**The one outcome that would overturn the derivation:** `hold 1` logs no spikes while flickers are
seen. Then the change happens after our blit and none of the three knobs can touch it.
