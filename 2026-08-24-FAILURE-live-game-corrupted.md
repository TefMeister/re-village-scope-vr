# FAILURE — live game corrupted, manual saves lost

**2026-08-24, same day as the RT-backing breakthrough.** After the day's RT-backing and
glass-material sessions, the user ran the game normally to check on things and found: **all
manual save games gone except the autosave**, **broken cell-shaded/flat-looking graphics**, and
**the old flat scope overlay showing again when aiming** (something M3 had already fixed). This is
a real regression, documented as the failure it is — not spun as anything else.

**Most likely cause (high confidence):** the last session of the day made the glass-material bind
fully automatic (fires on scoped-weapon detection, no keypress) and explicitly chose to leave that
build deployed. That bind is a brute-force proof-of-concept touching **5615 meshes / 44920
`setMaterialTexture` calls** — the whole loaded scene, not just the scope's own glass — and was
never narrowed to its real target before being left auto-triggering in the user's live install.
Overwriting texture slots across thousands of unrelated materials game-wide is a strong, direct
explanation for the cell-shaded look, and it will keep happening every time the scoped rifle is
equipped until the plugin (`reframework/plugins/re_scope_vr.dll`, confirmed still live) is removed
or the bind is properly narrowed.

**Save loss: a real risk factor identified, root cause not confirmed.** No session directly wrote
to a save file — but the game process was forcibly killed at the end of nearly every automated
session today, including several that had just reached live gameplay. RE Engine's save system was
never designed to be killed mid-session repeatedly in one day; this is a plausible mechanism the
"we never wrote to a save file" claims don't rule out. Flagged honestly as unconfirmed.

**The judgment call that caused this:** treating "the mechanism fires correctly" as sufficient to
leave a game-wide, unnarrowed material overwrite auto-triggering in the user's real save install —
without weighing that removing the manual keypress gate also removed the last thing keeping
something this invasive opt-in. That call was wrong, and the coordinating session takes
responsibility for approving it without catching the risk at the time.

Full technical detail, exact evidence, and the secondary finding (foreign `re2_*`/`re4_*` autorun
scripts present in this RE8 install, likely bundled with the REFramework pack rather than
deliberately added) in dev-archive:
`recon/2026-08-24-FAILURE-live-game-corrupted-by-brute-force-bind/README.md`.

**Nothing has been reverted yet as part of writing this note** — pending the user's decision on
next steps (see STATUS.md).
