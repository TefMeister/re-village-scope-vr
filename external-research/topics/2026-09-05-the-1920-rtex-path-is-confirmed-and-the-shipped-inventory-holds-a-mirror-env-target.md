# The guessed 1920×1080 `.rtex` path is real — and the shipped inventory holds a `mirror_env` render target

**Status:** 🆕 new · **Priority:** high — it turns a live `[FLAT]` row's fallback guess into a
confirmed path at zero cost, corrects one number in our own notes, and puts a concrete asset in
front of the reopened `via.render.Mirror` candidate.

## Why this was looked up

The board's `[FLAT, free]` **resolution lever 2** row ships a guess and says so honestly:

> "Only the SIZE is on record, not the path string, so nothing was flipped blind: the Lua tries
> `movie/rtex/movie_1920_1080.rtex` and **falls back** to the known-good 1280 path."

The size came from our own 2026-08-29 read of Ekey's public RE8 file inventory. The path string was
never checked against that same list — which is a one-command read. So: is the guess right?

## ✅ It is right, exactly as written

Read from `Ekey/REE.PAK.Tool`, `Projects/RE8_STM_Release.list`, 113,918 entries
`[verified-live 2026-09-05, n=1 file read]`. The complete `movie/rtex` inventory is **five** entries:

| path (as listed) | pixels | aspect |
| --- | --- | --- |
| `natives/stm/movie/rtex/movie_650_850.rtex.5` | 650×850 | 0.76 (portrait) |
| `natives/stm/movie/rtex/movie_1144_1048.rtex.5` | 1144×1048 | **1.09 (near-square)** |
| `natives/stm/movie/rtex/movie_1170_784.rtex.5` | 1170×784 | 1.49 |
| `natives/stm/movie/rtex/movie_1280_720.rtex.5` | 1280×720 | 1.78 — **the known-good one in use** |
| **`natives/stm/movie/rtex/movie_1920_1080.rtex.5`** | **1920×1080** | **1.78 — the target** |

The deployed request string `movie/rtex/movie_1920_1080.rtex` matches the listed path with the
`natives/stm/` prefix stripped, which is the convention the working 1280 request already follows.
**So the fallback should not fire for the reason "that file does not exist"** — and that makes the
log line the row asks for sharper than it was: if `mirror RT: using …` still reports the 1280
fallback, the cause is the *request or the latch*, not a missing asset. That is a different bug with
a different fix, and it is now separable at no cost.

⚠️ One detail worth carrying: every entry ends **`.5`** — the RE Engine resource-version suffix, not
part of the name. Requests elsewhere in this project omit it, and the working 1280 path is listed the
same way, so no change is implied. It is only a trap if a request is ever built by copying a line out
of this list verbatim.

## ✏️ A correction to our own note

The 2026-08-29 note (quoted in the board row) records the inventory as *"~30 entries incl.
1920×1080"* `[reported 2026-08-29]`. Re-read today, the true shape is different in a way that
matters:

- **56** `.rtex` entries in total, not ~30.
- But only **5** of those are the generic, size-named `movie/rtex` targets above. The other 51 are
  **purpose-built** — `recordsys_rtt` per character and per enemy, `bloodflow_lhand/rhand`,
  `mercenaries/rtt_mercehourglass_*`, `enemyrendertargetlist/…`, a `ui2110_rtt`, a
  `materialpainteditrtt`, and six cube faces (`systems/rendering/{xn,xp,yn,yp,zn,zp}.rtex.5`).

So the practical inventory for "grab a bigger blank render target" is **five, not thirty**, and
1920×1080 is the largest that exists — there is no 2048, 2560 or 4096 anywhere in the game
`[verified-live 2026-09-05]`. **Lever 2 is therefore the last rung on this ladder**, which is worth
knowing before anyone plans a further resolution step: after 1920 there is no bigger shipped asset to
borrow, and the next increment would have to come from creating a target rather than borrowing one.

**If 1920 disappoints, the interesting fallback is not 1280 but `movie_1144_1048`.** The scope patch
is a *circle*, and a 16:9 target spends most of its pixels outside it. At 1144×1048 the usable
inscribed circle is ~1048 px across versus ~1080 for the 1920 target — nearly identical detail from
**half** the pixels. `[inferred-static 2026-09-05]` — a geometric argument, not a measurement, and it
assumes the latch's padded-height window tolerates a near-square source, which the row says it does
for "either width". Cheap to try in the same launch.

## 🔭 The unexpected one: `mirror_env.rtex` exists

`natives/stm/mastermaterial/textures/rendertarget/mirror_env.rtex.5`

The board's **reopened `via.render.Mirror` candidate** — *"Mirror as producer (`registerScene`) + the
natively-hooked confirmed-backed resource + `setMaterialTexture` on the glass as the display"* — is
currently the preferred lead over hunting the OpenXR swapchain, and its weak point is that all three
pieces are proven individually but never combined. This asset says the game **ships a render target
under `mastermaterial` explicitly named for mirror environment**, which is what `via.render.Mirror`
would render into in normal use `[inferred-static 2026-09-05]` — the name is strong evidence of
purpose, and nothing more than that until something reads it.

Why it is worth a line in the plan rather than a shrug: the Mirror candidate has to answer "what does
Mirror render into, and is that resource really backed?" This is a shipped, already-registered
answer to the first half — a target the engine itself pairs with mirror rendering, rather than one we
create and then have to prove has GPU backing (the exact problem that killed the 2026-08-24 attempt
and produced the `⛔ OPEN PROBLEM = RT GPU BACKING` row). **Borrowing an engine-owned mirror target is
the same trick that already works for the movie targets**, applied to the one lead that most needs it.

`[hypothesis]` throughout — the name may denote a static cubemap-style environment texture rather
than a live `via.render.Mirror` output, and the six `systems/rendering/{xn,xp,…}` cube faces in the
same inventory are a reminder that this engine does have static environment capture. One reflection
read of that resource's type and dimensions settles which it is.

## Concrete next steps

1. Nothing to change in the deployed build — **the guess was right.** Read `mirror RT: using …` as
   the row already says, but now read a 1280 fallback as *"the request or the latch failed"*, not
   *"the file is missing"*.
2. If 1920 lands but still looks mushy, try **`movie/rtex/movie_1144_1048.rtex`** in the same run —
   near-square, better suited to a circular patch than 16:9.
3. When the `via.render.Mirror` retest happens, reflect
   **`mastermaterial/textures/rendertarget/mirror_env.rtex`** first — type, dimensions, and whether
   it carries the `RENDER_TARGET` flag the F6 probe looked for on 2026-08-24. One read, no launch
   cost beyond a session already planned.

## Sources

- https://github.com/Ekey/REE.PAK.Tool — `Projects/RE8_STM_Release.list`, the public RE8 file
  inventory (path strings only; no game content read, downloaded or redistributed). Read
  2026-09-05. Credit: **Ekey**, already in this project's `CREDITS.md`.
- This project's own `topics/2026-08-29-runtime-mesh-spawning-via-prefab-instantiate.md` (the
  2026-08-29 read of the same list, whose "~30 entries" figure this corrects) and the board's
  `[FLAT]` resolution-lever-2 and `via.render.Mirror` rows in `claude-memory/status/re-village-scope-vr.md`.
