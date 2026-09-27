@echo off
rem ---------------------------------------------------------------------------
rem  MIRROR LIGHT-WEIGHT MODE OFF  (2026-09-25)
rem  Back to the normal full-quality second camera. This is the default.
rem  Needs a game RESTART to take effect. Remembered for next time.
rem ---------------------------------------------------------------------------
setlocal
if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)
> "%~dp0reframework\data\re_scope_mirror_lw.txt" echo 0
echo.
echo   Mirror light-weight mode is OFF for the next launch (the default).
echo.
timeout /t 5 /nobreak >nul 2>&1
