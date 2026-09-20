@echo off
rem ---------------------------------------------------------------------------
rem  Stop holding the rifle steady. The game puts its own values back by itself on
rem  the next weapon change, so this is only needed to compare with and without.
rem
rem  Run it while the game is up, then say so - the log gets read from here.
rem ---------------------------------------------------------------------------
setlocal

if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)

> "%~dp0reframework\data\re_spread_kill_cmd.txt" echo steady off

echo.
echo   Sent: steady off
echo   Fire again from the hip - the spread should come back if this was the cause.
echo.
timeout /t 2 /nobreak >nul 2>&1
