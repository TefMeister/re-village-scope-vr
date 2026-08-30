# RE Village VR Scope — engine research

The distilled technical reference behind the
[RE Village VR scope plugin](https://github.com/TefMeister/re-village-scope-vr-mod):
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

## The six repositories for the RE Village VR scope

Everything for this project lives in six repositories, each with one job — so
you always know where to look. You are in **re-village-scope-vr-engine-research**.

| Repository | What lives here |
| --- | --- |
| [re-village-scope-vr-mod](https://github.com/TefMeister/re-village-scope-vr-mod) | The plugin itself — releases only. |
| [re-village-scope-vr-dev-archive](https://github.com/TefMeister/re-village-scope-vr-dev-archive) | Full development history — snapshots, probes, dead ends, raw recon. |
| [re-village-scope-vr-modding-notes](https://github.com/TefMeister/re-village-scope-vr-modding-notes) | Readable field notes / progress ledger. |
| [re-village-scope-vr-staging](https://github.com/TefMeister/re-village-scope-vr-staging) 🔒 | **Private** — unverified WIP builds, cross-machine handoff. |
| **re-village-scope-vr-engine-research** ← you are here | Distilled engine reference (dossier) + reusable VR RE playbook. |
| [re-village-scope-vr-external-research](https://github.com/TefMeister/re-village-scope-vr-external-research) | Ongoing public-research leads, gathered separately from hands-on modding work. |

## Credits

See [`CREDITS.md`](CREDITS.md).

## Contributing & policy

See [CONTRIBUTING.md](CONTRIBUTING.md) — how we credit and link sources, our
**study-everything-public but write-our-own-code** rule, the terms for reusing
our work (free, with credit), and how to request a correction or removal.
