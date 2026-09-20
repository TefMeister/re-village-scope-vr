@echo off
rem ---------------------------------------------------------------------------
rem  Put the rifle back to how the game ships it: hip fire scatters again.
rem  Works instantly - no restart.
rem ---------------------------------------------------------------------------
setlocal

if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)

> "%~dp0reframework\data\re_scope_spread.txt" echo 0 0

echo.
echo   Sent: off. The game's own scatter is back.
echo.
timeout /t 2 /nobreak >nul 2>&1
