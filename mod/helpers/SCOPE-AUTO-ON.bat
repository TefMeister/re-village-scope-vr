@echo off
rem ---------------------------------------------------------------------------
rem  SCOPE AUTO-START ON  (2026-09-24)
rem  The scope sets itself up the moment the sniper rifle is in your hands:
rem  no VR-TRUE-SCOPE.bat needed. Do NOT run VR-TRUE-SCOPE.bat as well.
rem  Works while the game is running, and is remembered for next time.
rem ---------------------------------------------------------------------------
setlocal
if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)
> "%~dp0reframework\data\re_scope_autostart.txt" echo 1
echo.
echo   Scope auto-start is ON.
echo   Take the sniper rifle out and give it about 10 seconds.
echo   Do NOT also run VR-TRUE-SCOPE.bat while this is on.
echo.
timeout /t 5 /nobreak >nul 2>&1
