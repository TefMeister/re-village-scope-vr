# 2026-09-13a — The whole scope set-up is one command: `bringup` (`/pd`, home PC `RTX`, NO LAUNCH)

**The game was not launched and nothing here has been run in the game.** Source: `staging/re-village-scope-vr/`.
Dossier §9v.

## What was built

Last night's hand-typed recipe (2026-09-12 23:46–23:51, the run that ended silent, invisible and live) is now
one line in `re_scope_cmd.txt`:

```
bringup
```

It does, in order, each step through the same code path as if it had been typed (so each logs its own
`harness:` line):

1. `fn pfb_goat`, `fn p10` — refuses if a rig already exists (`fn destroy_rig` first).
2. Waits for the rig (fails loudly after 10 s, binds nothing).
3. `fn drive_on`, `model 0`, `steer 1`, `mrollsym 1` — only the settings that do **not** survive a relaunch.
   `crop_follow`, `mroll_k`, `mroll_off`, `ret_depth` live in the plugin's settings file and are left alone,
   so a value tuned in the headset is never silently overwritten.
4. `fn goat_armour` (new) — the prop's hit/damage parts off.
5. `fn goat_vanish` — which **now also silences** (pendulum `Gain 0`, pendulum left ON).
6. Waits for the plugin to report `mirror_latched=1` (warns and binds anyway after 10 s).
7. Presses numpad `*` (glass bind) through the VR panel's own key queue, then **again at +5 s and +20 s**.
8. `pendset Gain 0` once more (idempotent, logs the read-back), then `bringup: DONE`.

Also new: `bind` (one numpad `*` press, for when the stock crosshair shows) and `fn goat_armour` on its own.

## Decisions worth knowing

- **The re-binds are blind, on purpose.** Last night a bind logged `2 slot(s) bound` and the glass still showed
  the stock crosshair; a later press stuck `[verified-live 2026-09-12, n=1]`. The plugin cannot detect the
  undo (no stable texture identity — the guard is disabled for that reason), so a detector was not possible.
  Re-pressing is harmless: the plugin's bind opens with a restore. ⚠️ Whether +5 s / +20 s is late enough is
  **unknown** — the undo's timing was never measured (the successful second press was ~3 min later). If the
  stock crosshair is back after `DONE`, that is a finding about the undo's timing, and `bind` fixes it.
- **Armour touches the root only.** The 22:26 strip already disabled those three types there without harm.
  Children are only reported (`LEFT ON`), because nothing has ever been disabled on a child and the pendulum
  lesson says the visible goat hangs off one. Whether an enemy can break the prop at all is `[hypothesis]`.
- **The row asked for "re-bind if the stock reticle is still visible".** That condition cannot be read, so it
  became "re-bind twice, then tell the wearer the one word to type".

## Verified

- `scripts/tests/bringup_sequence_test.lua` **23/23** — drives the real harness file with the game stubbed:
  the order, exactly three presses, and the refusal paths (rig exists, no rig, no latch, double `bringup`)
  `[verified-numerically 2026-09-13]`. It checks sequencing only, not that any step works in the game.
- Older suites unchanged: `steer_axis_test` 61/61, `steer_corr_test` 71/71. Both Lua files pass `luac -p`;
  new `string.format` calls run against dummy arguments.
- **Pre-flight install check:** the stamp said three files had CHANGED. They had not been replaced by anything
  foreign — the two scripts match the committed source apart from line endings, and a fresh `/Brepro` build of
  the plugin hashes **identical** to the installed DLL (`612dcf33…`). The stamp was simply never re-recorded after
  last night's final deploy. Re-recorded now, after this deploy: 4/4 OK.
- Backups beside the installed files: `*.pre-bringup-backup-2026-09-13`.
