A working sniper scope for **Resident Evil Village in VR**, as an add-on for praydog's REFramework VR mod.

## Update 2026-10-01: the REFramework build to use has changed
The September DLSS build this text first named (`a24c3459`) can crash the game the moment the VR headset becomes
ready, before the main menu, on some setups: on our test PC it did on nearly every start, and the March build
`76298bd` started every time. GitHub no longer offers that March build, so its five files are attached here as
**REFramework-DLSS-loader-76298bd-files.zip**: praydog's own files, unmodified, with his licence. Install order:
praydog's release v1.5.9.1 first, then those five files on top, then the scope mod. The `README.txt` inside the
mod zip still shows the old step 2; the current text is in the repo under `mod/readme/`.

## What changed in v1.0.1
- The install text now names the DLSS versions that actually work: PureDark's Upscaler Base Plugin **1.1.2** and NVIDIA DLSS **310.5.3**. (v1.0.0 named 1.2.0 and 310.9.1, which load but find no DLSS with this REFramework build.)
- The start-up "hiccup" note is gone: that crash turned out to be a downloaded save set, not REFramework.
- The mod's own files are unchanged from v1.0.0.

## What it does
- A real magnified view through the rifle's lens that points exactly where the bullets go.
- The game's own colours, outdoors and indoors.
- A steady two-handed grip: holding the left grip button with the left controller lowers the rifle a little, so aiming straight means the left controller is visibly **above** the right one, to avoid occlusion drift.
- No stray weapon clicks when the rifle dips or comes up: the game had three left-hand positions on the rifle, each with a quick "gun click" sound; now there is one left-hand pose. The bolt and reload sounds stay.
- The scope keeps working through hits, knockdowns and weapon switches, where before it froze for a second after a hit or a switch back to the rifle.

## Install
Also on Nexus Mods: https://www.nexusmods.com/residentevilvillage/mods/827

Download **RE-Village-VR-Scope-v1.0.1.zip** below and follow `README.txt` inside it. It lists every step and the exact
versions this was tested with on a clean install:
- praydog's REFramework release v1.5.9.1, with the five DLSS ("pd-upscaler") build `76298bd` files on top (see the update above)
- Works well with both OpenXR and SteamVR (OpenVR)
- PureDark's Upscaler Base Plugin 1.1.2 (Nexus Mods, site mod 502) and NVIDIA DLSS 310.5.3 (optional, for DLSS)

There are no `.bat` files and nothing to run: the mod is a set of files copied into the game folder.

## Disclaimer
This is a fan-made add-on. It is **not** a VR mod on its own (it needs praydog's REFramework), it is **not** affiliated
with Capcom or REFramework, and it contains **no** game files and **no** REFramework files. You must own Resident Evil
Village.

## Credits
praydog for REFramework and its VR mode; Andyalpa for the picture-in-picture (PIP) scope idea that started this whole project; PureDark for the Upscaler Base Plugin; NVIDIA for DLSS; Capcom for Resident
Evil Village; and the modding community. If you should be credited and are not, contact us and we will fix it as soon
as possible. We honour correction and removal requests from rights holders.
