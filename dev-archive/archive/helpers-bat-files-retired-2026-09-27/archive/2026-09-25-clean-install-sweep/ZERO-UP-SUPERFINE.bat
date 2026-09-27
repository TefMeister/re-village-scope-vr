@echo off
rem ---------------------------------------------------------------------------
rem  ZEROING, SUPER FINE: nudge the picture UP by 0.1 degrees.
rem
rem  HALF the XFINE step. Asked for by Tefa 2026-09-21, once every shot landed
rem  where the rifle points and the zero could be judged to a hair.
rem
rem  Four sizes now, so use whichever suits:
rem     ZERO-UP.bat          2.0 deg   - getting near
rem     ZERO-UP-FINE.bat     0.4 deg   - closing in
rem     ZERO-UP-XFINE.bat    0.2 deg   - landing it
rem     ZERO-UP-SUPERFINE.bat 0.1 deg - the last hair
rem
rem  Steps: READ-ME-ZEROING.txt, in this folder.
rem ---------------------------------------------------------------------------
setlocal

if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)

> "%~dp0reframework\data\re_scope_cmd.txt" echo dzeroup 0.1

echo.
echo   Super-fine nudge UP 0.1 degrees.
echo.
timeout /t 2 /nobreak >nul 2>&1
