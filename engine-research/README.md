# RE Village VR Scope — engine research

The distilled technical reference behind the
[RE Village VR scope plugin](../mod/):
how Resident Evil Village's sniper scope actually works inside the RE Engine,
why it breaks in VR, and what REFramework's plugin SDK offers for fixing it —
written so the findings outlive this one project.

## Contents

- [`ENGINE-DOSSIER.md`](ENGINE-DOSSIER.md) — the scope mechanism (GUIScope,
  the main-camera FOV zoom, what does and does not exist to reuse), the
  REFramework native plugin API surface, and the picture-in-picture scope
  design derived from them.
- [`PLAYBOOK.md`](PLAYBOOK.md) — the shared, engine-agnostic flat-to-VR
  reverse-engineering playbook (identical copy across all our
  `-engine-research` repositories).
- `templates/` — starter template for researching another engine the same way.

## The folders for the RE Village VR scope

Everything for this project lives in six folders, each with one job — so
you always know where to look. You are in **`engine-research/`**.

| Folder | What lives here |
| --- | --- |
| [`mod/`](../mod/) | The plugin itself — releases only. |
| [`dev-archive/`](../dev-archive/) | Full development history — snapshots, probes, dead ends, raw recon. |
| [`modding-notes/`](../modding-notes/) | Readable field notes / progress ledger. |
| [staging/re-village-scope-vr](https://github.com/TefMeister/staging/tree/main/re-village-scope-vr) 🔒 | **Private** — unverified WIP builds, cross-machine handoff. |
| **`engine-research/`** ← you are here | Distilled engine reference (dossier) + reusable VR RE playbook. |
| [`external-research/`](../external-research/) | Ongoing public-research leads, gathered separately from hands-on modding work. |

## Credits

See [`CREDITS.md`](CREDITS.md).

## Contributing & policy

See [CONTRIBUTING.md](CONTRIBUTING.md) — how we credit and link sources, our
**study-everything-public but write-our-own-code** rule, the terms for reusing
our work (free, with credit), and how to request a correction or removal.
