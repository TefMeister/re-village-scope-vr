# A settings save was quietly promoting live experiments to defaults — and the panel now speaks harness words

**2026-09-18, dev PC `DESKTOP-V8GTSIR`, `/pd`, Opus. THE GAME WAS NOT LAUNCHED AND NOTHING HERE HAS BEEN RUN.**

Two board rows, both `[PD]`, both closed statically: the settings file eating live harness overrides,
and the VR tuning panel not being able to send a harness word. They turned out to be the same
session's work because they meet in one place — a click in the headset.

---

## 1. The defect: two kinds of knob, one save

There are two ways a knob moves in this mod, and until today the settings file could not tell them
apart.

* **Durable tuning** — the numpad, and the VR panel's numpad buttons. Numpad 7 flips the glass V
  flip; the handler calls `save_settings()` so the flip survives the next launch. That is the design
  and it is right.
* **A live harness word** — `framev 2`, `rbfb 1`, `hold 1`, typed into `re_scope_cmd.txt` while the
  game runs. These are session experiments. Every single one of them ships with a "not commanded"
  sentinel, precisely so that the settings value stands when nobody is experimenting.

`save_settings()` wrote every knob's **live** value. So any numpad press — or any click on the VR
panel, which feeds the same handler — captured whatever the harness happened to be holding at that
moment and wrote it into the settings file as the next launch's **default**.

That is not a hypothetical. On 2026-09-17 in the headset, pressing `7` while `framev 2` was up wrote
`frame_v=2`. It was caught by hand and reverted by hand `[verified-live 2026-09-17, n=1]`. Nothing in
the log said it had happened.

### ⚠️ Why it is worse than it looks

**An experiment that promotes itself is invisible in exactly the session that could catch it.** The
knob is already at that value, so the picture does not change when it is written. The cost lands on
the *next* launch, with no harness word in sight and nothing in any log connecting the two — which is
the shape of a mystery rather than a bug.

It is also the exact inverse of the `sw_delay` trap from earlier the same week: there, a
headset-verified fix was *not* shipped as a default and one machine silently booted without it. Both
are the same question asked badly — **what is a default, and what is a dial someone is holding?**

## 2. The rule, and why this one

**A key the harness can command persists the value it BOOTED with, never the value a live override
put there.**

It is decided per key, per save, from the pane file itself. The producer republishes every key every
cycle and writes the sentinel when no word is in force, so *"is this key commanded right now"* is a
fact read fresh each poll rather than a flag that can go stale. Nothing is remembered across a save.

Three consequences, stated plainly because two of them are trades:

* A harness word can no longer be made permanent by accident. **It also cannot be made permanent on
  purpose** — to keep one, put the line in `re_scope_vr_settings.txt` by hand, which is what `RTX`
  already did for `sw_delay`. Silence was the thing being fixed, so that is the right way round.
* Knobs the harness cannot reach — exposure, `mir_cx`/`mir_cy`, `glass_flip_v`, the grading knobs —
  are untouched and still persist their live value, because for them the live value *is* the
  decision.
* `crop_mode` / `crop_follow` / `aspect_mode` were never affected: they were given their own `g_lua_*`
  atomics back on 2026-09-06 and are merged at the point of use. That is the older, heavier form of
  the same idea, and it is why 25 of the 28 harness-reachable keys needed this and three did not.

**And the save now says so.** When it declines a live value it logs one line naming every knob, what
was kept and what was on the dial. The failure this exists for was silent; the fix must not be.

## 3. What was built

* `plugin/src/boot_values.h` — the whole decision as a pure function plus a 25-key registry, no D3D
  and no engine types, so the test compiles the shipped code rather than a transcription of it. Same
  shape as `rgate::decide` and `holdm::classify`.
* `plugin/src/config.cpp` — the registry instance, a `capture_boot_values()` called once after
  `load_settings()`, and every registry key's argument in the save routed through it. The key/global
  pairing is **one table** used by both the capture and the decline-log, so a key cannot be captured
  in one place and persisted from another.
* `plugin/src/pane_file.cpp` — a `kCmdKeys` table of key + sentinel, `static_assert`-locked to the
  registry's size, and one `note_commanded(k, v)` call placed **ahead of the whole dispatch chain**,
  so a key cannot be handled and left unmarked.
* **`geom_vflip` joined the settings file in the same change.** `load_settings()` had always parsed
  it and `save_settings()` had never written it — so a hand-edited `geom_vflip=` line was deleted by
  the next numpad press. Same class of silent loss, and the test below found it while it was being
  written. `hold_diag` is the one key deliberately left load-only: it is a countdown, and persisting
  it would re-arm diagnostics on every launch.

