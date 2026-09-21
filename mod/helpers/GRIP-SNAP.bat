@echo off
rem ---------------------------------------------------------------------------
rem  TWO-HANDED GRIP: the ORIGINAL behaviour, for comparison - the rifle re-aims
rem  itself the instant the second hand goes on (the "throw to the left").
rem  GRIP-KEEP.bat puts ours back. Works while the game is running.
rem ---------------------------------------------------------------------------
setlocal
if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)
> "%~dp0reframework\data\re_scope_cmd.txt" echo fn grip_snap
echo.
echo   Grip: ORIGINAL behaviour - the rifle jumps when the second hand goes on.
echo.
timeout /t 2 /nobreak >nul 2>&1
