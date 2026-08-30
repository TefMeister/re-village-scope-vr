# 2026-08-24 — gameplay-access via reflection: partial win, real wall found

Follow-up to the same day's RT-backing breakthrough + continuous-blit session. Goal: reach real
gameplay with the scoped rifle equipped (step 2's blocker — binding to the glass's actual material
slots needs the real weapon in view), sidestepping the fact that this dev PC's title-screen menu
doesn't respond to any synthetic keyboard/mouse input technique tried (see below).

## Screen-automation infrastructure built (reusable)

This project had no screenshot/input-injection tooling before this session. Built and validated:
- `capture.ps1` — foreground + screenshot a named process's window (`System.Drawing` `CopyFromScreen`).
- `pmkey.ps1` — `PostMessage(WM_KEYDOWN/WM_KEYUP)` to a window, bypassing global `SendInput`.
- `pmclick.ps1` / `pmdrag.ps1` / `pmscroll.ps1` — `PostMessage`-based mouse click/drag/wheel,
  moving the real OS cursor first (`SetCursorPos`) since REFramework's ImGui overlay reads live
  cursor position for hover state, not just the posted message's embedded coordinates.

**Real, reusable finding: this game only responds to `PostMessage`, not `SendInput`.** A first
attempt using `SendInput` (the standard global-injection API) failed at the Win32 level with
`ERROR_INVALID_PARAMETER` from a P/Invoke struct-layout bug (the `INPUT` union under-declared —
only `KEYBDINPUT`'s 24 bytes instead of the real 32-byte union that must also fit `MOUSEINPUT` —
making the whole struct 32 bytes instead of the required 40; `SendInput` rejects any `cbSize`
mismatch outright). Fixed the struct layout (confirmed `sz=40`, `SendInput` started returning
success) — but even success-reporting `SendInput` calls produced **zero visible effect** in the
game (confirmed via REFramework's own `Insert` overlay-toggle hotkey, a case with no game-logic
ambiguity — if `Insert` doesn't toggle the overlay, nothing is reaching the process). Switching to
`PostMessage(WM_KEYDOWN/UP)` **worked immediately** for the same `Insert` test. Conclusion: this
game/REFramework build reads its window's message queue, not the global low-level input stream —
worth remembering for any future automation on this project instead of re-discovering it.

## REFramework's ObjectExplorer navigated fully via PostMessage automation

Confirmed the built click/scroll scripts can drive REFramework's own ImGui debug UI end-to-end
(expand tree nodes, scroll a cramped fixed-size panel, drill into `DeveloperTools` → `ObjectExplorer`
→ `Singletons` → a specific singleton → its `TDB Methods`/`TDB Fields`). Located
**`app.SaveLoadFlowManager`** (43 methods) and **`app.SaveLoadManager`** (71 methods) this way, then
switched to a faster method-dump Lua autorun script (`sdk.find_type_definition(...):get_methods()`,
logged) rather than continuing to click through the GUI one node at a time — much faster once the
right singleton is known.

## `requestContinue()` — a real, working, reflection-only "press Continue" (partial win)

`app.SaveLoadFlowManager:call("requestContinue")` — called from a Lua autorun script via
`sdk.get_managed_singleton("app.SaveLoadFlowManager")` — **correctly reaches the real
continue-confirmation screen**, showing the actual latest save's real data (chapter name
"Heisenberg's Factory", not a placeholder) and a "A Continue" prompt. **This independently confirms
save data exists and is intact** on this dev PC (Steam Cloud cache at
`Steam\userdata\<id>\1196590\remote\win64_save\`, 26 `.bin` files — note the correct Steam AppID for
RE Village is **1196590**, not 2050650 which is RE4 remake; searching the wrong AppID briefly and
wrongly suggested saves might be missing, corrected via direct disk inspection).

**A follow-up call to `requestSlotLoadData()` was a mistake** — it does NOT confirm/continue the
already-queued Continue action. It navigates to an unrelated "Traveler Records" manual save-slot
browser (all 5 slots empty) — this game's Continue flow does not appear to use that numbered-slot
UI at all (likely a shared RE-Engine-wide component present in the reflection API but not populated
for this game's actual save system, which is autosave/checkpoint-based). **Do not call
`requestSlotLoadData()` after `requestContinue()`** — it's a dead end for this purpose, not a next
step.

## The real wall: the "A Continue" confirmation prompt is gamepad/XInput-only

Exhaustively tested every synthetic-input technique available without a virtual gamepad driver, on
this exact screen, all negative:
- `SendInput` (both before and after the struct-layout fix) — no effect (and per above, this whole
  game ignores `SendInput` regardless of the target key).
- `PostMessage(WM_KEYDOWN/UP)` for `VK_RETURN` (Enter) — no effect.
- `PostMessage(WM_KEYDOWN/UP)` for `VK_SPACE` — no effect (tried earlier, at the title screen, same
  no-response pattern).
- `PostMessage(WM_KEYDOWN/UP)` for `F` (`0x46`) — tried specifically because a *different* later
  screen ("Traveler Records" slot browser) showed an "F OK" keyboard prompt, suggesting F might be
  the game's real bound interact/confirm key regardless of displayed glyph — still no effect on the
  Continue confirmation screen specifically.
- Reflection: dumped **all 22 fields** of `app.SaveLoadFlowManager` (all flow-identifier strings or
  internal bookkeeping — `ContinueFlow`/`LoadSystemDataFlow`/etc. are just state-name constants, not
  triggers) and its live `flowContainer` (`app.SaveLoadFlowPrefabContainer`, 7 fields, all `via.Prefab`
  references, 0 methods) — no direct "confirm"/"accept" trigger found anywhere in this object graph.
- `useContinueSlotNumber()` (a method whose name suggested "commit to the slot Continue already
  picked") — called successfully (`ok=true`), zero visible effect on the confirmation screen.

**Conclusion: this specific confirmation prompt reads real XInput/gamepad state directly (matching
its own on-screen "Ⓐ" gamepad glyph), not the window message queue REFramework's own overlay and
this game's *other* screens (e.g. the F-key-driven slot browser) use.** This is a genuine, different
input path from everything else tested in this project so far — likely because it's implemented via
the game's native controller-prompt/confirm-dialog system rather than the same menu-navigation code
path as the title screen's Start Game / slot browser screens.

## What would actually solve this

Not attempted this session (out of scope for reflection-only automation, and each is a bigger
undertaking than this pass's budget):
1. **A virtual gamepad driver** (ViGEmBus + a script emulating an Xbox controller's A button) —
   would almost certainly work, since the game is clearly gamepad-input-aware at this exact screen.
   Requires installing a kernel driver, not done here without checking with the user first.
2. **Real human input** — the simplest fix: the user (or anyone) presses the real controller/keyboard
   confirm once, live, at this exact screen, while the rest of the automated navigation
   (`requestContinue()` etc.) does the rest.
3. **Further reflection digging**: hasn't checked whether a generic `app.InputManager`/`via.hid.*`
   singleton exposes a settable "virtual button state" the game's own confirm-dialog code reads —
   plausible but unexplored; would need its own dedicated investigation.

## Cleanup

All diagnostic scripts (`zz_savemgr_probe.lua` and its several revisions) deleted from
`reframework/autorun/` after use — none left deployed. Screenshot/input-automation `.ps1` helper
scripts live in the session scratchpad only, not copied into any repo (not project code, just
one-off Windows automation glue — flagging their existence here in case a future session wants the
same capability and prefers not to reinvent the struct-layout fix).

Game process killed cleanly. `re8_scope_vr_companion.lua` and the deployed `re_scope_vr.dll`
(from the earlier continuous-blit session, commit `faf8635`) are untouched and still correctly
deployed. No save files touched or modified — only read (existence check) and driven via the
documented reflection API, never written to directly.
