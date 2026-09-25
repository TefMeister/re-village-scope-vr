@echo off
rem ---------------------------------------------------------------------------
rem  FRONT HAND: HALF
rem  How much the LEFT hand steers the rifle. Works while the game is running.
rem  FULL = as always.  HALF = half strength, so tracking slide moves it half as
rem  much.  LOCKED = the rifle follows the right hand only; the left hand is still
rem  drawn on the rifle but cannot move it, so slide cannot either.
rem  Resets to FULL when the game restarts, until one is chosen as the default.
rem ---------------------------------------------------------------------------
setlocal
if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)
> "%~dp0reframework\data\re_scope_cmd.txt" echo fn grip_front_half
echo.
echo   Front hand: HALF.
echo.
timeout /t 2 /nobreak >nul 2>&1
