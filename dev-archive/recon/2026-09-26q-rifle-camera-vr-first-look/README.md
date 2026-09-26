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
