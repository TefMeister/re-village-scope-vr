RE VILLAGE VR SCOPE  v1.0.1  (2026-09-30)

v1.0.1: the install text is corrected (the DLSS versions that actually work); the mod's own files are unchanged from v1.0.0.
==========================================

WHAT THIS IS
A fan-made add-on for praydog's REFramework VR mod for Resident Evil Village. It gives the sniper rifle a working
scope in VR:
- a real magnified view through the lens that points exactly where the bullets go,
- the game's own colours outdoors and indoors,
- a steady two-handed grip (the "stacked" hold: left controller a little above the right),
- no stray weapon clicks when the rifle dips or comes up,
- the scope keeps working through hits, knockdowns and weapon switches.

WHAT THIS IS NOT
- Not a VR mod on its own. It needs praydog's REFramework (with its VR mode) installed first.
- Not an official Capcom or REFramework product, and not affiliated with either.
- It contains NO game files and NO REFramework files. You must own Resident Evil Village.
- There are no .bat files and nothing to run: it is a set of files copied into the game folder.

STEP-BY-STEP INSTALL
--------------------
Tested on 2026-09-27 on a clean Steam install, with exactly the versions below.

STEP 1 - The game
  1.1  Install Resident Evil Village from Steam.
  1.2  Find the game folder: in Steam, right-click the game > Manage > Browse local files.
       This is the folder that contains re8.exe. Every "game folder" below means this folder.
  1.3  Start the game once, reach the main menu, and quit. (This lets Steam and the game finish their setup.)

STEP 2 - praydog's REFramework (the DLSS "pd-upscaler" build a24c3459, 5 September 2026)
  2.1  Open https://nightly.link/praydog/REFramework/workflows/dev-release/pd-upscaler
       (the same build on GitHub: https://github.com/praydog/REFramework/actions/runs/33940315972 - needs a GitHub login)
  2.2  Download two files: "REFramework.zip" and "VR.zip".
  2.3  From REFramework.zip, copy dinput8.dll into the game folder.
  2.4  From VR.zip, copy the whole "reframework" folder into the game folder, plus the file for the way you play:
         - openxr_loader.dll for OpenXR (for example Virtual Desktop or Quest Link set to OpenXR), or
         - openvr_api.dll for SteamVR (OpenVR).
       This mod works well with both OpenXR and SteamVR (OpenVR).

STEP 3 - DLSS (optional, but this is how it was tested)
  3.1  PureDark's "Upscaler Base Plugin" version 1.1.2 from Nexus Mods (not 1.2.0: that one loads but finds no DLSS with this REFramework build, tested 30 September 2026):
       https://www.nexusmods.com/site/mods/502  (under Files, pick the 1.1.2 version: UpscalerBasePlugin-502-1-1-2-....zip)
       Copy PDPerfPlugin.dll into the game folder (the 1.1.2 zip holds just that one file).
  3.2  NVIDIA's DLSS library, version 310.5.3, from NVIDIA's official repository (the newer 310.9.1 does not work with the 1.1.2 plugin):
       https://github.com/NVIDIA/DLSS/tree/v310.5.3/lib/Windows_x86_64/rel
       Download nvngx_dlss.dll and copy it into the game folder.
  3.3  In the game folder, create a text file named re2_fw_config.txt (or open it if it exists) and make sure it
       contains these lines:
           TemporalUpscaler_Enabled=true
           TemporalUpscaler_UpscaleQuality=1
           TemporalUpscaler_SharpnessEnable=true
           TemporalUpscaler_SharpnessAmount=0.000000
           TemporalUpscaler_UseNativeResolution=false

STEP 4 - Check VR works before adding this mod
  4.1  Start your VR runtime (for example Virtual Desktop, Quest Link or SteamVR).
  4.2  Start the game. You should be in VR. Press Insert on the keyboard to see the REFramework menu.
  4.3  Quit the game.

STEP 5 - This mod
  5.1  Open the folder "Resident Evil Village BIOHAZARD VILLAGE" inside this package.
  5.2  Copy EVERYTHING inside it into the game folder. If Windows asks to merge folders, say yes.
       (The full list of what is added is in FILES.txt.)
  5.3  Change this line in re2_fw_config.txt, in the game folder, from false to true (or tick "Loose File Loader" in the REFramework menu):
           LooseFileLoader_Enabled=true
       If you created re2_fw_config.txt yourself, you might need to add that line manually.

STEP 6 - Play
  6.1  Start the game in VR and load your save.
  6.2  Take out the sniper rifle. The scope switches on by itself within about a second.
  6.3  To hold the rifle with both hands: hold the LEFT GRIP button with the left controller a few centimetres ABOVE the
       right controller. The left hand goes on the forestock, the rifle aims with your right hand, and the headset can
       see both controllers.


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
