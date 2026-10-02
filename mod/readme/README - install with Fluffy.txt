Description


A fan-made add-on for praydog's REFramework VR mod for Resident Evil Village, installed with Fluffy Mod Manager or by hand.
a real magnified view through the rifle's lens that points exactly where the bullets go.
a steady two-handed grip: holding the left grip button with the left controller will lower the rifle a little, so aiming straight means that left motion controller is visibly above the right one, to avoid occlusion drift.
no stray weapon clicks when the rifle dips or comes up. The game had 3 different left hand positions on the rifle, and when each of them triggered, a quick "gun click sound" was played. Now there is only one left hand pose gripping the rifle, because it was unreliable in VR and the sounds got annoying.
the scope keeps working through hits, knockdowns and weapon switches, where before it kept freezing for a second each time after getting hit or changing back to the rifle.

This is not a VR mod on its own: it needs praydog's REFramework with its VR mode installed first.
Not an official Capcom or REFramework product, and not affiliated with either.
It contains no original game files and no REFramework files. You must own Resident Evil Village.


Changes in v1.1.2


The sniper rifle no longer jumps to the right when it fires.
The scope picture now brightens and dims with the game, indoors and outdoors, and its blue tint is gone.


Changes in v1.1.1


The left hand lets go of the gun with a short pull: about 10 cm, or about 25 degrees sideways.
On the pistol the left hand rests on the grip, but does not steer the gun.
The rifle's left-hand spot no longer moves the left hand on other weapons.
The rifle no longer points off to the side after a restart.


Installation instructions


STEP 1 - The game

1.1  Install Resident Evil Village from Steam (only tested with the Steam version).

1.2  Find the game folder: in Steam, right-click the game > Manage > Browse local files. This is the folder that contains re8.exe. Every "game folder" below means this folder.

1.3  Start the game once, reach the main menu, and quit. (This lets Steam and the game finish their setup.)


STEP 2 - praydog's REFramework (release v1.5.9.1), then the DLSS loader files (build 76298bd, 11 March 2026 - Fluffy does not install this part)

2.1  Open https://github.com/praydog/REFramework/releases/tag/v1.5.9.1 and download "RE8.zip".

2.2  From RE8.zip, copy dinput8.dll, openxr_loader.dll and the whole "reframework" folder into the game folder. Tried it with OpenVR and SteamVR too and worked just fine.

2.3  Now the DLSS loader files. From the scope mod's GitHub release page (https://github.com/TefMeister/re-village-scope-vr/releases/latest), download "REFramework-DLSS-loader-76298bd-files.zip" and copy its contents into the game folder, saying YES to overwrite. These five files are praydog's own DLSS ("pd-upscaler") build 76298bd, unmodified; they are offered there only because GitHub no longer has that build for download.

WHY THIS BUILD: the newer September 2026 DLSS build (a24c3459) can crash the game the moment the VR headset becomes ready, before the main menu, on some setups (it did on ours, nearly every start). The March build does not.


STEP 3 - DLSS (optional, but this is how it was tested)

3.1  PureDark's "Upscaler Base Plugin" version 1.1.2 (under Files, pick the 1.1.2 version, not 1.2.0: that one loads but finds no DLSS with this REFramework build, tested 30 September 2026):
https://www.nexusmods.com/site/mods/502
- Copy only PDPerfPlugin.dll into the game folder.

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


STEP 5 - Install this mod with Fluffy Mod Manager
(Fluffy Mod Manager, free: https://www.nexusmods.com/residentevilvillage/mods/18?tab=files&file_id=970)

5.1  Unzip it into a folder of its own (not inside the game folder).

5.2  Open Fluffy Mod Manager (see the downloads button there; it might need you to download a newer version of the mod manager first), then choose Resident Evil Village.

5.3  Drag "RE-Village-VR-Scope-v1.1.2-fluffyMM.zip" into the Fluffy window.
(Or put the zip into Fluffy's Games\RE8\Mods folder and restart Fluffy.)

5.4  Tick "RE Village VR Scope" in the list, so it installs.

5.5  Change this line in re2_fw_config.txt, in the game folder, from false to true (or tick "Loose File Loader" in the REFramework menu):
          LooseFileLoader_Enabled=true
If you created the re2_fw_config.txt file yourself, you might need to add that line manually.

---------- STEPS FOR MANUAL INSTALL ----------

5.1  Open the folder "Resident Evil Village BIOHAZARD VILLAGE" inside this package.

5.2  Copy EVERYTHING inside it into the game folder. If Windows asks to merge folders, say yes.
     (The full list of what is added is in FILES.txt.)

5.3  Change this line in re2_fw_config.txt, in the game folder, from false to true (or tick "Loose File Loader" in the REFramework menu):
          LooseFileLoader_Enabled=true
If you created the re2_fw_config.txt file yourself, you might need to add that line manually.


STEP 6 - Play

6.1  Start the game in VR and load your save.

6.2  Take out the sniper rifle. The scope switches on by itself within about a second.


UNINSTALL

Delete the files listed in FILES.txt from the game folder (or untick "RE Village VR Scope" in Fluffy, if you installed it that way).


Main features


gets rid of the huge billboard with a scope in the middle when playing in VR and replaces it with a gun and a working accurate scope


Requirements


REFramework


Shout outs


Claude Code for all the coding for a month and 5 days
Andyalpa for the PIP idea
MarsyApp for the idea from the Anomaly VR mod - raising left controller above the right one to remove occlusion drift
Praydog - this would not exist without REFramework
PureDark for Upscaler Base Plugin
FluffyQuack for Fluffy Mod Manager
If you should be credited here and are not, contact us and we will fix it as soon as possible. We honour correction and removal requests from rights holders.
