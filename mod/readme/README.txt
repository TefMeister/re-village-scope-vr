RE VILLAGE VR SCOPE  v1.1.2  (2026-10-02)

v1.1.2: the sniper rifle no longer jumps to the right when it fires; the scope picture now brightens and dims with the
        game, indoors and outdoors, and its blue tint is gone.
v1.1.1: the left hand lets go of the gun with a short pull (about 10 cm, or about 25 degrees sideways); on the pistol it
        rests on the grip without steering the gun; the rifle's left-hand spot no longer moves the left hand on other
        weapons; the rifle no longer points off to the side after a restart.
v1.0.2: updated readme for the installation steps (which REFramework build to use, and why); the mod's own files are unchanged.
v1.0.1: the install text is corrected (the DLSS versions that actually work); the mod's own files are unchanged from v1.0.0.
==========================================

WHAT THIS IS
A fan-made add-on for praydog's REFramework VR mod for Resident Evil Village. It gives the sniper rifle a working
scope in VR:
- a real magnified view through the lens that points exactly where the bullets go,
- the game's own colours outdoors and indoors,
- a steady two-handed grip: holding the left grip button with the left controller will lower the rifle a little, so
  aiming straight means that left motion controller is visibly above the right one, to avoid occlusion drift,
- no stray weapon clicks when the rifle dips or comes up (the game had 3 different left hand positions on the rifle,
  each playing a quick "gun click sound" when it triggered; now there is only one left hand pose gripping the rifle),
- the scope keeps working through hits, knockdowns and weapon switches, where before it kept freezing for a second
  each time after getting hit or changing back to the rifle.

WHAT THIS IS NOT
- Not a VR mod on its own. It needs praydog's REFramework (with its VR mode) installed first.
- Not an official Capcom or REFramework product, and not affiliated with either.
- It contains NO game files and NO REFramework files. You must own Resident Evil Village.
- There are no .bat files and nothing to run: it is a set of files copied into the game folder.

STEP-BY-STEP INSTALL
--------------------
Tested on 2026-09-27 on a clean Steam install, with exactly the versions below.

STEP 1 - The game
  1.1  Install Resident Evil Village from Steam (only tested with the Steam version).
  1.2  Find the game folder: in Steam, right-click the game > Manage > Browse local files.
       This is the folder that contains re8.exe. Every "game folder" below means this folder.
  1.3  Start the game once, reach the main menu, and quit. (This lets Steam and the game finish their setup.)

STEP 2 - praydog's REFramework (release v1.5.9.1), then the DLSS loader files (build 76298bd, 11 March 2026)
  2.1  Open https://github.com/praydog/REFramework/releases/tag/v1.5.9.1 and download "RE8.zip".
  2.2  From RE8.zip, copy dinput8.dll and the whole "reframework" folder into the game folder, plus the file for
       the way you play:
         - openxr_loader.dll for OpenXR (for example Virtual Desktop or Quest Link set to OpenXR), or
         - openvr_api.dll for SteamVR (OpenVR).
       This mod works well with both OpenXR and SteamVR (OpenVR).
  2.3  Now the DLSS loader files. From the scope mod's release page
       (https://github.com/TefMeister/re-village-scope-vr/releases/latest), download
       "REFramework-DLSS-loader-76298bd-files.zip" and copy its contents into the game folder, saying YES to
       overwrite. These five files are praydog's own DLSS ("pd-upscaler") build 76298bd, unmodified; they are
       offered there only because GitHub no longer has that build for download.
       WHY THIS BUILD: the newer September 2026 DLSS build (a24c3459) can crash the game the moment the VR
       headset becomes ready, before the main menu, on some setups (it did on ours, nearly every start).
       The March build does not.

STEP 3 - DLSS (3.1 and 3.2 are optional, but this is how it was tested), then the settings file (3.3 and 3.4, needed by everyone)
  3.1  PureDark's "Upscaler Base Plugin" version 1.1.2 (under Files, pick the 1.1.2 version, not 1.2.0: that one loads but finds no DLSS with this REFramework build, tested 30 September 2026):
       https://www.nexusmods.com/site/mods/502
       Copy only PDPerfPlugin.dll into the game folder.
  3.2  NVIDIA's DLSS library, version 310.5.3, from NVIDIA's official repository (the newer 310.9.1 does not work with the 1.1.2 plugin):
       https://github.com/NVIDIA/DLSS/tree/v310.5.3/lib/Windows_x86_64/rel
       Download nvngx_dlss.dll and copy it into the game folder.
  3.3  Start the game once more (with or without the headset), reach the main menu, and quit. This start makes
       REFramework create the file re2_fw_config.txt in the game folder and fill it with its settings.
       Do this step even if you skipped DLSS.
  3.4  Open re2_fw_config.txt in the game folder (Notepad is fine) and check that all of these lines are there, set as
       shown. If one is missing, add it.
           LooseFileLoader_Enabled=true      (it says false at first: change it to true)
       If you installed DLSS in 3.1 and 3.2, also:
           TemporalUpscaler_Enabled=true
           TemporalUpscaler_UpscaleQuality=1
           TemporalUpscaler_SharpnessEnable=true
           TemporalUpscaler_SharpnessAmount=0.000000
           TemporalUpscaler_UseNativeResolution=false
       Save the file.

STEP 4 - Check VR works before adding this mod
  4.1  Start your VR runtime (for example Virtual Desktop, Quest Link or SteamVR).
  4.2  Start the game. You should be in VR. Press Insert on the keyboard to see the REFramework menu.
  4.3  Quit the game.

STEP 5 - This mod
  5.1  Open the folder "Resident Evil Village BIOHAZARD VILLAGE" inside this package.
  5.2  Copy EVERYTHING inside it into the game folder. If Windows asks to merge folders, say yes.
       (The full list of what is added is in FILES.txt.)
  5.3  Check that re2_fw_config.txt, in the game folder, says LooseFileLoader_Enabled=true (you changed it in step 3.4).

STEP 6 - Play
  6.1  Start the game in VR and load your save.
  6.2  Take out the sniper rifle. The scope switches on by itself within about a second.
  6.3  To hold the rifle with both hands: hold the LEFT GRIP button with the left controller a few centimetres ABOVE the
       right controller. The left hand goes on the forestock, the rifle aims with your right hand, and the headset can
       see both controllers.
  6.4  Bring the left hand to the front of any two-handed gun and it docks by itself; pull it about 10 cm away (or about
       25 degrees sideways) and it lets go. On the pistol the left hand rests on the grip but does not steer the gun.


UNINSTALL
Delete the files listed in FILES.txt from the game folder.

CREDITS
- praydog, for REFramework and its VR mode, which this builds on.
- Andyalpa, for the picture-in-picture (PIP) scope idea that started this whole project.
- PureDark, for the Upscaler Base Plugin (PDPerfPlugin), and NVIDIA for DLSS.
- Capcom, for Resident Evil Village.
- Everyone in the modding community whose research and tools made this possible. If you should be credited here and
  are not, contact us and we will fix it as soon as possible.
We honour correction and removal requests from rights holders.
