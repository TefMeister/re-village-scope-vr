@echo off
rem ---------------------------------------------------------------------------
rem  TWO-HANDED SHOTS: SEND THE BULLET WHERE YOU WERE AIMING.
rem
rem  Holding the rifle with both hands, the gun jumps a little to the left just before
rem  the bullet leaves, and the bullet used to follow the jump. With this ON the bullet
rem  takes its direction from two frames earlier - what the crosshair was on when you
rem  pulled the trigger. One-handed shots are not affected. ON is the default.
rem
rem  Works instantly, no restart. TWO-HAND-FIX-OFF.bat undoes it.
rem ---------------------------------------------------------------------------
setlocal

if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)

> "%~dp0reframework\data\re_scope_prejump.txt" echo 2

echo.
echo   Sent: ON.
echo.
timeout /t 2 /nobreak >nul 2>&1
