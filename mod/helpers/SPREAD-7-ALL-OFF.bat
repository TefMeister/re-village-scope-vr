@echo off
rem ---------------------------------------------------------------------------
rem  Put everything back: the game scatters its bullets as it always did.
rem  Use this between tries so two changes are never on at once.
rem
rem  Run it while the game is up, then say so.
rem ---------------------------------------------------------------------------
setlocal

if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)

> "%~dp0reframework\data\re_spread_kill_cmd.txt" (
echo skip off
echo spec off
echo zero off
)

echo.
echo   Sent: skip off / spec off / zero off
echo   The game's own scatter is back.
echo.
timeout /t 2 /nobreak >nul 2>&1
