@echo off
rem VR-TRUE-SCOPE.bat -- the whole scope set-up in one click, including the new
rem "true picture" mirror pose. About 50 seconds. Have the sniper rifle in your hands.
rem
rem WHAT IT DOES, and why the order matters:
rem   1. fn rtex_2560   pick the 2560x1440 mirror target. It is higher quality AND safer
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
echo   Setting up the scope. Do not touch anything for about 50 seconds.
echo.

echo   [1/4] choosing the 2560x1440 mirror target...
echo fn rtex_2560> "%CMD%"
timeout /t 3 /nobreak >nul 2>&1

echo   [2/4] re-arming the mirror latch (pressing numpad . for you)...
powershell -NoProfile -Command ^
  "Add-Type -Name W -Namespace K -MemberDefinition '[DllImport(\"user32.dll\")] public static extern void keybd_event(byte b, byte s, uint f, int e); [DllImport(\"user32.dll\")] public static extern System.IntPtr FindWindow(string c, string n); [DllImport(\"user32.dll\")] public static extern bool SetForegroundWindow(System.IntPtr h);'; $h=[K.W]::FindWindow($null,'RESIDENT EVIL VILLAGE'); if($h -ne [System.IntPtr]::Zero){[void][K.W]::SetForegroundWindow($h); Start-Sleep -Milliseconds 700}; [K.W]::keybd_event(0x6E,0,0,0); Start-Sleep -Milliseconds 80; [K.W]::keybd_event(0x6E,0,2,0)"
timeout /t 3 /nobreak >nul 2>&1

echo   [3/4] building the scope -- this is the slow bit, about 35 seconds...
echo bringup> "%CMD%"
timeout /t 45 /nobreak >nul 2>&1

echo   [4/4] laying the mirror along your line of sight...
>  "%CMD%" echo pitch 90
>> "%CMD%" echo yaw 90
>> "%CMD%" echo propf 0
>> "%CMD%" echo propu 0
>> "%CMD%" echo propr 0.20

echo.
echo   Done. Look through the scope.
echo.
echo   If the picture is the inside of the scope tube (brown and gold streaks),
echo   send a bigger propr -- try 0.25 or 0.30.
echo   If it looks too far off to one side, try 0.15.
echo.
timeout /t 6 /nobreak >nul 2>&1
exit /b 0
