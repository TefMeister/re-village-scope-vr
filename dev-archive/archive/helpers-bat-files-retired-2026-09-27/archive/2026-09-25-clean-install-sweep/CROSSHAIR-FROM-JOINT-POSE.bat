@echo off
rem ---------------------------------------------------------------------------
rem  CROSSHAIR FROM THE JOINT POSE  (last night's setting, for comparison)
rem  The crosshair maths goes back to the camera-joint pose it always used, with the
rem  view-frame zero from 2026-09-21 (up -10.9 / right -9.2). The drawn-pose line in
rem  the log keeps being written either way. Works while the game is running.
rem ---------------------------------------------------------------------------
setlocal
if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)
> "%~dp0reframework\data\re_scope_drawpose.txt" echo 0
> "%~dp0reframework\data\re_scope_panesrc.txt" echo 0
> "%~dp0reframework\data\re_scope_zeroframe.txt" echo 1
> "%~dp0reframework\data\re_scope_cmd.txt" echo zeroup -10.9
>> "%~dp0reframework\data\re_scope_cmd.txt" echo zeroright -9.2
echo.
echo   Crosshair maths back on the joint pose, zero -10.9 / -9.2 (view frame).
echo.
timeout /t 3 /nobreak >nul 2>&1
