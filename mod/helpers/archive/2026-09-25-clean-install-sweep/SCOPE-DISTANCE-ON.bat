@echo off
rem ---------------------------------------------------------------------------
rem  MAKE THE ZERO HOLD AT EVERY DISTANCE.
rem
rem  The scope picture is taken from a spot about 40 cm to the side of the barrel, and
rem  until now it was aimed at a point a FIXED 50 metres away - right for far targets,
rem  up to 5 degrees wrong up close. That is why the zero had to be re-done whenever
rem  you stood at a different distance from the wall.
rem
rem  With this on, the picture is aimed at whatever the rifle is actually pointing at,
rem  near or far. EXPECT TO NUDGE THE ZERO ONCE after switching it on - a little, and
rem  sideways - and then it should stay put at every distance.
rem
rem  Works instantly, headset only. SCOPE-DISTANCE-OFF.bat undoes it.
rem ---------------------------------------------------------------------------
setlocal

if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)

> "%~dp0reframework\data\re_scope_aimdist.txt" echo 1

echo.
echo   Sent: ON. The picture now aims at what the rifle points at, near or far.
echo   Nudge the zero once if it needs it - then try a close wall AND a far one.
echo.
timeout /t 2 /nobreak >nul 2>&1
