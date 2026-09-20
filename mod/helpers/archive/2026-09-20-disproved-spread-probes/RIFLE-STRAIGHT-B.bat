@echo off
rem ---------------------------------------------------------------------------
rem  THE OTHER ONE. Only needed if RIFLE-STRAIGHT-A.bat gave random shots.
rem
rem  The game hands each shot two directions and we make them the same. A keeps
rem  the first, this keeps the second. On an aimed shot the two are identical, so
rem  no log anywhere can tell which is which - firing once each way can.
rem
rem  Works instantly - no restart. Only affects the scoped rifle.
rem  RIFLE-STRAIGHT-OFF.bat puts it back.
rem ---------------------------------------------------------------------------
setlocal

if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)

> "%~dp0reframework\data\re_scope_spread.txt" echo 2 0

echo.
echo   Sent: keep the SECOND direction (mode 2), scoped rifle only.
echo   Fire a few shots from the HIP and say which of A or B went straight.
echo.
timeout /t 2 /nobreak >nul 2>&1
