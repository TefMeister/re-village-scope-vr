Description


A fan-made add-on for praydog's REFramework VR mod for Resident Evil Village, installed with Fluffy Mod Manager.
a real magnified view through the rifle's lens that points exactly where the bullets go.
a steady two-handed grip: holding the left grip button with the left controller lowers the rifle a little, so aiming straight means the left motion controller is visibly above the right one, to avoid occlusion drift.
no stray weapon clicks when the rifle dips or comes up.
The scope keeps working through hits, knockdowns and weapon switches.

This is not a VR mod on its own: it needs praydog's REFramework with its VR mode installed first.
Not an official Capcom or REFramework product, and not affiliated with either.
It contains no original game files and no REFramework files. You must own Resident Evil Village.


Installation instructions


STEP 1 - The game

1.1  Install Resident Evil Village from Steam (only tested with the Steam version).

1.2  Find the game folder: in Steam, right-click the game > Manage > Browse local files. This is the folder that contains re8.exe. Every "game folder" below means this folder.

1.3  Start the game once, reach the main menu, and quit.


STEP 2 - praydog's REFramework (the DLSS "pd-upscaler" build a24c3459, 5 September 2026 - Fluffy does not install this part)

2.1  Open https://nightly.link/praydog/REFramework/workflows/dev-release/pd-upscaler
(the same build on GitHub: https://github.com/praydog/REFramework/actions/runs/33940315972 - possibly needs a GitHub login)

2.2  Download two files: "REFramework.zip" and "VR.zip".

2.3  From REFramework.zip, copy dinput8.dll into the game folder.

2.4  From VR.zip, copy openxr_loader.dll and the whole "reframework" folder into the game folder. Tried it with OpenVR and SteamVR too and worked just fine.


STEP 3 - DLSS (optional, but this is how it was tested)

3.1  PureDark's "Upscaler Base Plugin" version 1.1.2 from Nexus Mods (not 1.2.0: that one loads but finds no DLSS with this REFramework build, tested 30 September 2026):
https://www.nexusmods.com/site/mods/502  (under Files, pick the 1.1.2 version: UpscalerBasePlugin-502-1-1-2-....zip)
- Copy only PDPerfPlugin.dll into the game folder. (The ffx_*.dll files are for AMD FSR; not needed for DLSS.)

3.2  NVIDIA's DLSS library, version 310.5.3, from NVIDIA's official repository (the newer 310.9.1 does not work with the 1.1.2 plugin):
https://github.com/NVIDIA/DLSS/blob/v310.5.3/lib/Windows_x86_64/rel/nvngx_dlss.dll
Click the download button (the down-arrow, top right of the file box) to download nvngx_dlss.dll, then copy it into the game folder.

3.3  In the game folder, create a text file named re2_fw_config.txt (or open it if it exists) and make sure it
contains these lines:
TemporalUpscaler_Enabled=true
TemporalUpscaler_UpscaleQuality=1
TemporalUpscaler_SharpnessEnable=true
TemporalUpscaler_SharpnessAmount=0.000000
TemporalUpscaler_UseNativeResolution=false


STEP 4 - Check VR works before adding this mod

4.1  Start your VR runtime (for example Virtual Desktop or Quest Link) with OpenXR.

4.2  Start the game. You should be in VR. Press Insert on the keyboard to see the REFramework menu.

4.3  Quit the game.


STEP 5 - This mod, with Fluffy Mod Manager

5.1  Download Fluffy Mod Manager from Nexus Mods (free):
https://www.nexusmods.com/residentevilvillage/mods/18?tab=files&file_id=970
Unzip it into a folder of its own (not inside the game folder) and start Modmanager.exe.

5.2  Open Fluffy Mod Manager and choose Resident Evil Village.

5.3  Drag "RE-Village-VR-Scope-v1.0.0-Fluffy.zip" into the Fluffy window.
(Or put the zip into Fluffy's Games\RE8\Mods folder and restart Fluffy.)

5.4  Tick "RE Village VR Scope" in the list, so it installs.

5.5  Add this line to re2_fw_config.txt in the game folder (or tick "Loose File Loader" in the REFramework menu):
          LooseFileLoader_Enabled=true


STEP 6 - Play

6.1  Start the game in VR and load your save.

6.2  Take out the sniper rifle. The scope switches on by itself within about a second.


UNINSTALL

Untick "RE Village VR Scope" in Fluffy. It removes every file it added.


Main features


gets rid of the huge billboard with a scope in the middle when playing in vr and replaces it with a gun and a working accurate scope


Requirements


REFramework
Fluffy Mod Manager


Shout outs


Claude Code for all the coding
Andyalpa for the PIP idea
MarsyApp for the idea from the Anomaly VR mod - raising left controller above the right one to remove occlusion drift
Praydog - this would not exist without REFramework
PureDark for Upscaler Base Plugin
FluffyQuack for Fluffy Mod Manager
If you should be credited here and are not, contact us and we will fix it as soon as possible. We honour correction and removal requests from rights holders.
