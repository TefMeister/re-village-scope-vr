# 2026-10-01: a flat-screen copy on the dev PC, and the grip moves to Dr.BeGonE

*Dev PC, live session driven by Claude, at Tefa's request: "make the village scope work in flat screen ... also
needs the Dr.BeGonE part extracted only for VR".*

## The flat copy

- **A second copy of the game, for flat-screen work only.** The 38 GB install was copied, without any mod files or
  the VR loader, to a folder of its own on the dev PC's second drive. A `steam_appid.txt` beside the exe lets it
  start from there without Steam switching to the original install `[verified-live 2026-10-01, n=4 launches]`.
  The saves are shared, so "Continue" loads Tefa's latest one (Heisenberg's Factory).
- **Window:** 1280×720 window, screen untouched `[verified-live 2026-10-01]`. The setting lives in the game
  folder's `config.ini`: `WindowMode=Normal` plus `FullScreenDisplayMode=24`, an index into the
  `DisplayModeN_Width/Height` list in the same file (24 = 1280×720 on this PC). ⚠️ The in-game route has a 10-second
  "keep this resolution?" box that defaults to No and ignores the keyboard after a mouse Back; it reverted twice.
  Prefer the file.
- **Music:** BGM Volume set to 0 in Options > Audio. The arrows wrap round (0 to 10), so count the presses. Not
  yet confirmed across a relaunch.
- **What is installed:** praydog's REFramework, the exact build the v1.0.1 release was tested with (`dinput8.dll`
  from the pd-upscaler run of 5 September), and the release's files **minus** the grip, plus the new
  `re8_vrz_scope_sounds_menu.lua`. No VR files. The loose-file loader is switched on in `re2_fw_config.txt`.
  This REFramework build really does use the RE2-named settings file for Village, so the install text is right
  about that.

## The scope in flat

- Everything loads with no script errors; the scope comes up by itself when the sniper rifle (key 4) is drawn.
- **The picture starts black** at a 1280×720 window. The fix found on the home PC on 2026-09-18 still works:
  `fn rtex_1280`, numpad `.`, then `bringup`, through the command file. After it the picture shows
  `[verified-live 2026-10-01, n=1]`. Pictures: `dev-archive/recon/2026-10-01-flat-copy-on-dev-pc/`.
- **Next:** make that happen by itself at start-up, so flat testing on the dev PC needs no hand-sent commands.

## The grip moves out

`re8_vrz_scope_left_grip.lua` held four things. Split, with the code unchanged apart from the joins:

| Now in | What |
| --- | --- |
| Dr.BeGonE, `games/re-village/re8_vrz_begone_grip.lua` (VR only) | the stacked grip and the drawn left hand, with its finger pose |
| this mod, `re8_vrz_scope_sounds_menu.lua` | the weapon-click silencing, the left-menu-button fix, the sound/anim probes |

Checked by `grip_split_test.lua` (8 checks; a deliberately broken copy fails) and by a flat launch: the scope's
half loads, and `grip` answers "Dr.BeGonE is not installed -- VR only". **Not yet worn in the headset.**

⚠️ **The next scope release must not ship before Dr.BeGonE has a download**, or players lose the grip. Until then
v1.0.1 stays as it is.

## Corrected the same day: the download link was NOT broken

I reported the install text's REFramework link as dead after ONE request to its direct-download form answered "not found". Tefa had installed from it the day before without trouble. Re-checked: the link opens the page with all three downloads, and its REFramework.zip is 13,249,715 bytes, the same size as the tested build `[verified-live 2026-10-01, n=2]`. The one failure was a passing hiccup of the download site `[hypothesis]`. The texts and the v1.0.1 download were put back exactly as they were (the zip is byte-identical to the original). Lesson: one failed request is not a dead link; retry, and ask the person who installed it last.

## Later the same day: the flat picture comes up by itself `[verified-live 2026-10-01, n=1 launch]`

- **The fix:** the flat copy has `reframework/data/re_scope_autostart.txt` = `1 1280`. That tells the automatic start to use
  the mirror picture at 1280 instead of the rifle camera, and it then does the three steps itself (`fn rtex_1280`, the
  re-arm, `bringup`) 0.32 s after the rifle is drawn. The picture shows; nothing was sent by hand
  (`3-scope-came-up-by-itself.png`, `autostart-by-itself-log.txt`). No code change was needed for this.
- **Why not the rifle camera (the release default) on this PC:** its picture stays near black here: the scope circle
  averages about 2 of 255 against about 19 for the wall it points at, with the 8-bit target and with the float target
  `[measured 2026-10-01]` (pictures 4 and 5). Part of the cause was found and fixed: the step that takes the rifle
  camera's finished picture looked for its layer next to the mirror layers, and in the factory those are detached, so
  it looked at nothing. It now finds the layer through the renderer and retries (staging, tested). The add-on's
  next link still fails: the view's texture slot is empty, which in REFramework's own code also means "no picture".
  Likely because this PC runs with no upscaler (a GTX 1660 Super cannot run DLSS) and the game then draws its final
  picture straight to the window's buffers `[hypothesis]`. Home, with DLSS, found the picture at the same slot.
- **Installed on the flat copy:** the add-on rebuilt here from the committed source plus a diagnostic that names the
  broken link (`bf2146280a43`; the release build `7b8dd4912575` contains the same 309 log messages, so it came from
  the same source, and the size difference is the compiler).
- **Saves:** Tefa saw the other save slots reported as corrupted in this copy. The slot files were not written
  today (only the autosave and the settings file, at 18:02, when the game loaded); a full copy of the save folder
  was taken first to `D:\claude video game stuff\save-backups\re-village-2026-10-01-1810\` (27 files). Whether the
  slots load in the normal install is not checked yet.
