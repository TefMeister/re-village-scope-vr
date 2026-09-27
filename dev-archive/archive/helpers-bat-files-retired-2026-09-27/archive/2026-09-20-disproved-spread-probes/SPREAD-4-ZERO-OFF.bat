@echo off
rem ---------------------------------------------------------------------------
rem  Give the game its own bullet scatter back, so hip fire is inaccurate again.
rem  Only needed to compare with and without.
rem
rem  Run it while the game is up, then say so.
rem ---------------------------------------------------------------------------
setlocal

if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)

> "%~dp0reframework\data\re_spread_kill_cmd.txt" echo zero off

echo.
echo   Sent: zero off
echo   The game's own scatter is back.
echo.
timeout /t 2 /nobreak >nul 2>&1
