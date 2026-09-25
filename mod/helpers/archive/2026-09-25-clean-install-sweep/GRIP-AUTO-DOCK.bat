@echo off
rem ---------------------------------------------------------------------------
rem  GRIP: AUTO-DOCK (the old behaviour)  -- the left hand docks by itself when it
rem  comes within 10 cm of the forestock, no button needed, and steers the rifle
rem  while docked. GRIP-BUTTON-ONLY.bat is the new default. Works while running.
rem ---------------------------------------------------------------------------
setlocal
if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)
> "%~dp0reframework\data\re_scope_cmd.txt" echo fn grip_auto_dock
echo.
echo   Grip: the hand docks by itself near the forestock (old behaviour).
echo.
timeout /t 2 /nobreak >nul 2>&1
