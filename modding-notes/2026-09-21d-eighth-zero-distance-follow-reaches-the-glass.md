# 2026-09-21 (d) — the eighth zero, and the distance correction finally reaches the scope picture

Home PC, Tefa in the headset, 16:40–16:47.

**What happened.** The morning's "near and far hit the same spot" result had been withdrawn: the
distance correction was only moving a part of the picture that is no longer used, so it could not
have helped. The fix (dossier §9ce) was built and installed but had never been run. This was its
first run.

**What the log shows.** Every one of the seven shots carries `picture turned 1.6 deg for it` at
13.0 m, so the correction now really turns the scope picture. `[verified-live 2026-09-21, n=7
shots, one distance]` Tefa re-zeroed with it on and landed at **up −10.7 / right −9.5** (from
−11.9 / −7.1). The sideways move of 2.4° is close to the ~2° that §9ce predicted.
`[verified-live 2026-09-21, n=1 wearer]`

**Saved.** The new zero is the default in the start-up script, the settings file, the reset helper
and the zeroing read-me — in the repos and in the game folder.

**Still owed.**

- ~~The near/far test.~~ **Done ten minutes later, same launch, zero untouched:** near (5.3 m), far
  (13.0 m), near again (5.0 m). The picture turned 3.6° / 1.6° / 3.7° for them, and Tefa: *"they
  really do seem to all go in the right place!"* `[reported 2026-09-21]`, turn figures
  `[verified-live 2026-09-21, n=3 shots, 2 distances]`. Left: confirm on a second day, then make
  distance-follow the shipped default.
- **And again after a restart (17:01 launch):** the saved zero came up by itself, ten shots near and
  far, Tefa: *"yes, still land where they have to!"* `[reported 2026-09-21]`
  `[verified-live 2026-09-21, n=10 shots, 1 restart]`. No zero shift across this restart.
- The 1920×1080 scope picture. This launch latched the 2560×1448 picture, so the new default size
  has still never run — and the restart did the same, two launches out of two.

**17:30 — why the 1080p picture never took.** The size picker in `rig.lua` had no case for
"prefer 1920": it was written when 1920 was already first in the default order, and nobody added
one when 2560 became first on 2026-09-18. The request was accepted and logged, then ignored.
`[inferred-static 2026-09-21]` One line added, existing size test 9/9, installed
`[compile-verified 2026-09-21]`, not run. The next launch is also the first real test of the
tightened 1920 latch window, so a black scope is possible — `START-SCOPE-SHARP-1440.bat` is the way
back.

Evidence: `dev-archive/recon/2026-09-21-eighth-zero-distance-follow-reaches-the-glass/`.
