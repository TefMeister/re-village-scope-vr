# 2026-09-26 22:02 — the rifle camera's first look in VR (Tefa in the headset)

`[verified-live 2026-09-26, n=1]` (log) / `[reported 2026-09-26]` (Tefa's screenshots):
- The glass showed mostly flat grey, sometimes huge white letters (game UI text).
- Log: the finished-picture texture in VR is **1559x1670** (per-eye render size), and it leaves RENDER_TARGET **twice per frame**
  (flat: once). The plugin copied write #1 — not the rifle camera's.
- Also: at startup the plugin read the PREVIOUS session's PrepareOutput address from `re_scope_po.txt` and retried it 128 times
  (the SEH walk refused it each time). Fixed: the Lua clears the file at load; the plugin ignores its first read.
- Fix built and installed (plugin 69def0c8): copy EVERY write of the frame, so the last one wins (flat: the same single write;
  VR: the second). `clonepo 1` / `clonepo 2` pick one write if the last is not ours.
- Tefa asked how to unfreeze the desktop monitor while playing in VR: REFramework menu (Insert) → VR → Desktop Recording Fix →
  Enabled / Skip Present (both on in re2_fw_config.txt). Effect not read in source yet [hypothesis: Skip Present stops the desktop copy].

## Second VR look, 22:50 (Tefa in the headset, `clonepo 2`)
`[reported 2026-09-26]`: the glass showed the text of the FROZEN DESKTOP WINDOW ("Checking for additional content. Please do not
close the game...", the loading screen the monitor froze on), mirrored left-right — Tefa read it letter by letter. So in VR the
texture reached through our clone's PrepareOutput TargetState is the desktop/flat output that REFramework's VR mode stops updating,
not the clone's picture. Both writes (the texture leaves RENDER_TARGET twice a frame) belong to that path. The picture dump key does
not work in VR, so no dump. Also: "outside while inside" for the first second happens in flat too (Tefa) — most likely the near plane
(muzzle + 5 cm = ~0.85 m) clipping a nearby wall [hypothesis].
