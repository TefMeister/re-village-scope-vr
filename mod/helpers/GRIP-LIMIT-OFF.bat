@echo off
rem ---------------------------------------------------------------------------
rem  GRIP: NO STEERING LIMIT (the default since 2026-09-22)  -- the left hand can
rem  swing the rifle as far as it likes. GRIP-LIMIT-25.bat puts the old 25-degree
rem  guard back. Works while running.
rem ---------------------------------------------------------------------------
setlocal
if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)
> "%~dp0reframework\data\re_scope_cmd.txt" echo fn grip_limit_off
echo.
echo   Grip: no steering limit (default).
echo.
timeout /t 2 /nobreak >nul 2>&1
