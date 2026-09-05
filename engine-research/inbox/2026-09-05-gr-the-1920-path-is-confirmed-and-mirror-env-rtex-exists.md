Supersedes: `re-village-scope-vr/external-research/topics/2026-08-29-runtime-mesh-spawning-via-prefab-instantiate.md`, the "~30 entries" figure for RE8's shippable `.rtex` inventory (quoted in the board's `[FLAT]` resolution-lever-2 row)

# The guessed 1920 `.rtex` path is real, 1920 is the LAST rung — and the game ships a `mirror_env` render target

**Filed by `/gr`, 2026-09-05 (estate sweep). For the modding lane.** No launch, no game files read —
this is Ekey's public path listing. Full write-up:
`external-research/topics/2026-09-05-the-1920-rtex-path-is-confirmed-and-the-shipped-inventory-holds-a-mirror-env-target.md`.

## 1. ✅ The `[FLAT]` resolution-lever-2 guess is correct

The row says *"Only the SIZE is on record, not the path string […] the Lua tries
`movie/rtex/movie_1920_1080.rtex` and falls back to the known-good 1280 path."*

It exists, exactly as guessed: **`natives/stm/movie/rtex/movie_1920_1080.rtex.5`**
`[verified-live 2026-09-05, n=1 file read of `RE8_STM_Release.list`]`. Stripping `natives/stm/` is
the same convention the working 1280 request already uses, and the trailing `.5` is the resource
version suffix, not part of the name.

**Nothing to change in the build — but it sharpens the log line you are about to read.** If
`mirror RT: using …` still reports the 1280 fallback, the file is not missing, so the cause is the
**request or the latch**. Different bug, different fix, and now separable for free.

## 2. ✏️ Correction: "~30 entries" is wrong, and 1920 is the ceiling

Our 2026-08-29 note (quoted in the row) records *"~30 entries incl. 1920×1080"*. Actual shape:

- **56** `.rtex` entries in total,
- but only **5** are generic size-named `movie/rtex` targets: 650×850, 1144×1048, 1170×784,
  1280×720, 1920×1080. The other 51 are purpose-built (`recordsys_rtt` per character/enemy,
  `bloodflow_*`, `mercenaries/*`, `enemyrendertargetlist/*`, `ui2110_rtt`, `materialpainteditrtt`,
  six cube faces under `systems/rendering/`).
- **There is no 2048, 2560 or 4096 `.rtex` anywhere in the game** `[verified-live 2026-09-05]`.

So **lever 2 is the last rung on this ladder.** Worth knowing before planning a further resolution
step: after 1920 there is no bigger shipped asset to borrow, and the next increment would have to
come from *creating* a target — which is the `⛔ RT GPU BACKING` problem again.

**If 1920 lands but still looks mushy, try `movie/rtex/movie_1144_1048.rtex` before concluding
anything.** The patch is a circle; a 16:9 target spends most of its pixels outside it. 1144×1048
gives ~1048 px of inscribed circle against 1920×1080's ~1080 — near-identical detail from **half**
the pixels. `[inferred-static 2026-09-05]`, a geometric argument, and it assumes the latch's padded
window tolerates a near-square source (the row says "either width").

## 3. 🔭 The one worth your attention: `mirror_env.rtex`

**`natives/stm/mastermaterial/textures/rendertarget/mirror_env.rtex.5`**

The reopened `via.render.Mirror` candidate is the board's preferred lead, and its weak point is
stated in the board itself: all three pieces are individually proven, the combination never run, and
the 2026-08-24 attempt died on *"binding our created RT to the glass succeeds but shows nothing —
backing needs pipeline registration not yet found."*

This is a **shipped, engine-owned render target explicitly named for mirror rendering**. If it is
what the name says, it answers the first half of the Mirror question — what Mirror renders into, and
whether that resource is genuinely backed — with an asset the engine already registers, rather than
one we create and must then prove. **That is the same trick that already works for the movie
targets**, pointed at the lead that most needs it.

`[hypothesis]` and deliberately so: the name may denote a static environment texture rather than a
live Mirror output, and the six `systems/rendering/{xn,xp,yn,yp,zn,zp}.rtex` cube faces in the same
inventory are a reminder this engine does static environment capture too. **One reflection read of
its type, dimensions and flags settles which** — the same F6-style check that proved the 728×1280
`R8G8B8A8_UNORM_SRGB` / `RENDER_TARGET` backing on 2026-08-24.

## Suggested dossier change

Where the dossier records the `.rtex` inventory or the resolution levers, replace "~30 entries" with
the five-entry `movie/rtex` list plus the 56 total, note that **1920×1080 is the maximum shipped**,
and add `mastermaterial/textures/rendertarget/mirror_env.rtex` to the `via.render.Mirror` candidate's
notes as the first thing to reflect when that retest happens.

Credit: **Ekey**, REE.PAK.Tool — already in this project's `CREDITS.md`. Path strings only; no game
content was read, downloaded or redistributed.
