@echo off
rem ---------------------------------------------------------------------------
rem  THE ZERO-SHOT TEST. No target, no bullets, no judging where anything landed.
rem
rem  Print the rifle's steadiness flags right now. Then HOLD THE AIM BUTTON and
rem  let go: the tool prints a FLAG line for anything that changes. If
rem  isRestrictAimShake flips to true while you hold aim, that is the accuracy,
rem  and it can be switched on without aiming at all.
rem
rem  Equipping the rifle is enough for this - nothing has to be fired.
rem  READ-ONLY. Run it while the game is up, then say so.
rem ---------------------------------------------------------------------------
setlocal

if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)

> "%~dp0reframework\data\re_spread_kill_cmd.txt" echo flags

echo.
echo   Sent: flags
echo   Now HOLD THE AIM BUTTON for a second and let go. That is the whole test.
echo.
timeout /t 2 /nobreak >nul 2>&1
