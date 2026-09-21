@echo off
rem ---------------------------------------------------------------------------
rem  WHICH POINT OF THE LEFT HAND STEERS THE RIFLE: HAND POINT
rem  HAND POINT = the original: a point 16 cm out along the left controller, which
rem               swings with every twist of the left wrist.
rem  CONTROLLER = the controller's own position: twisting the wrist moves nothing.
rem  Works while the game is running. Resets to HAND POINT on restart until chosen.
rem ---------------------------------------------------------------------------
setlocal
if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)
> "%~dp0reframework\data\re_scope_cmd.txt" echo fn grip_by_handpoint
echo.
echo   Rifle is steered by: HAND POINT.
echo.
timeout /t 2 /nobreak >nul 2>&1
