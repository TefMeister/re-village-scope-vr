# 2026-09-26 night (/lm, flat, Opus) — 🏆 THE RIFLE CAMERA ON THE SCOPE GLASS, AUTOMATICALLY

Plugin `6004633f` (clone-source mode: built by the session's reader, unit gain added by /lm), staging `6ba3028`.
One word, `clonescope 20`, no numpad, no src8, no crop words. `[verified-live 2026-09-26, n=1]` throughout.

- The Lua published `clone_src #29617`; the plugin armed its own re-arm, latched the clone's fresh 2560×1448 fmt=29 target,
  did **not** upgrade to fmt-26, sampled it whole and centred at unit gain.
- The clone sat on the scope pose (Body joint + lens mount + push), looking (−0.763, 0.130, 0.633) — along the rifle held up-left
  in flat; FOV 20 re-asserted; 219 post-process property values copied from MainCamera.
- **The glass shows the live, magnified world down the rifle**: a carved panel; a different panelled wall after strafing.
- Push along the bore: **0.30 m** shows the rifle's own front sight as a dark "V" at the top; **0.60 m** clear; **1.00 m** went through
  the door into the snowy exterior (proof it is on the rifle's line; also: the push must stay short, or be clipped by a ray, near walls).
- Still to fix: a band of **white speckle along the top** of the glass — most likely the 8 unrendered padding rows of the 1448-row
  target (the engine draws 1440) now sampled because clone mode takes the whole height `[hypothesis]`; and the picture is dim
  indoors (the game's own exposure; 219 values copied, unit gain).
