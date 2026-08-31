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

This is neutral research, done in the open — not built for any one project,
person, or group in particular, but for anyone who wants to pick it up. If we
can crack it here, the technique will be useful for every Resident Evil game
that has scopes.

Everything is **written from scratch** against REFramework's published plugin
SDK headers; praydog's sources are studied and credited as prior art, but no
one else's code is used — every line is our own, by deliberate policy. The
playable plugin is almost the by-product: the real goal is the knowledge
gained on the way, written down so anyone can do the same — see the
[engine dossier](../engine-research/)
and the cross-engine
[flat-to-VR library](https://github.com/TefMeister/flat-to-vr-cross-engine-research).

## What you will need

- Your own legitimate copy of **Resident Evil Village** (this mod contains
  **no** game files).
- [REFramework](https://github.com/praydog/REFramework) (the RE8 build).
- A PC VR headset via SteamVR/OpenXR (Quest over Link/Virtual Desktop works).

## The folders for the RE Village VR scope

Everything for this project lives in six folders, each with one job — so
you always know where to look. You are in **`mod/`**.

| Folder | What lives here |
| --- | --- |
| **`mod/`** ← you are here | The plugin itself — releases only. |
| [`dev-archive/`](../dev-archive/) | Full development history — snapshots, probes, dead ends, raw recon. |
| [`modding-notes/`](../modding-notes/) | Readable field notes / progress ledger. |
| [staging/re-village-scope-vr](https://github.com/TefMeister/staging/tree/main/re-village-scope-vr) 🔒 | **Private** — unverified WIP builds, cross-machine handoff. |
| [`engine-research/`](../engine-research/) | Distilled engine reference (dossier) + reusable VR RE playbook. |
| [`external-research/`](../external-research/) | Ongoing public-research leads, gathered separately from hands-on modding work. |

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
