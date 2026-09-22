@echo off
rem ---------------------------------------------------------------------------
rem  STACKED GRIP: OFF
rem  Back to the old rule: only the left hand near the forestock takes the grip.
rem  Works while the game is running. STACKED-GRIP-ON.bat turns it back on.
rem ---------------------------------------------------------------------------
setlocal
if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)
> "%~dp0reframework\data\re_scope_cmd.txt" echo fn grip_stacked_off
echo.
echo   Stacked grip: OFF (forestock socket only, as before).
echo.
timeout /t 2 /nobreak >nul 2>&1
