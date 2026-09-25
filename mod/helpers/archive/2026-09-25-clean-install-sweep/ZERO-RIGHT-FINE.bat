@echo off
rem ---------------------------------------------------------------------------
rem  ZEROING, FINE: nudge the picture RIGHT by 0.4 degrees.
rem
rem  A FIFTH of the step the plain ZERO-RIGHT.bat uses. Asked for on 2026-09-20,
rem  once the coarse pass had got close: "the zero and direction have to be in 5x
rem  smaller increments to fine tune now".
rem
rem  Five clicks of this equals one click of the coarse one, so you can keep
rem  using both - coarse to get near, fine to land it.
rem
rem  Steps: READ-ME-ZEROING.txt, in this folder.
rem ---------------------------------------------------------------------------
setlocal

if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)

> "%~dp0reframework\data\re_scope_cmd.txt" echo dzeroright 0.4

echo.
echo   Fine nudge RIGHT 0.4 degrees.
echo.
timeout /t 2 /nobreak >nul 2>&1
