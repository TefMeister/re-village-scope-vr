@echo off
rem ---------------------------------------------------------------------------
rem  DRIFT GUARD OFF. While the headset says it cannot SEE the left controller,
rem  the front of the rifle is left to follow it anyway (for comparison).
rem  Works while the game is running. Needs the patched REFramework (dossier 9ch).
rem ---------------------------------------------------------------------------
setlocal
if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)
> "%~dp0reframework\data\re_scope_cmd.txt" echo fn grip_guard_off
echo.
echo   Drift guard: OFF.
echo.
timeout /t 2 /nobreak >nul 2>&1
