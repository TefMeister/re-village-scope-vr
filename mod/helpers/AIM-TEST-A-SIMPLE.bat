@echo off
rem ---------------------------------------------------------------------------
rem  AIM TEST A -- the SIMPLE aiming maths.
rem
rem  The mod works out where to cut the scope picture from in two different ways,
rem  and on 2026-09-19 they were found to disagree badly - by about a quarter of
rem  the whole frame, vertically, at the same instant:
rem
rem      the detailed one (in use):  cut from (0.735, 0.064)
rem      the simple one:             cut from (0.576, 0.361)
rem
rem  (0.5, 0.5) is dead centre, so the detailed one is cutting from very near the
rem  top edge - which is what "aimed lower and to the left" looks like, and why the
rem  streak arrives so easily.
rem
rem  This switches to the SIMPLE one. Run AIM-TEST-B-DETAILED.bat to switch back.
rem  Look through the scope after each and say which aims closer to where you are
rem  really pointing.
rem
rem  NOTE: the simple one also drops the stretch/skew correction, so the picture
rem  may look slightly distorted. Ignore that - judge only WHERE IT POINTS.
rem ---------------------------------------------------------------------------
setlocal

if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)

echo geom 0> "%~dp0reframework\data\re_scope_cmd.txt"
echo.
echo   Switched to the SIMPLE aiming maths.
echo   Look through the scope. Where does it point?
echo.
timeout /t 3 /nobreak >nul 2>&1
