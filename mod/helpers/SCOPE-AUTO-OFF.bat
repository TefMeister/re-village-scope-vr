@echo off
rem ---------------------------------------------------------------------------
rem  SCOPE AUTO-START OFF  (2026-09-24)
rem  Back to the old way: run VR-TRUE-SCOPE.bat with the rifle in hand.
rem  This is the default.
rem  Works while the game is running, and is remembered for next time.
rem ---------------------------------------------------------------------------
setlocal
if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)
> "%~dp0reframework\data\re_scope_autostart.txt" echo 0
echo.
echo   Scope auto-start is OFF.
echo   Use VR-TRUE-SCOPE.bat to start the scope, as before.
echo.
timeout /t 5 /nobreak >nul 2>&1
