# 2026-09-05k — The fix was a regression, and the record already said so (`/lm`, home PC, one flat launch)

**Lane:** `/lm village scope`, home PC, 21:23–21:29 in-game. Tefa launched and reached a level;
everything after that was driven from outside. **Closed gracefully through `WM_CLOSE`** once no
further rebuild could produce a picture in that process.

Evidence: `dev-archive/recon/2026-09-05k-latch-control/` — six cycle captures, two triptychs, the
full log, and `dev-archive/tools/re8latchcontrol.py`. Source `staging` (this commit). Plugin
**rebuilt and deployed** (`.pre-rearm-pending-backup-2026-09-05k`), clean, **150,528 B**,
hash-verified. **Unrun.**

## The headline, stated against myself

**The latch "fix" I built and deployed at 21:13 (`7e47abb`) was a regression, and the record on
disk already showed it.** The 2026-08-31 design latches the 8-bit `fmt=29` resolve first and then
**upgrades** to the `fmt=26` raw-HDR scene buffer when the engine allocates it next; the GT grading
(§7) tonemaps *that* HDR source, and the upgrade line is present in launch 1 tonight and in the
headset run where the shots landed (`2026-09-05-vr-model-test/launch2`) `[verified-live, n=3 logs]`.
Putting the format test inside `looks_like_mirror_target` refused the upgrade branch as well, so
launch 2 ran entirely on the SRGB resolve — the 08-31 note's "exposure-immune golden veil" — and its
one "good" picture (cycle 1, mean 115) was a whitened yellow wash, not the world.

**What was actually wrong** is narrower: `fmt=26` must never be the **first** source. As a first
source (after a re-arm with nothing latched) it is a random 1920×1088 HDR intermediate and shows
black `[verified-live 2026-09-05, n=2, launch 1]`; as an *upgrade* after the `fmt=29` latch it is
the mirror's own scene buffer, identified by allocation order, and it is the picture that works.

## The corrected change

- `looks_like_mirror_target` is geometric again (dimension, width, height window, RT flag).
- "May this be a **first** source" is decided in the hook: `fmt=29` and no `ALLOW_UNORDERED_ACCESS`.
  Every movie `.rtex` the engine has handed this project is exactly that — 1280×728 on 2026-08-24
  and six latches tonight `[verified-live, n=7]`. The `fmt=26` **upgrade** branch is untouched and
  reachable again.
- **Numpad `.` no longer retires the current source.** It marks a replacement *pending*; the next
  acceptable allocation swaps in; until then the scope keeps what it has. The HDR early-return
  yields to a pending re-arm, or a replacement could never be seen while HDR is latched.

## Why re-arm had to change: allocation is not under the cold order's control

Six rebuild cycles in one process, same pose, log-verified:

| cycle | target | `mirror RT: using` (create ran) | allocation seen by the hook | picture |
| --- | --- | --- | --- | --- |
| 1 | 1920 | yes | 1920×1088 `fmt=29/0x1` latched | whitened wash (SRGB path) — 115 |
| 2 | 1920 | **no** (holder reused) | none | no-source cream — 218 |
| 3 | 1920 | **no** | none | no-source cream — 218 |
| — | probe | control path `movie_1280_720` | 1280×728 `fmt=29/0x1` latched (**the probe's**) | — |
| 4 | 1280 | yes | 1280×728 `fmt=29/0x1` latched (second one) | dark render — 24 |
| 5 | 1920 | yes | **none** (cached) | no-source cream — 217 |
| 6 | 1280 | yes | **none** (cached) | no-source cream — 216 |

`[verified-live 2026-09-05, n=6 cycles]`. `create_resource` allocated 1280 **twice** in one process
and 1920 **once**; whether a given call allocates is not predictable from the path. "Retire and
wait" therefore went blank on every cycle that did not allocate — three of six — where the old
predicate had instead grabbed the next 1920-wide thing. The corrected predicate took **nothing**
on those three (the loud miss, as designed) and the right target on all three genuine allocations.
**Zero wrong grabs in six cycles.**

## Two things learned in passing

- **The boot latch is not ours.** In every launch the first `MIRROR SOURCE latched` line fires
  before any rig exists — `1920×1080 fmt=28 flags=0x1` (`R8G8B8A8_UNORM`, exact 1080, not the
  padded 1088) in launches with the old DLL, `1920×1080 fmt=29` under the gated one
  `[verified-live, n=3 launches]`. The cold order's re-arm was silently doing a second job:
  displacing that boot latch. Pending-replace keeps doing it.
- **The reticle square is a source tell:** green while a mirror source is latched, **blue** when
  none is `[verified-live 2026-09-05, n=3 no-source cycles]`. Readable in any flat capture.

## `mirror_env.rtex` — a second honest refusal

`fn probe_rtex` resolved **all nine** paths — `mirror_env`, the six `systems/rendering` cube faces,
both movie targets — and `res:get_type_definition()` returned **nil for every one**
`[verified-live, n=1]`. Yesterday's failure was the type *name*; today's is the *object*: what
`sdk.create_resource` returns is not a managed object on this build, so **reflection cannot
describe a resource at all** here. Dimensions and format of `mirror_env` need the D3D12 route: when
the lens material samples it, the engine creates an SRV for it, and the plugin already hooks
`CreateShaderResourceView` — logging the `GetDesc()` of the resource behind that SRV is a
`[PD]` change and the honest end of the reflection road.

## Rows touched, honestly

- **Sharpness (1920 vs 1280): still not made.** Cycle 1 was the SRGB path, cycle 4 a dark render;
  no comparable pair exists. Needs a fresh process on the corrected DLL.
- **Snow-as-sky whitening:** launch 1's bright 1280 picture (21:09) *was* on the HDR path (an
  upgrade line follows its latch), so that observation stands as the row's shape; tonight's washed
  cycle 1 was the SRGB path and is **not** evidence for it. Ladder is numpad **9** in mirror mode
  (cycles OFF then rungs) — drivable from the harness next time.
- `EyeDistortionRange` 0.100 again — `[verified-live, n=4 launches]`.

## Automation (§5a)

Menu→gameplay not exercised (Tefa loaded the level). Commands proven; camera not exercised;
self-close proven (n=4). `re8latchcontrol.py` runs the whole control unattended and prints the
table above.

## What is NOT established

- That pending-replace works. Its control: two rebuilds on **different** targets in a fresh
  process must both show a picture, the second logging `REPLACED on pending re-arm`, and a rebuild
  that does not allocate must **keep** the previous picture instead of going cream.
- That the HDR upgrade still fires with the first-source gate in place — it should, the branch is
  unchanged, but "should" is `[hypothesis]` until a log shows the line.
