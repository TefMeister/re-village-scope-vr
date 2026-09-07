# Credits & Attribution

This project is a reverse-engineering and modding effort built on the public
research, tools, and documentation of many people who came before us. None of
this would be possible without their work. We list every source we've drawn
on below — including work that helped only as inspiration — by name or
handle, as accurately as we could verify it.

## The game itself

This mod modifies, at runtime, **Resident Evil Village** by **Capcom**
(https://www.capcom.com), via praydog's REFramework. The game, its engine,
and all of its assets are Capcom's, and the game is the entire reason this
project exists. **No game files, code, or assets are distributed in any of
this project's repositories** — only code, notes, and tools we wrote
ourselves, plus third-party components whose licenses permit redistribution
(noted below).

## Prior art, tools, and research this repo draws on

| Source / Work | Creator(s) | Link |
|---|---|---|
| REFramework (mod framework, native VR support for RE Village, plugin SDK) | praydog | https://github.com/praydog/REFramework |
| REFramework Book (Lua API documentation) | cursey | https://cursey.github.io/reframework-book/ |
| The REFramework VR community (scopes-don't-render-in-VR limitation, VR rendering techniques) | various, credited individually as sourced | — |
| REFramework GitHub issue trackers (RE resource-lifetime bug research) | praydog and the issue reporter | https://github.com/praydog/REFramework/issues |
| Otis_Inf (Frans Bouma) — RE Engine photomode tools (checked as prior art) | Frans Bouma | https://opm.fransbouma.com |
| EMV Engine (the prefab-instantiate spawning mechanism, studied online; RE8 support and component-spawning caveats from its README) | alphazolam | https://github.com/alphazolam/EMV-Engine |
| REE.PAK.Tool (`RE8_STM_Release.list` — the RE8 file inventory used to enumerate `.pfb` prefabs and `.rtex` render-target descriptors) | Ekey | https://github.com/Ekey/REE.PAK.Tool |
| "HDR Theory and Practice" (CEDEC 2017) — the GT three-section tone curve whose structure the engine's tonemap parameters resemble | Hajime Uchimura | https://www.slideshare.net/nikuque/hdr-theory-and-practicce-jp |
| tonemapper — an open catalogue of tone-mapping operators, used to compare curve shapes; nothing taken | Tizian Zeltner | https://github.com/tizian/tonemapper |
| REFramework's **source** specifically — `shared/sdk/Renderer.hpp`/`.cpp` (`is_fully_rendered`, `find_fully_rendered_scene_layers`), `src/mods/VR.cpp` on `master` and `pd-upscaler` (the projection override applying to every camera while the view override does not; the right-eye chain erase list), `src/mods/Hooks.cpp`, `src/mods/vr/CameraDuplicator.cpp`, `reversing/re8.genny`, and the RE9 regenny `Scene.hpp` (2026-09-07) | praydog | https://github.com/praydog/REFramework |
| Commit `20a3ec5442` — **"VR (RE4): Fix scope not being zoomed in"**, the prior art for exempting a scope camera from the VR projection override; and `50f46296` — "Graphics (RE4): Add Scope Tweaks" (2026-09-07) | praydog | https://github.com/praydog/REFramework/commit/20a3ec5442 |
| REFramework issue #698 — "The way scopes work is they create a separate scene, yes" (2026-09-07) | praydog, and reporter TommyCreo21 | https://github.com/praydog/REFramework/issues/698 |
| REFramework issues #1243, #439, #509, #1615 — the threads establishing scope / secondary-render behaviour | Unit-45, MelonBoyy, MrOmbre, Hypnosphi | https://github.com/praydog/REFramework/issues |
| RE-Engine-Lib (`RTexFile.cs` — the public `.rtex` descriptor layout, which names `widthRate`/`heightRate` and confirms `0x0C` is a raw DXGI enum) and REE-Lib-Resources (`rsz_patch.json`, `il2cpp_cache.json`, `file_extensions.json`); also RszTool, REasy, ReachForGodot (2026-09-07) | kagenocookie | https://github.com/kagenocookie |
| RE_RSZ — the RE8 RSZ template carrying every serialized field name, incl. `via.render.Mirror`'s two fields and **`app.VrWeaponSniperScopeLensUpdater`** (Capcom's own VR sniper-scope component) (2026-09-07) | alphaZomega (alphazolam) | https://github.com/alphazolam/RE_RSZ |
| REFramework Object Explorer documentation — the "Dump SDK" route to a full `il2cpp_dump.json` (2026-09-07) | cursey | https://cursey.github.io/reframework-book/object_explorer/object_explorer.html |
| MHWildsHighQualityPhoto — a worked native-plugin example of swapping `via.render.RenderTargetTextureResource` inside a `RenderTargetTextureResourceHolder` to redirect a capture to a different-resolution `.rtex` (2026-09-07) | hcdd0304 | https://github.com/hcdd0304/MHWildsHighQualityPhoto |

Development on this project is AI-assisted: much of the research, code, and
documentation was produced with **Claude (Anthropic)** (https://claude.com)
working alongside the project owner.

## Missing from this list?

If you — or someone whose work you know — contributed to, influenced, or
even just inspired anything used in this project and you aren't credited
here, please **open a GitHub issue on this repo** and we'll correct it as
soon as possible. We would much rather over-credit than leave anyone out.

## Respecting creators

This project exists because other people generously shared their
reverse-engineering research, tools, and modding know-how in public — we've
tried to credit every one of them by name or handle above, as accurately as
we could verify. If you are the creator or rightful owner of anything
credited or used here and you'd rather your work not be referenced in this
repo, or you want specific content removed or no longer used by the mod,
please tell us: **open a GitHub issue on this repo**. We'll act on that
request promptly — no argument, no delay — and we'll find another way to get
the job done that doesn't rely on your material. This is your work; we're
just grateful to have learned from it.
