# 2026-09-16b — the save-reload "security camera": on every rig rebuild the plugin now falls back to the picture buffer that follows the new rig (`/pd`, dev PC, Fable, NO LAUNCH)

**The game was not launched and nothing here has been run.**

## 1. The row

*A save reload strands the mirror latch — "the security camera".* After an in-game reload the hand
rides the rifle again but the picture in the scope does not move with it; Reset Scripts does not
fix it, a full relaunch does `[verified-live 2026-09-13, n=1 wearer]`. The plugin's own lines told
the story: a fresh launch prints `rig rebuild #1: the latch followed (gen 1 -> 2)`; after the reload
it printed `at the latched width (1920) and the latch did not change`.

## 2. Why it happens (from the code, `[inferred-static 2026-09-16]`)

- The Lua's holder is made from a **path** (`movie/rtex/movie_1920_1080.rtex`), and the engine
  caches resources by path. After the reload, `bringup` reused the same holder — the note records
  "no `rig rebuild #2` line" and no new allocation.
- The plugin's picture source is not that holder's 8-bit target but the **upgraded raw-HDR buffer**:
  the next 1920×1088 float allocation the engine made after it, an intermediate that belongs to
  whatever pass the engine gave it to. With no new allocation there was nothing to re-latch, so the
  plugin kept sampling the **old** buffer. The new mirror resolved into the reused holder — the
  8-bit target the plugin had retired at upgrade time — and rendered its HDR pass elsewhere.
- So the glass showed a buffer nobody was aiming any more: a fixed viewpoint, "the security camera".
  This is the same pooled-buffer weakness the morning note (`2026-09-16-the-one-frame-flicker…`)
  suspects for the one-frame flicker; the reload case is its slow-motion version.

## 3. What was built (compile-verified, tested with the game stubbed, deployed on the dev PC, NOT run)

- **The fallback (plugin, default ON, `rbfb 0` switches it off):** on every rig rebuild counter bump
  from the Lua, if the source is the upgraded HDR buffer and the 8-bit resolve was kept (it is,
  since this morning), the plugin **swaps back to the 8-bit resolve at once**, retires the HDR buffer
  fence-safely, and the upgrade watch reopens by itself — the next fmt-26 allocation of that size
  is taken as the new HDR source, exactly as at launch. Log line:
  `rig rebuild #n: source fell back to the 8-bit resolve … the upgrade watch is open again`.
  While no new HDR allocation arrives the picture is the 8-bit one (sunlight clips to white) —
  correct and riding, instead of stale.
- **`rerig`** (harness): one word for the reload case — tears the dead rig down if one is recorded,
  then runs the whole `bringup`. Before this it was two commands and a rule to remember.
- Settings file carries `rb_fb`; the pane carries it live.

Numbers: plugin 0 errors, 0 warnings; all six suites pass again (16 / 124 / 40 / 176 / 20 / tone);
fxc 5/5; three Lua files compile; `bringup_sequence_test` 29/29. Dev-PC install re-stamped 14/14.

## 4. What is NOT established

- That the reload picture is *stale* rather than *a different live pass* — the fix covers both.
- Whether a save reload makes the engine allocate a fresh fmt-26 buffer for the new mirror. If it
  does not, the scope stays on the 8-bit picture after a reload until the next relaunch — riding
  and correct, but with clipped sunlight. `fn rtex_hdr` (the float target, see the morning note)
  would remove that limit too, since a path-bound float target needs no upgrade at all.
- The stranded-latch amber indicator now sees the fallback as "the latch followed" (the latch
  generation bumps), which is the truth, but it means the indicator no longer flags this case.

**The diagnostic that would show the derivation is wrong:** after `rerig` the log prints the
fallback line and the picture **still** does not ride the rifle. Then the 8-bit resolve is not
receiving the new mirror either, i.e. the reused holder is not what the new mirror renders into —
the Lua side (holder / RenderOutput binding on the new rig) would be the place to look, not the
plugin's latch.

## 5. NEXT (headset, home PC, inside any session)

1. Play until a reload is natural (or reload a save on purpose).
2. Type `rerig`. Expect the log line `rig rebuild #n: source fell back to the 8-bit resolve`, then
   either `MIRROR SOURCE UPGRADED to raw-HDR allocation` a moment later (best) or nothing more
   (8-bit picture, still fine).
3. Look: the scope picture rides the rifle again? — done, the row closes. Still a security camera?
   — §4's last paragraph.
