# 2026-09-24 flat test: auto-start on draw, early eye pose, two-press flip

`/lm` on the home PC (`RTX`), flat (REFramework logged `XR_ERROR_FORM_FACTOR_UNAVAILABLE`), driven by
`re8drive.py` from the title screen to the last save (the Stronghold, rifle in hand). `log-excerpt.txt`
is the relevant lines of `re2_framework_log.txt` from this launch. `[verified-live 2026-09-24, n=1 launch]`

| What | Result |
| --- | --- |
| Auto-start saw the rifle | 0.4 s after Continue: `rifle in hand -- starting the scope` |
| Its three steps | rtex 1280, re-arm (+3 s), bringup (+6 s): all logged, bat gaps kept |
| Rig built | 0.1 s after bringup: `autostart: DONE` |
| Eye pose at the rig | `P10: pane defaults set -- pitch=90 yaw=90 fwd=0 up=0 right=0.20` in the same frame as the rig; the five words re-sent at +3 s; no `propnear` |
| Picture latch | `MIRROR SOURCE latched 1280x728`, upgraded to raw HDR; `mirror_latched=1`, `glass_bound=2`; `bringup: DONE` at +28 s |
| One numpad 7 | `PICTURE FLIP ARMED ... NOT flipped`, glass_flip_v stayed 1 |
| Two quick numpad 7 | flipped to 0 and saved; two more flipped back to 1 |
| Settings file after the test | byte-identical to the backup taken before it |

Not seen: the picture itself. A capture caught another window on top of the game, and focus was
not stolen to retake it. Whether the scope shows no Ethan's clothes from the first moment is a
headset question. The flip log line says "FLIPPED UPSIDE DOWN" on the flip back too; cosmetic.

Auto-start was left ON afterwards. `VR-TRUE-SCOPE*.bat` now step aside when it is on (tested both
ways in a scratch folder), so running them from habit cannot pick the picture target under a live rig.
