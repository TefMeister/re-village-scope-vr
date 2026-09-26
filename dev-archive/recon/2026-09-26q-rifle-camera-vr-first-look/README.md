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

## 🏆 Third VR look, 23:36-23:45 — THE RIFLE CAMERA WORKS IN VR (Tefa in the headset)
- `clonedist`: DistortionType 0 on MainCamera's RenderOutput, the clone's RenderOutput and the clone's layer — the eye-tag lead is
  `[disproved 2026-09-26]`. Plugin po watch: the clone's PrepareOutput chain does NOT rotate (1 TargetState, 1 texture over 300
  presents) `[verified-live 2026-09-26, n=1]`. The glass still showed grey + letters (the frozen desktop path).
- Switched the clone to the authored FLOAT target (`clonehdr 1`, no clonepo): Tefa *"it looks like the correct picture with correct
  colours upside down"*; the saved `glass_flip_v=1` (the mirror needs it in VR) flipped the clone. After numpad 7 twice: *"it's working
  - the colours could be a little brighter, but it really feels so so good now! the shots are landing where i point as well, which
  ever way i angle the rifle, but they seem to land a little bit lower, just by the amount the left motion controller was raised to
  fight the occlusion drift"* `[reported 2026-09-26]`.
- Made automatic (plugin 561e367f + cam_fix): in VR the clone uses the float target and no clonepo; the clone ignores glass_flip_v;
  `glass_flip_v=1` restored in re_scope_vr_settings.txt for the mirror scope.
