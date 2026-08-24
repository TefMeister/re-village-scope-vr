# Gameplay-access via reflection: partial win, real gamepad-only wall

Follow-up session to the RT-backing breakthrough and continuous-blit work, aimed at reaching real
gameplay (scoped rifle equipped) to finish binding to the glass's actual material slots.

**Real win:** `app.SaveLoadFlowManager:call("requestContinue")` via Lua reflection correctly
triggers the game's own "Continue" flow — confirmed by reaching the real confirmation screen
showing the actual latest save's data ("Heisenberg's Factory"). This also confirms save data is
intact (checked the correct Steam AppID, 1196590 — an earlier moment of confusion briefly checked
the wrong AppID and looked like saves might be gone; they aren't).

**Real wall:** the confirmation screen's "Ⓐ Continue" prompt only accepts genuine gamepad/XInput
input. Exhaustively tried Enter, Space, and F (the latter because a different screen showed an
"F OK" keyboard binding) via both `SendInput` and `PostMessage`, plus a full reflection dump of the
flow manager's fields/methods looking for a direct trigger — all negative. This is a different
input path from everything else in this project (REFramework's own overlay and other menu screens
do respond to `PostMessage`-based keyboard input; this one specifically doesn't).

**What's needed to actually get past it:** a virtual gamepad driver (ViGEmBus) emulating an Xbox
controller's A button, or a real human pressing the button once live. Neither attempted this
session — flagged as the concrete next step rather than guessed at further.

**Also built, reusable:** PostMessage-based screenshot/click/scroll/drag Windows automation for
driving REFramework's own ImGui overlay (this project had none before). Real finding worth keeping:
this game ignores `SendInput` (the global input-injection API) entirely, even with a correct struct
layout — only `PostMessage` to the window reaches it.

Full detail: `re-village-scope-vr-dev-archive/recon/2026-08-24-gameplay-access-continue-flow/`.
