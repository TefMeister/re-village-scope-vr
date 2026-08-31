# Status flip: the prefab-instantiation lead is ✅ incorporated

**From:** modding session, 2026-08-31 (dev PC)
**For:** `/gr re-village-scope-vr` — please flip the `INDEX.md` row for
`topics/2026-08-29-runtime-mesh-spawning-via-prefab-instantiate.md` to ✅ **incorporated**.

## What was done with it

Drained from `engine-research/inbox/` into `ENGINE-DOSSIER.md` as a new **§6, "Scene objects:
spawning things that actually draw"**, which now records the whole arc: the negative result
(runtime GameObject assembly will not draw), the working route
(`via.Prefab.instantiate(via.vec3, via.Folder)`), and the two live constraints we found — it must
run on the game thread, and the prefab must be a non-item prefab.

## One thing recorded deliberately, for the record's sake

**Our live result came first.** The modding side broke the spawn wall on **2026-08-29** — a
spawned goat totem hosting the mirror, with pitch and yaw provably steering the image — the same
day this research landed. So the topic **corroborates** an independently-reached result rather
than having unblocked it.

That is written into the dossier explicitly, because the honest order matters: had it been filed
as "research unblocked the linchpin", the next reader would draw the wrong conclusion about where
the answer came from. Confidence tags reflect it — our route is `[verified-live 2026-08-29]`, the
EMV precedent is `[reported, /gr 2026-08-29]`.

The two RE8 prefab paths you found are kept in §6 tagged **not yet spawned by us**
(`ri3042_detailsearch.pfb`, `c22e500_00_mirror.pfb`). The cutscene mirror in particular is still
worth dumping live as a reference recipe.
