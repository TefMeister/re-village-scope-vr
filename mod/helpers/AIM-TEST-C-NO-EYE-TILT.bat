@echo off
rem ---------------------------------------------------------------------------
rem  AIM TEST C -- drop the headset's own tilt out of the aiming maths.
rem
rem  Measured on 2026-09-20 (tools/crop_centre_decompose.cpp, 9 checks, 0 failed):
rem  even with the rifle pointed exactly where you are looking, the mod cuts the
rem  scope picture from v = 0.244 - that is 51%% of the way from the middle of the
rem  frame to its TOP EDGE, before you move at all. From there only about 21
rem  degrees of raising the rifle pushes it off the edge entirely.
rem
rem  Two things put it up there:
rem    +0.30  the zeroing (14.4 up). WANTED - it is what makes the shot land on
rem           the crosshair. Not to be removed.
rem    +0.21  the headset eye's own off-centre tilt, which has nothing to do with
rem           the rifle at all. The mod reads it because it assumes the scope
rem           picture is drawn with the headset's projection - and on 2026-09-19
rem           that assumption was DISPROVED (dossier 9av).
rem
rem  This switches the aiming maths off that projection and onto a plain
rem  symmetrical one. If the guess is right it moves the resting place from
rem  0.244 to 0.350 and buys back roughly 9 degrees of room before the streak,
rem  WITHOUT touching the zeroing.
rem
rem  Run AIM-TEST-B-DETAILED.bat to go back to normal.
rem
rem  WHAT TO LOOK FOR: not the aim - the ROOM. Hold the rifle level, then raise it
rem  slowly. How far up can you go before the picture streaks? Compare with B.
rem ---------------------------------------------------------------------------
setlocal

if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)

>  "%~dp0reframework\data\re_scope_cmd.txt" echo geom 1
>> "%~dp0reframework\data\re_scope_cmd.txt" echo geomusep 0

echo.
echo   Aiming maths switched off the headset projection.
echo.
echo   Raise the rifle slowly and see how far it goes before the picture
echo   streaks. Then run AIM-TEST-B-DETAILED.bat and do the same, and say
echo   which one gave you more room.
echo.
timeout /t 3 /nobreak >nul 2>&1
