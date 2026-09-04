# This project records no REFramework revision anywhere — and on this framework that makes every Lua result a statement about two programs

Filed by: `/gr` (estate sweep, second pass 2026-09-04), for the modding lane.
Sibling topic: `visceral-re2-vr/external-research/topics/2026-09-04-the-revision-question-is-settled-and-the-september-lua-fixes-miss-the-shipped-mod.md`

## The gap

`ENGINE-DOSSIER.md` and `claude-memory/status/re-village-scope-vr.md` contain **no REFramework
revision, build date, or branch** `[verified-live 2026-09-04, n=1 grep]`. Every Lua and plugin
result this project has recorded is dated, but the framework underneath them is not.

The sibling RE Engine project does record it, and that record has already paid for itself once.

## Why it matters specifically here, not as general tidiness

REFramework's newest tagged release is **v1.5.9.1 (2025-03-05)** while `master` is committed to
almost daily, so two machines both running "REFramework" can be eighteen months apart
`[reported 2026-09-04, from /sr]`. Two concrete consequences this family has already produced:

- **A documented API contract silently stopped holding for nine days.** Returning `false` from
  `re.on_pre_gui_draw_element` — the documented way to stop a HUD element drawing — was broken by
  PR #1503 (2026-08-19) and repaired by PR #1809 (2026-08-28). A build from that window runs a
  suppression script with no error and draws the element anyway. `visceral-re2-vr` was able to
  clear itself in minutes because it had a revision to date-check; without one, the only route is
  to doubt your own Lua first.
- **September 2026 brought a run of Lua data-model fixes on `master`** — array element setting,
  array element type confusion, string/number ambiguity — in no release. Whether a given build has
  them is decided entirely by its date.

## The ask, and it needs no launch

Record the revision this project actually runs, in `ENGINE-DOSSIER.md`, beside the existing plugin
notes: the **build date and branch** at minimum, and the commit hash if the log or the DLL gives it.
REFramework prints its branch and version to its log at startup, so the answer is likely already
sitting in a log file on disk from an earlier session — no game launch required to read it.

Then adopt the habit the sibling project uses, which `/sr` proposed and the sibling topic adopts:
**record the exact REFramework revision beside every Lua finding**, the way a game patch version is
recorded. The estate's confidence tags already carry a date, so the cost is one clause.

## One thing worth knowing before any upgrade is considered

This is a **different framework build** from the sibling's. `visceral-re2-vr` is deliberately pinned
to a `pd-upscaler` fork build (2026-03-11) because mainline REFramework has never contained the
temporal upscaler that provides DLSS, and that fork still publishes no releases
`[verified-live 2026-09-04, n=1 API read]`. **That pin is specific to that project's DLSS
requirement and should not be copied here without checking whether this project needs it** — if this
project does not, mainline is the simpler place to be, and a build dated 2026-08-28 or later avoids
the GUI-callback regression entirely.
