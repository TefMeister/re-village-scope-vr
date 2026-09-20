@echo off
rem ---------------------------------------------------------------------------
rem  TRY THIS FIRST. Do not let the game scatter the bullet at all.
rem
rem  The scattering step sits between "make the bullet" and "finish the bullet",
rem  so skipping it should leave the shot on the direction it was made with.
rem
rem  If the rifle STOPS FIRING, or shoots at some fixed spot, then that step does
rem  more than scatter - say so and use SPREAD-6-SPEC-ON.bat instead.
rem  SPREAD-7-ALL-OFF.bat puts everything back.
rem
rem  Needs the rifle in hand. Run it while the game is up, then say so.
rem ---------------------------------------------------------------------------
setlocal

if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)

> "%~dp0reframework\data\re_spread_kill_cmd.txt" echo skip on

echo.
echo   Sent: skip on
echo   Now fire five shots from the HIP, without holding aim.
echo.
timeout /t 2 /nobreak >nul 2>&1
