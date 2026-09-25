@echo off
rem ---------------------------------------------------------------------------
rem  Back to the old behaviour: the scope picture aims at a fixed 50 metres.
rem  Your saved zero was made this way, so this is the known-good state.
rem ---------------------------------------------------------------------------
setlocal

if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)

> "%~dp0reframework\data\re_scope_aimdist.txt" echo 0

echo.
echo   Sent: off. The picture aims at a fixed 50 metres again.
echo.
timeout /t 2 /nobreak >nul 2>&1
