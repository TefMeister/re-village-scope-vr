@echo off
rem ---------------------------------------------------------------------------
rem  LOOK ONLY - changes nothing in the game.
rem
rem  Cancelling the scatter where I was cancelling it provably works on the numbers
rem  and provably does nothing to the bullet, because the bullet is already made by
rem  the time that step runs. So this looks one step earlier instead of guessing
rem  again: it writes down every value the game hands to the three steps that make
rem  a shot, and marks which ones are directions.
rem
rem  ONE shot with the aim button HELD, then ONE from the HIP. Two shots is enough.
rem  Whichever direction differs between them is the one that carries the scatter,
rem  and that is where the fix belongs.
rem
rem  It stops recording itself after six shots, so it cannot fill the log.
rem  RIFLE-STRAIGHT-OFF.bat when you are done.
rem ---------------------------------------------------------------------------
setlocal

if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)

> "%~dp0reframework\data\re_scope_spread.txt" echo 3 0

echo.
echo   Sent: look only (mode 3). Nothing in the game is changed.
echo   Now ONE shot with aim HELD, then ONE from the HIP.
echo.
timeout /t 2 /nobreak >nul 2>&1
