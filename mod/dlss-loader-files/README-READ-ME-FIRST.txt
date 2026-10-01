REFramework DLSS loader files, build 76298bd (11 March 2026) - praydog's files, unmodified
========================================================================================

These five files are praydog's own REFramework, DLSS ("pd-upscaler") build 76298bd, exactly as he built them.
Nothing in them was changed. They are here only because GitHub no longer offers that build for download.
REFramework is by praydog, MIT licence (LICENSE-REFramework.txt). https://github.com/praydog/REFramework

WHY: the September 2026 DLSS build (a24c3459) can crash Resident Evil Village the moment the VR headset
becomes ready, before the main menu, on some setups. This March build does not.

HOW: first install praydog's REFramework from his release page (see README.txt of the scope mod, STEP 2).
Then copy the contents of this folder into the game folder, saying YES to overwrite:
  dinput8.dll
  reframework\autorun\re2_sharpness_removal.lua
  reframework\autorun\re8_vr.lua
  reframework\autorun\utility\RE7.lua
  reframework\autorun\utility\RE8.lua
