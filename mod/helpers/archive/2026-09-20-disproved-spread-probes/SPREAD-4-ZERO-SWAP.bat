@echo off
rem ---------------------------------------------------------------------------
rem  THE OTHER WAY ROUND. Only needed if SPREAD-4-ZERO-ON.bat sent shots flying
rem  off at random instead of straight.
rem
rem  The game hands the shot two rotations and we cancel the scatter by making one
rem  equal the other. On an aimed shot they are identical, so the log cannot tell
rem  which of the two is the one you are pointing at. This tries the other choice.
rem
rem  Run it while the game is up, fire from the hip, then say which way worked.
rem ---------------------------------------------------------------------------
setlocal

if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)

> "%~dp0reframework\data\re_spread_kill_cmd.txt" echo zero swap

echo.
echo   Sent: zero swap
echo   Fire from the hip again and say which of the two went straight.
echo.
timeout /t 2 /nobreak >nul 2>&1
