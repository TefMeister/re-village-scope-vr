@echo off
rem ---------------------------------------------------------------------------
rem  Hold the rifle steady: tell the gun to restrict its own aim shake and reduce
rem  its own recoil, re-asserted every frame.
rem
rem  This is the first thing in this project that WRITES to the gun. It only calls
rem  two switches the game already has; it invents nothing and patches no code.
rem  SPREAD-3-STEADY-OFF.bat stops it, and a weapon change reverts it anyway.
rem
rem  Needs the rifle equipped and one shot fired first, so the tool has hold of it.
rem  Run it while the game is up, then say so - the log gets read from here.
rem ---------------------------------------------------------------------------
setlocal

if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)

> "%~dp0reframework\data\re_spread_kill_cmd.txt" echo steady on

echo.
echo   Sent: steady on
echo   Now fire from the hip WITHOUT holding aim, and see where the bullets land.
echo.
timeout /t 2 /nobreak >nul 2>&1
