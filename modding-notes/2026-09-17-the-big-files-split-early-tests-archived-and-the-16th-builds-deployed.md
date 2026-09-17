# 2026-09-17: the big files are split, the early tests archived, and the 09-16 builds deployed

Home PC `RTX`, `/lm`. The user asked for the big files to be backed up and cut into smaller pieces,
and for the early tests to be cleared out, keeping only what makes the scope work. The work followed
the code-hygiene proposal of 2026-09-16 (`claude-memory/docs/plans/2026-09-16-code-hygiene-pass.md`),
which the user approved today.

## What changed

**Backups first.**
- Tag `pre-split-2026-09-17` in `staging` (at `95557a5`) and in `psychonauts-vr` (at `ac86506`).
- Copies of the three big files and the split map in `C:\Users\TD3KX\big-file-backups-2026-09-17\`.
- The install as it was, in `reframework/_archive-2026-09-17/deployed-before-2026-09-17/`
  (plugin `38518f0`, producer `6d111ac`, harness `fc5e535`).

**`Plugin.cpp` (5,624 lines) → 15 files plus `rsv.h`**, the largest being `present.cpp` at 798 lines.
Move only; `staging` `4f9fcb6`.
- 0 warnings, and all nine unit suites give the same counts as before.
- `check-shader.sh` passes 5/5; it now reads `src/shader_src.cpp`.
- Against the pre-split build: the same 2 exports, the same 79 imports, and the same set of 513
  strings `[measured 2026-09-17]`.

**`re8_scope_m6_mirror_producer.lua` (6,758 lines) → a 56-line entry file plus 13 modules in
`autorun/re8scope/`**, the largest being `rig.lua` at 425 lines. `staging` `1d17332`.
- 2,823 lines moved verbatim.
- **3,935 lines of early tests (58%) went verbatim to
  `scripts/archive/producer-early-tests-2026-09-17/`**, with a README table saying what each block
  was and why it counts as dead.
- The REFramework menu is trimmed to match. It keeps status, SC, rig status, D, E, P10, P9, R, the
  offset/rotation sliders, STEER, Tear down rig, CLEANUP and Restore glass.
- The harness `fn` table (36 keys), the pane file and callback order are unchanged:
  `scripts/tests/producer_split_check.lua` 48/48 `[measured 2026-09-17]`.
- A new `scripts/tests/producer_globals_check.py` fails if any module name would fall back to a global.
- ⚠️ **The old file sat at exactly 200 top-level locals, Lua's hard limit** (`luac -l -l`)
  `[measured 2026-09-17]`, so the next `local` anyone added would have stopped the script loading.
  The modules have 6–37 each.

**Psychonauts `proxy_d3d9.c` (6,550 lines) → 14 `px_NN_*.c.inc` parts** in the same order, largest
736 lines. The DLL is byte-identical to the pre-split build `[measured 2026-09-17]`. `psychonauts-vr` `da51b90`.

**The install, tidied.** Everything below went to `reframework/_archive-2026-09-17/`, where nothing
is loaded and nothing is deleted:
- about 60 `.pre-*-backup` copies from `autorun/` and `plugins/`;
- three early test scripts that were **running on every launch**: `re8_scope_m3_recon.lua` (retired
  on the board on 2026-08-23, but back in autorun), `re8_scope_recon_probe.lua`, and
  `re8_scope_vrlens_probe.lua` (logged every camera once a second).

`re8_scope_vr_companion.lua` stays: it is behaviour, not a test.

## The proof that the split changed nothing in the game (flat, no headset)

Same route both times: last save, into gameplay, `bringup` through the command file.

1. **Staging HEAD before the split** (`30cdf7f0…` plugin; it carries every 2026-09-16 build):
   - both plugin and scripts loaded, with no Lua errors;
   - `bringup: START` → rig spawned → zero `14.4 / 9.5` → prop pulled in → glass `BOUND` → `bringup: DONE`;
   - re-binds at +5 s and +20 s.
2. **The split build** (`532526d3…`): the same 19 milestone lines, **identical** once addresses and
   positions are stripped. The whole post-`bringup` log contains the same lines, differing only in the
   order periodic lines interleave `[verified-live 2026-09-17, n=1 each, flat]`.
3. The picture on the glass looked the same in both captures.

Logs: `reframework/_archive-2026-09-17/re2_framework_log.{head,split}-bringup-flat.txt` (on `RTX`).

The split branch was then fast-forwarded into `main` in both repos, and **the split build is what is
installed on `RTX` now**, stamped with `deployed.sh` (19 files, including `re8scope/*.lua`).

## Not established

- **Nothing was run in the headset.** The flicker, jitter, hold and swdelay knobs are VR-only, and
  none of them was exercised. `hmd_active=false` throughout.
- Whether REFramework's "Reset Scripts" also clears `package.loaded` `[reported]`. If it does not,
  editing a module needs a game restart to take effect.
- The numbers are still loose: 589 inline numbers in the plugin sources by the new scan's count.
  Naming them is the next stage.

## What it means for the VR queue

**Every 2026-09-16 build is now installed on the home PC.** Until today they existed only on the dev
PC. So the VR rows on the board can run here as written. If anything looks worse than on 2026-09-14,
the old install is in `_archive-2026-09-17/deployed-before-2026-09-17/`, and `pre-split-2026-09-17`
is the source for it.
