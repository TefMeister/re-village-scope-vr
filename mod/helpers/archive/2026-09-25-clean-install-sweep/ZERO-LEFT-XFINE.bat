@echo off
rem ---------------------------------------------------------------------------
rem  ZEROING, EXTRA FINE: nudge the picture LEFT by 0.2 degrees.
rem
rem  HALF the FINE step, a TENTH of the coarse one. Asked for 2026-09-20 once the
rem  zero was already within a degree.
rem
rem  Three sizes now, so use whichever suits:
rem     ZERO-LEFT.bat          2.0 deg   - getting near
rem     ZERO-LEFT-FINE.bat     0.4 deg   - closing in
rem     ZERO-LEFT-XFINE.bat    0.2 deg   - landing it
rem
rem  Steps: READ-ME-ZEROING.txt, in this folder.
rem ---------------------------------------------------------------------------
setlocal

if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)

> "%~dp0reframework\data\re_scope_cmd.txt" echo dzeroright -0.2

echo.
echo   Extra-fine nudge LEFT 0.2 degrees.
echo.
timeout /t 2 /nobreak >nul 2>&1
