# RE Village VR Scope

A real, usable sniper scope for **Resident Evil Village in VR** (praydog's
[REFramework](https://github.com/praydog/REFramework) native VR) — a native
C++ REFramework plugin that renders a magnified picture-in-picture view onto
the rifle's scope lens, accurate to where the bullet actually goes.

> **Status: early work in progress — nothing playable is released yet.** This
> repository will hold releases only; watch it if you want to know the moment
> there is something to try.

## Why this exists

Scopes are a known unsolved problem across REFramework's VR support: in the
flat game, aiming a sniper simply narrows the main camera's field of view and
draws a scope mask on top. In VR that turns into a huge flat screen with a
crosshair floating in front of your face. There is no separate scope image in
the game to borrow — so a real VR scope has to be built: a second magnified
view rendered to a texture, mapped onto the lens, with the fullscreen zoom
suppressed so the world stays 1:1 in the headset.

This effort started as a thank-you. Our
[Resident Evil 2 VR interaction mod](https://github.com/TefMeister/arcade-controls-re2-vr)
stands on the foundation and hard manual work of **Andyalpa** (creator of
RE2VRMODRELOADED), and a working scope is something his VR work needs. If we
can crack it here, the technique is documented for every RE Engine game.

Everything is **written from scratch** against REFramework's published plugin
SDK headers; praydog's sources are studied and credited as prior art, but no
one else's code is used — every line is our own, by deliberate policy. The
playable plugin is almost the by-product: the real goal is the knowledge
gained on the way, written down so anyone can do the same — see the
[engine dossier](https://github.com/TefMeister/re-village-scope-vr-engine-research)
and the cross-engine
[flat-to-VR library](https://github.com/TefMeister/flat-to-vr-cross-engine-research).

## What you will need

- Your own legitimate copy of **Resident Evil Village** (this mod contains
  **no** game files).
- [REFramework](https://github.com/praydog/REFramework) (the RE8 build).
- A PC VR headset via SteamVR/OpenXR (Quest over Link/Virtual Desktop works).

## The five repositories for the RE Village VR scope

Everything for this project lives in five repositories, each with one job — so
you always know where to look. You are in **re-village-scope-vr-mod**.

| Repository | What lives here |
| --- | --- |
| **re-village-scope-vr-mod** ← you are here | The plugin itself — releases only. |
| [re-village-scope-vr-dev-archive](https://github.com/TefMeister/re-village-scope-vr-dev-archive) | Full development history — snapshots, probes, dead ends, raw recon. |
| [re-village-scope-vr-modding-notes](https://github.com/TefMeister/re-village-scope-vr-modding-notes) | Readable field notes / progress ledger. |
| [re-village-scope-vr-staging](https://github.com/TefMeister/re-village-scope-vr-staging) 🔒 | **Private** — unverified WIP builds, cross-machine handoff. |
| [re-village-scope-vr-engine-research](https://github.com/TefMeister/re-village-scope-vr-engine-research) | Distilled engine reference (dossier) + reusable VR RE playbook. |

## Credits, scope, and legality

Non-commercial fan project; requires an owned copy; redistributes no original
assets. We credit everyone whose work this builds on — see
[`CREDITS.md`](CREDITS.md) — and we honour correction/removal requests from
rights holders promptly.

## Contributing & policy

See [CONTRIBUTING.md](CONTRIBUTING.md) — how we credit and link sources, our
**study-everything-public but write-our-own-code** rule (we copy no one else's
source code or files, any license or price), the terms for reusing our work
(free, with credit), and how to request a correction or removal.
