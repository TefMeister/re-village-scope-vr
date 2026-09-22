@echo off
rem ---------------------------------------------------------------------------
rem  STACKED GRIP: ON  (this is the default -- run it only after STACKED-GRIP-OFF)
rem  Hold the LEFT controller a hand's width or so ABOVE the right one. That takes
rem  the two-handed grip on its own: no reaching for the forestock, no button. The
rem  rifle keeps following the RIGHT hand, so it does not point at the sky, and the
rem  left hand is still drawn on the forestock. Both controllers stay where the
rem  headset can see them, so nothing drifts. Works while the game is running.
rem  Zone: 3 to 35 cm above the right controller, within about 12 cm sideways.
rem ---------------------------------------------------------------------------
setlocal
if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)
> "%~dp0reframework\data\re_scope_cmd.txt" echo fn grip_stacked_on
echo.
echo   Stacked grip: ON. Left controller above the right = two-handed, rifle follows the right hand.
echo.
timeout /t 2 /nobreak >nul 2>&1
