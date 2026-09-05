# 2026-09-05j — One flat launch: the latch was matching on width alone (`/lm`, home PC)

**Lane:** `/lm re village scope`, home PC, 20:57–21:13 in-game (log timestamps), Tefa at work.
**Launch:** ONE, flat, started from the command line and driven cold to gameplay with nobody at the
keyboard. **Closed gracefully through `WM_CLOSE`** because the flat lane became blocked behind a
plugin fix — a game that cannot answer anything is a signal spent for nothing.

Evidence: `dev-archive/recon/2026-09-05i-probe-run/` — 18 captures, the side-by-side and triptych,
and the full framework log. Source `staging` `7e47abb`. Plugin **rebuilt and deployed**
(`re_scope_vr.dll.pre-latch-format-backup-2026-09-05i`), clean build, zero warnings,
**149,504 B**, hash-verified. Producer redeployed (probe fix), hash-verified.

## The headline: the mirror-source latch grabs the wrong allocation, reproducibly

The RT switch built earlier this evening (`fn rtex_1920` / `fn rtex_1280`) was run for the first
time. Four rig rebuilds in one session, same pose throughout, and here is what the plugin's own
latch line said each time:

| rebuild | target requested | latched | picture (mean / stddev, centre 700×700) |
| --- | --- | --- | --- |
| 1 | 1920 | **1920×1088 fmt=29 flags=0x1** | world, detailed — 81.7 / 40.8 |
| 2 | 1280 | **1280×728 fmt=29 flags=0x1** | world, much brighter — 102.9 / 50.5 |
| 3 | 1920 | **1920×1088 fmt=26 flags=0x5** | black — 17.5 / 11.8 |
| 4 | 1920 (retry) | **1920×1088 fmt=26 flags=0x5** | black — 17.6 / 12.1 |

`[verified-live 2026-09-05, n=4 rebuilds]`. fmt=26 is `R11G11B10_FLOAT`; flags=0x5 is
`ALLOW_RENDER_TARGET | ALLOW_UNORDERED_ACCESS`. That is one of the engine's own HDR intermediates,
not our movie `.rtex`. `looks_like_mirror_target` checked dimension, width, a height window and
`ALLOW_RENDER_TARGET` — and **both allocations satisfy all of that.** Once the engine had one of
those in flight the latch took it every time; the retry ruled out a race.

**The fix is a measured discriminator, not a guess.** Every movie `.rtex` the engine has ever handed
this project has been **fmt=29 (`R8G8B8A8_UNORM_SRGB`) with flags=0x1 exactly** — 1280×728 on
2026-08-24, and today 1280×728 once and 1920×1088 once, both fmt=29/0x1. The predicate now requires
that format and refuses `ALLOW_UNORDERED_ACCESS`. Designed to fail loudly: a movie target in some
other format produces **no latch line at all**, never a black scope. `[compile-verified 2026-09-05]`,
**unrun**.

**Why this matters beyond tonight:** it explains a class of "the scope went black after a rebuild"
that would otherwise have been blamed on the rig, the Lua, or the order of the cold sequence.

## The sharpness comparison was NOT made

That was the row the switch was built for, and it is still open. Captures 1 and 2 latched the right
targets but are **not comparable**: rebuild 2 came back substantially brighter, with the upper
two-thirds of the picture near white. That is the shape of the **snow-as-sky whitening** row, but it
was not tested against the ladder, so it stays `[hypothesis]`. Captures 3 and 4 are black. **No claim
about 1920 vs 1280 detail.** With the latch fixed, the comparison is one launch and two commands.

## `mirror_env.rtex` — half an answer, honestly bounded

- **It resolves.** `sdk.create_resource("via.render.RenderTargetTextureResource", …/mirror_env.rtex)`
  succeeds and `fn sc_next` bound it to **2 lens slots** `[verified-live 2026-09-05, n=1]`.
- **On the lens it shows warped environment imagery** — sky above, terrain below, matching the
  current location — and the content changes when the camera turns `[verified-live, n=1]`. ⚠️ That
  is **not** the discriminator it looks like: a *static* cube map sampled as a reflection also
  changes with view direction. Suggestive of an environment map, proves nothing about live-vs-static.
- **Dimensions and format are still unread.** `fn probe_rtex` refused to run, and was right to:
  `sdk.find_type_definition("via.render.RenderTargetTextureResource")` returns **nil** on this
  build even though `create_resource` resolves the identical string `[verified-live, n=1]`. The
  probe's guard called that a FAILURE, not a negative — exactly what it was built to do. It now takes
  the getter list from the **returned object's** type definition. Deployed, **unrun**.

## Automation, scored by name (§5a)

1. **menu→gameplay — PROVEN, cold, n=3.** `steam://rungameid/1196590` → 40 s → INSERT → ENTER →
   F → UP (dialog defaults to **No**) → F → splash → F → gameplay, a capture verified at every step
   before every commit `[verified-live 2026-09-05, n=3 launches]`.
2. **commands — PROVEN.** Command file + numpad by virtual key. `re8drive.py num` now accepts
   `.`/`*`/`+`/`-`/`/` by name; the old "num 14 / num 10" arithmetic still works.
3. **character + camera — PARTIAL.** Camera turn by relative `SendInput` works in flat
   `[verified-live, n=1]`; ADS via the pad hook works; movement not exercised.
4. **self-close — PROVEN**, `WM_CLOSE`, `[verified-live, n=3]`.

**⚠️ New gap, named: the REFramework overlay cannot be CLICKED from outside.** Hover registers —
the button highlights — but neither legacy `mouse_event` nor `SendInput` with
`MOUSEEVENTF_ABSOLUTE` (0.2 s and 0.35 s holds) ever fired "Reset scripts"
`[disproved 2026-09-05, n=3 attempts]`. Consequence: **a producer edit costs a relaunch**, and
tonight it did. A harness `reload` command was considered and **rejected**: re-executing the
producer file re-registers every `re.on_frame` callback, so two instances would drive the rig.
Recorded rather than built. Tools kept in `dev-archive/tools/re8click.py` (SendInput) and
`re8click-legacy-mouse_event.py` so the next attempt starts from the dead end, not before it.

## Also confirmed in passing

- The plugin's automatic eye-box ladder + hold ran again on the fresh launch: `EyeDistortionRange`
  reads back **0.100** on both lens materials, every write, every hold — now
  `[verified-live 2026-09-05, n=3 launches]`.
- The 1280×728 latch line tonight independently re-confirms the control descriptor the probe relies
  on (fmt=29, flags=0x1) `[verified-live, n=2 launches]`.

## What is NOT established

- Whether the latch fix works. Its control is written into the OPEN block: three consecutive
  rebuilds, all fmt=29, all with a picture.
- What `mirror_env.rtex` is. Resolved and warped-environment-shaped; dimensions unread.
- Why rebuild 2 was brighter. Whitening is the obvious candidate and is untested.
- 1920 vs 1280 sharpness — unanswered.
