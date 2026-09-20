@echo off
rem ---------------------------------------------------------------------------
rem  TRY THIS FIRST. Make the sniper rifle shoot where it points, from the hip.
rem
rem  This one is in our own compiled code, not the script - which matters, because
rem  the script physically could not write the number. Here it can, and it says so
rem  in the log either way:
rem
rem      "scatter 8.4 -> 0.000 deg  mode=1 APPLIED"   the shot goes where you point
rem      "WARNING -- the write did not take"          it did nothing, and we know
rem
rem  Works instantly - no restart. Only affects the scoped rifle.
rem
rem  If shots come out RANDOM rather than straight, run RIFLE-STRAIGHT-B.bat: the
rem  game hands the shot two directions and this keeps one of them; B keeps the
rem  other. One of the two is right. RIFLE-STRAIGHT-OFF.bat puts it back.
rem ---------------------------------------------------------------------------
setlocal

if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)

> "%~dp0reframework\data\re_scope_spread.txt" echo 1 0

echo.
echo   Sent: keep the FIRST direction (mode 1), scoped rifle only.
echo   Fire a few shots from the HIP, without holding aim.
echo.
timeout /t 2 /nobreak >nul 2>&1
