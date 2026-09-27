@echo off
rem ---------------------------------------------------------------------------
rem  ZEROING, SUPER FINE: nudge the picture RIGHT by 0.1 degrees.
rem
rem  HALF the XFINE step. Asked for by Tefa 2026-09-21, once every shot landed
rem  where the rifle points and the zero could be judged to a hair.
rem
rem  Four sizes now, so use whichever suits:
rem     ZERO-RIGHT.bat          2.0 deg   - getting near
rem     ZERO-RIGHT-FINE.bat     0.4 deg   - closing in
rem     ZERO-RIGHT-XFINE.bat    0.2 deg   - landing it
rem     ZERO-RIGHT-SUPERFINE.bat 0.1 deg - the last hair
rem
rem  Steps: READ-ME-ZEROING.txt, in this folder.
rem ---------------------------------------------------------------------------
setlocal

if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)

> "%~dp0reframework\data\re_scope_cmd.txt" echo dzeroright 0.1

echo.
echo   Super-fine nudge RIGHT 0.1 degrees.
echo.
timeout /t 2 /nobreak >nul 2>&1
