# /gr hand-off: the runtime-mesh dead end has a public answer — prefab instantiation

**Dead end targeted:** the 2026-08-28 finding (modding-notes
`2026-08-28-rig-mesh-hunt-and-clean-camera-retest.md`, STATUS §7) that a runtime-created
`via.render.Mesh` will not draw in RE8 through any recipe up to and including EMV's
constructor calls — which blocks Mirror pane control, the project's named linchpin.

**The answer:** don't assemble GameObjects from components — instantiate a `.pfb` prefab.
`via.Prefab` instance → `set_Path` → verify `get_Exist` → `instantiate(via.vec3, via.Folder)`.
The engine spawns the complete object through its own registration path, born visible.
EMV Engine does this in RE8 (README: "In all games, PFB files (prefabs) can also be
spawned"), and its README explicitly warns that component-list assembly "will not work well
for complicated GameObjects… use via.Prefabs for those" — public confirmation of the wall.

**RE8-specific ammunition:** `environment/props/prefab/item/detailsearch/ri3042_detailsearch.pfb`
(a spawnable standalone copy of the F2 rifle), and `movie/prefab/c22e500_00_mirror.pfb`
(a Capcom-assembled cutscene mirror worth dumping live for the reference recipe).

**Full write-up:** `re-village-scope-vr-external-research/topics/2026-08-29-runtime-mesh-spawning-via-prefab-instantiate.md`

**Suggested dossier change:** add to the scene/spawning section (or create one): runtime
GameObject assembly from components does not produce drawable meshes in RE8; the working
route is `via.Prefab.instantiate(via.vec3, via.Folder)` on a shipped `.pfb`, per EMV Engine
precedent — with the M18–M26 session as the in-house negative record.
