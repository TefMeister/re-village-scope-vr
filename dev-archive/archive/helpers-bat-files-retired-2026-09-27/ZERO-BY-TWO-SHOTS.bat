@echo off
rem ---------------------------------------------------------------------------
rem  ZERO BY TWO SHOTS  (2026-09-22 evening)
rem  Zero the scope the way a real one is zeroed, at whatever settings are in use.
rem    1. Look through the scope at a wall about 10-15 m away. Fire ONE shot.
rem    2. DO NOT MOVE YOUR FEET. Put the crosshair exactly on the bullet hole. Fire again.
rem    3. The plugin works out the zero from those two shots and applies it.
rem    4. Fire a third shot at anything: it should land on the cross.
rem  Not happy? Run this again and do another pair; each pair refines the last.
rem  Works while the game is running.
rem ---------------------------------------------------------------------------
setlocal
if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)
> "%~dp0reframework\data\re_scope_zeroshots.txt" echo 1
echo.
echo   Armed. Shot 1 at a wall. Then, without moving, crosshair ON THE HOLE, shot 2.
echo   The third shot should land on the cross.
echo.
timeout /t 4 /nobreak >nul 2>&1
