@echo off
rem ---------------------------------------------------------------------------
rem  MIRROR LIGHT-WEIGHT MODE ON  (2026-09-25, a test for the lights glitch)
rem  The scope's hidden second camera is built in the game's "light-weight"
rem  mode from the next launch on. Test: do the world's lights stop following
rem  the rifle? Does the scope picture still work?
rem  Needs a game RESTART to take effect. Remembered for next time.
rem ---------------------------------------------------------------------------
setlocal
if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)
> "%~dp0reframework\data\re_scope_mirror_lw.txt" echo 1
echo.
echo   Mirror light-weight mode is ON for the next launch.
echo   Restart the game, take the rifle out, and judge the lights and the picture.
echo   MIRROR-LIGHTWEIGHT-OFF.bat puts it back.
echo.
timeout /t 5 /nobreak >nul 2>&1
