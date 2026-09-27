@echo off
rem ---------------------------------------------------------------------------
rem  STOP GUESSING - WATCH INSTEAD. This changes nothing in the game.
rem
rem  Three attempts at switching the scatter off have now failed, each one a guess
rem  about where the game decides it. This records the whole firing sequence in
rem  order, plus what the rifle's data sheet actually answers when asked how wide
rem  to scatter.
rem
rem  Then: ONE shot holding aim, ONE shot from the hip. Aiming gives no scatter and
rem  the hip gives eight degrees of it, so the difference between those two
rem  recordings is the answer, whatever it turns out to be.
rem
rem  READ-ONLY, and it stops itself after 400 lines so it cannot flood anything.
rem  Needs the rifle in hand and a couple of bullets. Run it, fire the two shots,
rem  then say so.
rem ---------------------------------------------------------------------------
setlocal

if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)

> "%~dp0reframework\data\re_spread_kill_cmd.txt" echo trace on

echo.
echo   Sent: trace on
echo   Now ONE shot with the aim button HELD, then ONE shot from the HIP.
echo   Two shots is enough. Nothing in the game is changed.
echo.
timeout /t 2 /nobreak >nul 2>&1
