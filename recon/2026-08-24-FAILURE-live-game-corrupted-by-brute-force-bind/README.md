# 2026-08-24 — FAILURE: live game corrupted, manual saves lost

**This is a failure report, not a success writeup.** After the same day's RT-backing/glass-material
sessions, the user ran the game normally (not through any automation) to check on things ahead of
taking this to the home PC, and found: **all manual save games gone except the autosave**, **graphics
rendering with a broken cell-shaded/flat look**, and **the old flat scope overlay showing again when
aiming** (the thing an earlier milestone, M3, had already fixed). The user directly attributes this to
the day's automation work and asked for it to be documented honestly as a failure — this is that
document. Coordinating session takes responsibility for approving the choices below without weighing
the risk clearly enough at the time.

## Most likely root cause, high confidence: the currently-deployed plugin is still live and still doing this

The last session of the day (`2026-08-24-glass-material-in-real-gameplay`) fixed a real timing bug in
`ensure_created()`, then made the glass-material bind **fully automatic** — firing on scoped-weapon
detection with no keypress needed — and explicitly chose to **leave that build deployed** ("this fix
is a strict improvement over the prior session's build... so it was kept live rather than reverted").

The bind itself (`bind_holder_to_mesh`) is a **brute-force proof-of-concept**: it calls
`setMaterialTexture` on **5615 meshes / 44920 calls** — every mesh in the loaded scene, not just the
scope's own glass materials (narrowing to the real target, mats 2/3 slot 1, was explicitly left as
unfinished future work in that same session's own report). Overwriting a texture slot across
thousands of unrelated meshes' materials — including, almost certainly, normal maps, specular maps,
and other PBR inputs the brute-force pass didn't distinguish from the intended albedo slot — is a
very plausible, direct explanation for a broken, flat/cell-shaded look across the whole scene: those
lighting-relevant texture inputs get overwritten with the scope's RT content (or fail to bind
correctly against the wrong slot), and normal per-pixel shading breaks game-wide.

**This is not a one-time corruption from testing — because the fix made the bind auto-trigger on
weapon detection with no gating, and that build is still the one deployed (`reframework/plugins/
re_scope_vr.dll`, confirmed live, no backup suffix), this will keep happening every time the scoped
rifle (`ri3042`) is equipped, in any future play session, until the plugin is removed, disabled, or
the bind is properly narrowed to just the real glass material slots.**

**Verdict on the earlier session's own judgment call**: treating "the mechanism fires correctly" as
sufficient justification to leave a game-wide, unnarrowed material-overwrite auto-triggered in the
user's real, live game install was the wrong call. A proof-of-concept that touches 5615 meshes by
design should have stayed behind an explicit, session-only manual trigger (like the original F4
keypress it replaced) until narrowed to the actual intended target — "no keypress needed" was treated
as a usability win without weighing that it also meant "no longer opt-in for something this invasive."

## The flat scope overlay returning: plausibly downstream of the same corruption

M3 had already fixed the flat scope overlay (`GUIScope`) staying hidden correctly during ADS. Its
return could be: (a) a side effect of the same broad material corruption disrupting whatever the
companion Lua's hide logic depends on, (b) an exception/crash partway through the 44920-call brute-force
bind leaving downstream per-frame logic (including the companion's GUIScope-hide) in a bad state for
the rest of that session, or (c) something separate not yet identified. **Not confirmed** — flagged
honestly as the most plausible read given the evidence, not a proven mechanism.

## Save games lost except the autosave: real risk factor identified, root cause NOT confirmed

Every session's own report states no save files were written to directly — only read (existence
checks) and driven via `app.SaveLoadFlowManager` reflection calls (`requestContinue()`,
`useContinueSlotNumber()`), which per those reports only *read*/*navigate* save state. Taken at face
value, none of the day's documented actions should have deleted manual saves.

**However, a real, undocumented risk factor ran through every gameplay-reaching session today:** the
game process was **forcibly killed** (not cleanly exited) at the end of essentially every automated
session, including sessions that had just reached real gameplay, triggered weapon-detection logic,
and fired a 44920-call native texture-binding pass — i.e., the game was killed while in an active,
possibly mid-write gameplay/autosave state, repeatedly, over many sessions in a single day. RE Engine's
save system was never designed with "get forcibly terminated moments after loading Continue" as a
normal operating condition. **This is a plausible, undocumented mechanism for save-slot loss that no
individual session's "no save files touched" claim rules out** — "we never wrote to a save file"
and "abruptly killing the process during/after live gameplay corrupted the save index or clobbered
slots as a side effect of an unclean shutdown" are not mutually exclusive.

**Honest status: root cause of the save loss is NOT confirmed.** The brute-force-bind explanation
above has direct, strong supporting evidence (exact mechanism, exact call count, exact "kept it live"
decision on record). The save-loss explanation is a real, identified risk factor from today's
methodology, not a proven mechanism — flagging both rather than picking one to look tidy.

## Secondary finding: foreign autorun scripts present in this game's REFramework install

`reframework/autorun/` currently contains `re2_sharpness_removal.lua`, `re2_smooth_movement.lua`,
`re2_vr_crosshair.lua`, `re2_vr_grenade.lua`, `re2_vr_melee.lua`, `re4_vr_crosshair.lua` — none of
which belong in an RE Village (RE8) install. These most likely came bundled with whatever REFramework
nightly/VR-pack archive got installed on 2026-08-22/24 (some community REFramework distributions ship
example scripts for multiple games in one archive) rather than being deliberately added by any session
here — the Visceral RE2 project's own history documents this exact pattern (foreign scripts that
early-return harmlessly when the game doesn't match) happening there too. **Not confirmed to cause any
of the symptoms above** (RE-specific scripts typically early-return on a game-ID check when the
running game doesn't match), but it's real evidence the REFramework install itself is messier than it
should be, and worth a cleanup pass regardless.

## What is still live on disk right now (as of this report, dev PC)

- `reframework/plugins/re_scope_vr.dll` — **the auto-bind build, live, not backed up under this
  session's own name** (the backup chain is `re_scope_vr.dll.pre-d3d12hook-backup` →
  `.pre-blit-backup` → `.pre-autobind-backup`, each one older than the currently-deployed file).
  **This build will keep firing the game-wide brute-force bind on every scoped-weapon equip until
  removed or fixed.**
- `reframework/autorun/re8_scope_vr_companion.lua` — the flat-scope Lua companion, unchanged by
  today's native-plugin work as far as any session reported.
- The six foreign `re2_*`/`re4_*` autorun scripts noted above.

**No action was taken to remove/revert any of this as part of writing this report** — the user asked
specifically for documentation first. See STATUS.md for the recommended immediate next step (removing
or reverting the plugin) pending the user's go-ahead.

## Lesson for future sessions on this project (and this project's own convention going forward)

A proof-of-concept that deliberately brute-forces every mesh in a scene (documented, on the record, as
"not yet narrowed to the real target") must not be left auto-triggering in a live, real save-game
install just because the underlying mechanism is confirmed working. "The mechanism fires correctly"
and "this is safe to leave running unattended in the user's actual game" are different bars, and this
session's chain conflated them. Anything this invasive should default to a manual, explicit,
session-only trigger until it's been narrowed to its real, intended scope — the same discipline this
project already applies to keeping unverified builds out of the public `-mod` repo should also apply
to what's left auto-running in the user's own live install between sessions.