`tools/boot_values_test.cpp`: **152/152** `[verified-numerically 2026-09-18]`. Four of its nine
sections read `config.cpp` and `pane_file.cpp` **as text** and re-derive the registry from them — the
half-applied-patch failure is what this project keeps hitting, and a missing registry key does not
look broken either, it just silently keeps persisting the live value for that one knob.

### ⚠️ The mutation run found a hole in the test, and that is the most useful thing here

Five deliberate breaks were introduced one at a time. Four were caught. The fifth — gutting
`note_commanded` so it marks nothing — **passed all 148 checks with the original bug fully restored**.

Every check verified a table or a formula; none verified that the single call joining them was still
made. Check 9 now does, and the re-run catches all five:

| break | caught by |
| --- | --- |
| the save writes the live `frame_v` again | 6 |
| a sentinel stops matching its own dispatch guard | 7 |
| a key registered under a name nothing uses | 5, 6, 7, 8 (×2) |
| the decision reverts to "always persist live" | 1a, 1f, 3d, 3e |
| **the pane poll stops marking anything** | **9c** |

**The lesson is not about this fix.** A suite of pure-logic checks around a wiring change tests the
ends and not the join, and it reads as thorough while doing it. Mutating the join is what showed that.

## 4. The VR panel can send harness words now

Second row, same click. The panel spoke only numpad codes, so every harness word — `hold`, `src8`,
`rerig`, `bind`, `holddiag` — meant leaving Virtual Desktop, typing at the desktop and coming back,
per knob, mid-test. There are now 21 buttons that write the word straight into `re_scope_cmd.txt`,
which the harness polls twice a second. A whole wear can stay inside the headset.

Two details that are easy to get wrong and are the reason for the test:

* **The harness consumes that file by writing it EMPTY, not by deleting it.** So "already taken" is
  an *empty read*, not a missing file. A missing-file test — which is what the existing key queue
  correctly uses for its own file — would overwrite queued words here and lose them unseen.
* **The harness applies every line it finds**, so several clicks inside one poll window travel
  together and all of them run. That is deliberate: `hold 1` then `holddiag 120` is the intended pair.

`scripts/tests/panel_words_test.lua`: **132/132** `[verified-numerically 2026-09-18]`. It reads the
harness's own dispatch rather than keeping a list, so a renamed word fails here instead of in the
headset. It checks that every button's word is one the harness knows, that a word needing a value is
given one, that no two buttons share a label (imgui keys on the label, so duplicates silently stop
responding), and that the flush is called and guards on a non-empty read. Proved able to fail on all
five of those, one mutant each.

The panel also now says on screen that a word is a session experiment and will not be saved — which
is the §1 fix made visible at the only place someone would be surprised by it.

## 5. Keeping the log across launches

Third row, cheap. REFramework empties `re2_framework_log.txt` at every start; the 2026-09-17 session
made three launches and the two that mattered survive only as something typed out by hand.

`mod/helpers/KEEP-LOG.bat` copies the log to `reframework/logs/re2_framework_log-<timestamp>.txt`,
and `mod/helpers/LAUNCH-VILLAGE.bat` calls it and then starts the game through Steam
(`steam://rungameid/1196590`, read from this machine's own Steam manifest). Use that shortcut instead
of the Steam one and nobody has to remember.

Tested on a fake log in a scratch folder, not in the game folder and without launching anything:
correct timestamped copy, exit code 0 `[verified-numerically 2026-09-18, n=1]`. The timestamp comes
from `wmic` with a PowerShell fallback, because `wmic` is gone on newer Windows builds.

## 6. Deployed, and what is NOT established

Rebuilt with the bundled VS CMake (the one on `PATH` is 4.4 and cannot configure this cache), the DLL
and `panel.lua` deployed into the game folder with dated `.bak-2026-09-18b` backups, and all 28 files
re-stamped and hash-verified — the path list taken from the existing record and de-duplicated,
because `deployed.sh record` replaces rather than merges and a naive re-glob has doubled the count
before.

**Nothing here has been run.** Specifically:

* That the plugin actually boots with the captured values and declines the right ones is
  `[compile-verified 2026-09-18]` and nothing stronger. One flat launch says it: set a harness word,
  press a numpad key, read the settings file and look for the decline line.
* That a panel word button reaches the harness in a running game is untested. The file contract and
  the button table are checked; the click is not.
* `KEEP-LOG.bat` was tested on a fake log, not on a real REFramework one, and `LAUNCH-VILLAGE.bat`
  was **not** run at all — `/pd` does not launch games.

Credit: **praydog** (REFramework).
