@echo off
rem  !! DOUBLE-CLICK THIS. DO NOT RUN IT FROM A TOOL WITH stdin REDIRECTED.
rem     Every wait below is `timeout`, which REFUSES TO RUN AT ALL when stdin is
rem     redirected ("ERROR: Input redirection is not supported"). The script then
rem     races straight through and all four steps land in the command file inside
rem     one second, overwriting each other before the plugin can read them -- and it
rem     still prints every "[n/4]" line and exits 0, so it looks like it worked.
rem     Bitten on 2026-09-19. To drive it from a script, do the steps with real
rem     sleeps instead; see modding-notes/2026-09-19c-*.md.
rem
rem VR-TRUE-SCOPE.bat -- the whole scope set-up in one click, including the new
rem "true picture" mirror pose. About 50 seconds. Have the sniper rifle in your hands.
rem
rem WHAT IT DOES, and why the order matters:
rem   1. fn rtex_1920   pick the 1920x1080 mirror target (2026-09-21: Tefa, 2560x1440 was
rem                     noticeably costing performance in the headset; the plugin now
rem                     refuses the game's own 1080-high buffers, so 1920 is safe).
rem                     BEFORE: fn rtex_2560, higher quality AND safer
rem                     than the 1920 default: 2560 cannot collide with a 1080p desktop
rem                     buffer, which is what made the picture go black on 2026-09-18.
rem   2. numpad .       re-arm the mirror latch BEFORE anything allocates the target.
rem                     A target allocates on its first use per process, so this has to
rem                     come first or the latch keeps the wrong buffer. This script
rem                     presses the key for you.
rem   3. bringup        build the rig and bind the glass (~35 s).
rem   4. the pane pose  lay the mirror ALONG the line of sight instead of across it:
rem                       pitch 90, yaw 90, propf 0, propu 0, propr 0.20
rem                     That puts the picture's viewpoint exactly on your eye (measured
rem                     2026-09-18: off_u lever -1.93 -> 0.00, viewpoint 0.00 m from the
rem                     head) instead of ~0.9 m below it, which is what put Ethan's
rem                     clothing, the weapon, the ground and branches in the picture.
rem                     propr 0.20 shifts the viewpoint just off the scope's own axis --
rem                     at 0 the mirror renders the inside of the scope tube, because the
rem                     real view has a lens and the mirror pass does not.
rem
rem   propr is the number to play with. Smaller = less sideways offset = less parallax,
rem   but below about 0.20 the scope body comes back into the picture. Change the value
rem   at the bottom of this file, or send `propr <n>` yourself at any time.
rem
rem Put this in the game folder. Full story: engine-research/ENGINE-DOSSIER.md,
rem and engine-research/inbox/2026-09-18-mod-the-mirror-turns-the-picture-*.md

setlocal
set "CMD=%~dp0reframework\data\re_scope_cmd.txt"
if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)

echo.
echo   Setting up the scope.
echo.
echo   THE PICTURE USUALLY APPEARS IN UNDER A SECOND - look through the scope as
echo   soon as it is there, no need to watch this window.
echo.
echo   NEW 2026-09-24: the picture is aimed at your eye as the scope is built, so
echo   it should NOT show Ethan's clothes first any more. The last step still sends
echo   the same aim again as a safety net - leave this window open until it ends.
echo   If you DO still see his clothes for the first ~45 s, say so.
echo.

echo   [1/4] choosing the 1920x1080 scope picture...
echo fn rtex_1920> "%CMD%"
timeout /t 3 /nobreak >nul 2>&1

echo   [2/4] re-arming the mirror latch (pressing numpad . for you)...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scope-rearm-key.ps1"
rem  ^ was an inline one-liner that looked up the window by the title
rem    'RESIDENT EVIL VILLAGE'. The real title is 'Resident Evil Village', so the
rem    lookup silently failed and the key went to whatever had focus. It still worked
rem    only because the plugin polls this key globally rather than by window message.
rem    Now in its own file, found by PROCESS rather than by title. 2026-09-19.
timeout /t 3 /nobreak >nul 2>&1

echo   [3/4] building the scope...
echo         Measured cold on 2026-09-19: the rig and the picture are live 61 ms
echo         after this point. The long wait that follows is NOT the scope being
echo         built - it is the harness re-pressing 'bind' at +5 s and +20 s in case
echo         the first press did not take, and this script sitting out the worst
echo         case before it re-sends the pane pose. Since 2026-09-24 bringup itself
echo         writes the pose ~3 s after the rig appears (untested in the game); the
echo         re-send below is kept as a safety net and changes nothing if it took.
echo bringup> "%CMD%"
timeout /t 45 /nobreak >nul 2>&1

echo   [4/4] laying the mirror along your line of sight...
>  "%CMD%" echo pitch 90
>> "%CMD%" echo yaw 90
>> "%CMD%" echo propf 0
>> "%CMD%" echo propu 0
>> "%CMD%" echo propr 0.20

echo.
echo   Done. (The picture was almost certainly ready long before this line.)
echo.
echo   If the picture is the inside of the scope tube (brown and gold streaks),
echo   send a bigger propr -- try 0.25 or 0.30.
echo   If it looks too far off to one side, try 0.15.
echo.
timeout /t 6 /nobreak >nul 2>&1
exit /b 0
