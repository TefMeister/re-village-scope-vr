@echo off
rem ---------------------------------------------------------------------------
rem  ZEROING: RESET to the saved defaults (up -16.4, right -10.6).
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
rem
rem  !!!!  THIS DOES NOT SAVE ANYTHING. IT RESETS.  !!!!
rem
rem  On 2026-09-20 this was run expecting it to keep the values just tuned in, and
rem  it threw them away instead - it puts the SAVED defaults back, discarding
rem  whatever was nudged since.
rem
rem  There is no "save" button here and there cannot easily be one: the defaults
rem  live in the mod's start-up script, not in a file a batch file should be
rem  editing. To make a tuned zero permanent, say so and it gets written in.
rem  ZERO-SHOW.bat prints the current values without changing them.
rem
rem ---------------------------------------------------------------------------
setlocal

if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)

> "%~dp0reframework\data\re_scope_cmd.txt" echo zeroup -16.4
>> "%~dp0reframework\data\re_scope_cmd.txt" echo zeroright -10.6

echo.
echo   RESET to the saved zero (up -16.4, right -10.6).
echo.
timeout /t 2 /nobreak >nul 2>&1
