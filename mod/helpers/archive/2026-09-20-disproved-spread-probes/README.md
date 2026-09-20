# Disproved spread probes, archived 2026-09-20

Fifteen helper files from one evening's work on the sniper's bullet scatter. Every lever they drive
is disproved and written up in `engine-research/ENGINE-DOSSIER.md` §9bc–§9bh:

| files | what they drove | verdict |
| --- | --- | --- |
| `SPREAD-0` … `SPREAD-3` | the Lua tool's flag watch and `steady` lever | the two "switches" take no arguments and are questions, not setters (§9bc) |
| `SPREAD-4-ZERO-*` | re-pointing the argument slots from Lua | no effect at all — Lua cannot write a value-type argument (§9be) |
| `SPREAD-5` / `SPREAD-6` | skip `setupDiffusion`, zero the spec radius | the spec getters are never called at firing time (§9bg) |
| `SPREAD-8` / `SPREAD-9` | the trace and the self-verifying Lua write | the trace earned its keep; the write could not land |
| `RIFLE-STRAIGHT-A` / `-B` | the native cancel at `setupDiffusion`, both directions | the write lands and the bullet ignores it — wrong step (§9bg) |

⚠️ **They were archived because there were seventeen similarly-named files in the game folder and the
wrong one was easy to click.** That is a tooling fault: a test that is easy to run wrong will be run
wrong. One obvious file per live test is the rule now.

Nothing is lost — they are in git, and the reasoning is in the dossier.
