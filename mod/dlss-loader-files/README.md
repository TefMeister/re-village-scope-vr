# The DLSS loader files download (release asset, not in this repo)

`REFramework-DLSS-loader-76298bd-files.zip` on the v1.0.1 release page holds the five files of praydog's REFramework
DLSS ("pd-upscaler") build 76298bd (11 March 2026) that differ from his downloadable release v1.5.9.1: `dinput8.dll`,
`reframework/autorun/re2_sharpness_removal.lua`, `reframework/autorun/re8_vr.lua`, `reframework/autorun/utility/RE7.lua`
and `reframework/autorun/utility/RE8.lua`, plus his MIT licence and a read-me-first. They are his files, unmodified
(`MANIFEST.sha256` here lists them). They are offered only because GitHub no longer has that build for download, and
because the September 2026 build (a24c3459) can crash the game at VR start-up (see
`modding-notes/2026-10-01-the-startup-crash-is-the-loader-build.md`). Tefa's rule, 2026-10-01: players still fetch
REFramework from praydog first; we supply only the files that must differ. The binaries are not committed here.
