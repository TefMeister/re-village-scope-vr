@echo off
rem ---------------------------------------------------------------------------
rem  CROSSHAIR FROM THE DRAWN POSE  (the 2026-09-22 zero test -- this is the default)
rem  The scope picture is drawn from one camera pose and, until today, the crosshair
rem  was placed with a different one. Now the picture-drawing pose is handed over and
rem  used, so the old hand-tuned zero should no longer be needed: this sets the zero
rem  to 0 / 0 (in the view frame). Shoot at a few things, near and far, with the rifle
rem  canted both ways. Hits on the cross = the zero is gone for good.
rem  CROSSHAIR-FROM-JOINT-POSE.bat puts last night's setting back.
rem  Works while the game is running.
rem ---------------------------------------------------------------------------
setlocal
if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)
> "%~dp0reframework\data\re_scope_drawpose.txt" echo 1
> "%~dp0reframework\data\re_scope_zeroframe.txt" echo 1
> "%~dp0reframework\data\re_scope_cmd.txt" echo zeroup 0
>> "%~dp0reframework\data\re_scope_cmd.txt" echo zeroright 0
echo.
echo   Crosshair maths now uses the pose the picture was DRAWN from. Zero set to 0 / 0.
echo.
timeout /t 3 /nobreak >nul 2>&1
