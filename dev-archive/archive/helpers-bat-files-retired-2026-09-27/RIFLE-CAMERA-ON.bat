@echo off
rem ---------------------------------------------------------------------------
rem  RIFLE CAMERA ON  (2026-09-26)
rem  The scope shows a camera of our own mounted on the rifle instead of the
rem  mirror picture. It starts itself the moment the sniper rifle is in your
rem  hands (1920 picture). Still being finished: a band of speckle across the
rem  top of the picture, and it is far too bright outdoors.
rem  Back to the mirror scope: run SCOPE-AUTO-ON.bat.
rem  Takes effect at the next game start, and is remembered.
rem ---------------------------------------------------------------------------
setlocal
if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)
> "%~dp0reframework\data\re_scope_autostart.txt" echo 1 1920 clone
echo.
echo   Rifle camera is ON (from the next game start).
echo   Take the sniper rifle out and the scope shows the rifle's own camera.
echo   Run SCOPE-AUTO-ON.bat to go back to the mirror scope.
echo.
timeout /t 5 /nobreak >nul 2>&1
