@echo off
rem ---------------------------------------------------------------------------
rem  GRIP: BUTTON ONLY (the default since 2026-09-22)  -- the left hand docks ONLY
rem  while the left grip button is held (near the forestock, or stacked above the
rem  right controller), lets go when it is released, and the rifle keeps the right
rem  hand's aim at the moment of the press. Works while running.
rem ---------------------------------------------------------------------------
setlocal
if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)
> "%~dp0reframework\data\re_scope_cmd.txt" echo fn grip_button_only
echo.
echo   Grip: the left grip button is the only way to dock (default).
echo.
timeout /t 2 /nobreak >nul 2>&1
