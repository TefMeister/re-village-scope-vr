@echo off
rem ---------------------------------------------------------------------------
rem  GRIP: 25-DEGREE STEERING LIMIT (the old guard)  -- the left hand cannot swing
rem  the rifle more than 25 degrees off the right hand's aim. GRIP-LIMIT-OFF.bat
rem  is the default. Works while running.
rem ---------------------------------------------------------------------------
setlocal
if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)
> "%~dp0reframework\data\re_scope_cmd.txt" echo fn grip_limit_25
echo.
echo   Grip: steering limited to 25 degrees (old guard).
echo.
timeout /t 2 /nobreak >nul 2>&1
