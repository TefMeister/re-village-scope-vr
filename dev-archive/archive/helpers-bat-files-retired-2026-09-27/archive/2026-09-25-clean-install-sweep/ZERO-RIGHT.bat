@echo off
rem ---------------------------------------------------------------------------
rem  ZEROING: nudge the picture RIGHT by 2 degrees.
rem
rem  ZEROING moves the scope PICTURE so that what the crosshair sits on is what
rem  the bullet actually hits. It does not change where the rifle shoots - it
rem  changes where the scope says it is shooting.
rem
rem  + up / + right are as YOU see them in the headset.
rem
rem  ⚠ The shipped values (up 14.4, right 9.5) were measured on 2026-09-13 under
rem  the OLD mirror pose. That pose changed on 2026-09-18 - the viewpoint moved
rem  from about a metre below your head to exactly at your eye - so the old zero
rem  is very likely wrong now. That is the suspected cause of "aimed lower and
rem  to the left". Re-zeroing is the fix.
rem
rem  Steps: READ-ME-ZEROING.txt, in this folder.
rem ---------------------------------------------------------------------------
setlocal

if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)

> "%~dp0reframework\data\re_scope_cmd.txt" echo dzeroright 2

echo.
echo   Nudged RIGHT 2 degrees. Run it again for another 2.
echo.
timeout /t 2 /nobreak >nul 2>&1
