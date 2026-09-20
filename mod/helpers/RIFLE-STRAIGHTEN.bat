@echo off
rem ---------------------------------------------------------------------------
rem  MAKE THE RIFLE SHOOT WHERE IT POINTS, FROM THE HIP.
rem
rem  Measured 2026-09-21 over eight shots: the game is handed a perfectly clean aim,
rem  then wobbles it, then BUILDS THE BULLET with the wobbly one. Every earlier
rem  attempt corrected it one step too late - after the bullet already existed.
rem
rem  This puts the clean aim back at the exact moment the bullet is built.
rem
rem  It checks its own work. The log will say, per shot:
rem      "STRAIGHTENED  was 9.4 deg off, bullet now built 0.000 deg off"   it worked
rem      "WARNING -- the write did not take"                               it did not
rem      "not touched (not the scoped rifle)"                              wrong gun
rem
rem  Only the scoped rifle. Works instantly - no restart. RIFLE-OFF.bat undoes it.
rem ---------------------------------------------------------------------------
setlocal

if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)

> "%~dp0reframework\data\re_scope_spread.txt" echo 4 0

echo.
echo   Sent: straighten the bullet as it is built.
echo   Fire from the HIP, without holding aim, at something small.
echo.
timeout /t 2 /nobreak >nul 2>&1
