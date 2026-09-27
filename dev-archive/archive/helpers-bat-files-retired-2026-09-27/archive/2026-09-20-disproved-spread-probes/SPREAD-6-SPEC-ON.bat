@echo off
rem ---------------------------------------------------------------------------
rem  THEN TRY THIS. Force the rifle's own "how wide does it scatter" number to zero.
rem
rem  The game asks the weapon's data sheet for a scatter width every shot. This
rem  answers zero. It is the tidiest version of the fix and the one a released mod
rem  would use - but right now it applies to EVERY gun, not just the rifle.
rem
rem  Unlike the earlier attempts, this one should show in the numbers: the scatter
rem  printed for each shot should drop to 0.000. If it does not, the number is not
rem  being read from there.
rem
rem  SPREAD-7-ALL-OFF.bat puts everything back.
rem  Needs the rifle in hand. Run it while the game is up, then say so.
rem ---------------------------------------------------------------------------
setlocal

if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)

> "%~dp0reframework\data\re_spread_kill_cmd.txt" echo spec on

echo.
echo   Sent: spec on
echo   Now fire five shots from the HIP, without holding aim.
echo.
timeout /t 2 /nobreak >nul 2>&1
