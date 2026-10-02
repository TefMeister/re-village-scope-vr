A working sniper scope for **Resident Evil Village in VR**, as an add-on for praydog's REFramework VR mod.

## What changed in v1.1.1
- **The left hand lets go with a short pull.** Before, it only let go once the hands were far apart, and a sideways
  pull barely counted. Now it lets go when the left hand moves about 10 cm, or about 25 degrees sideways, from where it
  took the grip. Firing and working the bolt do not drop it.
- **The pistol is aimed by the right hand only.** A left hand resting on the pistol's grip no longer steers it.
- **Every weapon keeps its own left-hand spot.** The rifle's left-hand spot was being used on every weapon once the
  rifle had been out, so the left hand floated in the air beside the pistol and the shotgun. Now it only applies to the
  sniper rifle.
- **The left hand docks by itself on any two-handed gun** (the left grip button still works).
- **The rifle no longer points off to the side after a restart.**
- Install steps are unchanged from v1.0.2.

## What it does
- A real magnified view through the rifle's lens that points exactly where the bullets go.
- The game's own colours, outdoors and indoors.
- A steady two-handed grip on every two-handed gun: the left hand docks by itself, and holding the left grip button with the left controller lowers the rifle a little, so aiming straight means the left controller is visibly **above** the right one, to avoid occlusion drift.
- No stray weapon clicks when the rifle dips or comes up: the game had three left-hand positions on the rifle, each with a quick "gun click" sound; now there is one left-hand pose. The bolt and reload sounds stay.
- The scope keeps working through hits, knockdowns and weapon switches, where before it froze for a second after a hit or a switch back to the rifle.

## Install
Also on Nexus Mods: https://www.nexusmods.com/residentevilvillage/mods/827

Download **RE-Village-VR-Scope-v1.1.1-manual.zip** (manual install) or **RE-Village-VR-Scope-v1.1.1-fluffyMM.zip** (Fluffy Mod
Manager) below and follow the readme inside it. In short, the versions this was tested with on a clean install:
- praydog's REFramework release v1.5.9.1, with the five DLSS ("pd-upscaler") build `76298bd` files on top
- Works well with both OpenXR and SteamVR (OpenVR)
- PureDark's Upscaler Base Plugin 1.1.2 (Nexus Mods, site mod 502) and NVIDIA DLSS 310.5.3 (optional, for DLSS)

There are no `.bat` files and nothing to run: the mod is a set of files copied into the game folder.

## Disclaimer
This is a fan-made add-on. It is **not** a VR mod on its own (it needs praydog's REFramework), it is **not** affiliated
with Capcom or REFramework, and it contains **no** game files. The mod's own zips contain **no** REFramework files; the
separate loader-files zip (the same as v1.0.2's) holds five of praydog's files, unmodified, under his MIT licence. You must own Resident Evil
Village.

## Credits
praydog for REFramework and its VR mode; Andyalpa for the picture-in-picture (PIP) scope idea that started this whole project; MarsyApp for the idea from the Anomaly VR mod of raising the left controller above the right one to remove occlusion drift; PureDark for the Upscaler Base Plugin; NVIDIA for DLSS; FluffyQuack for Fluffy Mod Manager; Capcom for Resident
Evil Village; and the modding community. If you should be credited and are not, contact us and we will fix it as soon
as possible. We honour correction and removal requests from rights holders.
