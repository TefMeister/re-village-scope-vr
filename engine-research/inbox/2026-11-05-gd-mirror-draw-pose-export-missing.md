# Gold Digger, 2026-11-05: the installed REFramework no longer has the scope's mirror-pose export

From: `/gd` on the dev PC (PC2), reading the visceral-re8-vr "guns" shelf (the scope's session log is shelved there).

`[measured 2026-11-05]` Every `re_scope_vr_session.log` copy on the shelf, 20 of them from 2026-11-04 17:18 to
2026-11-05 12:43 (home PC), says:

    REF_GetMirrorDrawPose missing -- the crosshair maths keeps the camera joint's pose

So the REFramework installed in the Village folder is not the patched one this repo built (the one that exports the pose
the mirror was drawn from, used for the crosshair and its once-a-second self-check). The scope still works, falling back to
the camera joint's pose; the self-check angle cannot be logged.

The first shelved copy already held 15 of these lines, so it started before 2026-11-04. `[hypothesis]`: the 2026-10-31 clean
REFramework rebuild on the Visceral (visceral-re8-vr) side replaced the patched `dinput8.dll` without the scope's export.

Proposed board row: `[PD] Put REF_GetMirrorDrawPose back into the REFramework build both Village mods share (one patch set,
so neither mod's rebuild drops the other's export); check one scope log no longer says "missing".`
