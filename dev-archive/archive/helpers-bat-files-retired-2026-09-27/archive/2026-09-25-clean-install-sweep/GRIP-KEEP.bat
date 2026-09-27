@echo off
rem ---------------------------------------------------------------------------
rem  TWO-HANDED GRIP: putting the second hand on the rifle does NOT move it.
rem  This is the default after UPDATE-VR-FRAMEWORK.bat - run it only to come back
rem  from GRIP-SNAP.bat. Works while the game is running.
rem ---------------------------------------------------------------------------
setlocal
if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)
> "%~dp0reframework\data\re_scope_cmd.txt" echo fn grip_keep
echo.
echo   Grip: taking the grip does NOT move the rifle.
echo.
timeout /t 2 /nobreak >nul 2>&1
