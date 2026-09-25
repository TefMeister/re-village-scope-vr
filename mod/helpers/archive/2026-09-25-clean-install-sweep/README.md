# Probe and test helpers, archived 2026-09-25 (the clean-install sweep)

On 2026-09-25 Tefa asked for the whole Village install to be rebuilt from a clean game folder, with
the mod added back as one tidy package. The game folder held about a hundred helper files by then,
almost all of them written for one evening's test and never needed again. The eight that a player
(or a session) actually uses stayed in `mod/helpers/`; everything else moved here, unchanged.

Nothing here is lost: every file is also in the full backup taken before the clean-up
(`D:\RE Village REFramework builds\full-backup-2026-09-25-before-clean-install\`, checksummed), and
the reasoning behind each one is in `engine-research/ENGINE-DOSSIER.md` and the modding notes.

| Family | Files | What they were for | Where it ended |
| --- | --- | --- | --- |
| `AIM-TEST-*`, `READ-ME-AIM-TEST.txt` | 4 | the 2026-09-19/20 aim-line tests | superseded by the two-shot zero |
| `CROSSHAIR-FROM-*` | 3 | which pose the crosshair is placed with | the drawn pose won (2026-09-22), now a switch file |
| `DIG-SPREAD`, `RIFLE-*`, `TWO-HAND-FIX-*` | 6 | the bullet-spread and rifle-straightening levers | the spread cancel is the shipped default (`re_scope_spread.txt`) |
| `EYE-LOCK-*`, `PICTURE-*`, `FLICKER-*` | 16 | the one-frame flicker hunt | the eye lock fixed it (2026-09-22); on by default |
| `GRIP-*`, `STACKED-GRIP-*` | 15 | the two-handed grip variants | button-only docking, stacked grip: in the loader build `2150cdbc` |
| `PLAN-C-*`, `SCOPE-STEER-*`, `SCOPE-DISTANCE-*`, `TEST-*` | 24 | mirror-pose, steering, distance-follow and the 2026-09-17 nine-build checks | plan C off for good; distance-follow on by default |
| `ZERO-*` (except `ZERO-BY-TWO-SHOTS`) | 21 | the hand-nudged zeroing and its bookkeeping | replaced by the two-shot zero, which also saves itself |
| `START-SCOPE*`, `VR-TRUE-SCOPE-1080/1440` | 5 | manual scope start, per picture size | the auto-start does it on the draw; `VR-TRUE-SCOPE.bat` stays as the one manual fallback |
| `CURRENT-/MORNING-/PLUGIN-YESTERDAY/UPDATE-*` | 6 | build swapping for A/B tests | every build lives in the builds archive with a manifest now |
| `scope-rearm-key.ps1`, `scope-steer-config.ps1` | 2 | the keystroke bridge before the plugin had its own key channel | the plugin reads `re_scope_vr_keys.txt` itself |

Counts are approximate; the file list is the folder itself.
