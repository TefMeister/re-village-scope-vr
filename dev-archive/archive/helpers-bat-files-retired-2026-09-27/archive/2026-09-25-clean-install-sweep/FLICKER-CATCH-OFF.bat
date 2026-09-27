@echo off
rem ---------------------------------------------------------------------------
rem  FLICKER CATCH OFF  (2026-09-22 evening)
rem  Stops keeping the last 90 scope pictures and turns the change measure off.
rem  The catches already written stay in reframework\data\flicker-ring-N\.
rem  Works while the game is running.
rem ---------------------------------------------------------------------------
setlocal
if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)
> "%~dp0reframework\data\re_scope_ring.txt" echo 0
> "%~dp0reframework\data\re_scope_cmd.txt" echo hold 0
echo.
echo   Flicker catch is OFF.
echo.
timeout /t 3 /nobreak >nul 2>&1
