# RE Village VR Scope

A real, usable sniper scope for **Resident Evil Village in VR** (praydog's
[REFramework](https://github.com/praydog/REFramework) native VR) — a native
C++ REFramework plugin that renders a true second view of the world onto the
rifle's scope lens, accurate to where the bullet actually goes. This is what
VR players call a **"PiP (picture-in-picture) scope"**: the lens itself is a
live picture — a separately rendered, magnified view — not a fullscreen zoom
or a flat overlay. (Not to be confused with the mod's flat-monitor mode,
which additionally shows a picture-in-picture magnifier circle on screen;
in VR the lens is the whole show.)

> **Status: finished. Current version v1.1.5 (2026-10-10, confirmed in play). v1.1.2 released 2026-10-02 (v1.0.0 on 2026-09-27); v1.1.3 added the scope's 5 cm near limit (no seeing through nearby walls); v1.1.4 removed the rifle-up lag and tuned the colour; v1.1.5 keeps reloads from being cancelled by the VR block gesture when both hands hold the gun.** Download the zip from the
> [Releases page](https://github.com/TefMeister/re-village-scope-vr/releases) or from
> [Nexus Mods](https://www.nexusmods.com/residentevilvillage/mods/827) — its `README.txt` has step-by-step
> install instructions and the exact REFramework, DLSS and NVIDIA versions it was tested with. No `.bat` files: it is
> a set of files copied into the game folder, on top of praydog's REFramework.
>
> It is a fan-made add-on, not affiliated with Capcom or REFramework, and contains no game files and no REFramework files.

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
- A PC VR headset. The mod works well with both OpenXR and SteamVR (OpenVR);
  Quest over Link or Virtual Desktop works.

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

## Known limitations

These are known and will ship as they are. They are listed here so nobody is
surprised by them.

- **The scope picture can streak at its edge if you move your head far off
  the line of the scope.** Lowering your head well below the rifle, or
  leaning a long way to one side, makes the picture smear at its top or right
  edge. It only happens on those two sides. Ordinary aiming, with your eye
  behind the scope, does not reach it. We have not fixed it, and we do not
  yet fully understand why it happens.
- **Moving your head still moves the scope picture a little** while the
  rifle is held still. A real scope would not do this. It is much smaller
  than it was, and it is parked for now.

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
