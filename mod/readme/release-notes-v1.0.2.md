A working sniper scope for **Resident Evil Village in VR**, as an add-on for praydog's REFramework VR mod.

## What changed in v1.0.2
- Updated readme for the installation steps. The REFramework build to install has changed: praydog's release
  v1.5.9.1 first, then the five files of his March DLSS build `76298bd` on top (attached below as
  **REFramework-DLSS-loader-76298bd-files.zip**, his files, unmodified, with his licence). The September build
  `a24c3459` named by v1.0.0 and v1.0.1 can crash the game the moment the VR headset becomes ready, before the
  main menu, on some setups; on our test PC it did on nearly every start, and the March build started every time.
- The Fluffy Mod Manager package carries the same readme and its preview picture.
- The mod's own files are unchanged since v1.0.0.

## What it does
- A real magnified view through the rifle's lens that points exactly where the bullets go.
- The game's own colours, outdoors and indoors.
- A steady two-handed grip: holding the left grip button with the left controller lowers the rifle a little, so aiming straight means the left controller is visibly **above** the right one, to avoid occlusion drift.
- No stray weapon clicks when the rifle dips or comes up: the game had three left-hand positions on the rifle, each with a quick "gun click" sound; now there is one left-hand pose. The bolt and reload sounds stay.
- The scope keeps working through hits, knockdowns and weapon switches, where before it froze for a second after a hit or a switch back to the rifle.

## Install
Also on Nexus Mods: https://www.nexusmods.com/residentevilvillage/mods/827

Download **RE-Village-VR-Scope-v1.0.2.zip** (manual install) or **RE-Village-VR-Scope-v1.0.2-Fluffy.zip** (Fluffy Mod
Manager) below and follow the readme inside it. In short, the versions this was tested with on a clean install:
- praydog's REFramework release v1.5.9.1, with the five DLSS ("pd-upscaler") build `76298bd` files on top
- Works well with both OpenXR and SteamVR (OpenVR)
- PureDark's Upscaler Base Plugin 1.1.2 (Nexus Mods, site mod 502) and NVIDIA DLSS 310.5.3 (optional, for DLSS)

There are no `.bat` files and nothing to run: the mod is a set of files copied into the game folder.

## Disclaimer
This is a fan-made add-on. It is **not** a VR mod on its own (it needs praydog's REFramework), it is **not** affiliated
with Capcom or REFramework, and it contains **no** game files. The mod's own zips contain **no** REFramework files; the
separate loader-files zip holds five of praydog's files, unmodified, under his MIT licence. You must own Resident Evil
Village.

## Credits
praydog for REFramework and its VR mode; Andyalpa for the picture-in-picture (PIP) scope idea that started this whole project; MarsyApp for the idea from the Anomaly VR mod of raising the left controller above the right one to remove occlusion drift; PureDark for the Upscaler Base Plugin; NVIDIA for DLSS; FluffyQuack for Fluffy Mod Manager; Capcom for Resident
Evil Village; and the modding community. If you should be credited and are not, contact us and we will fix it as soon
as possible. We honour correction and removal requests from rights holders.
