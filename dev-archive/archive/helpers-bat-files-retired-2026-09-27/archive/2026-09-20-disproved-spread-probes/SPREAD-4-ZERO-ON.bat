@echo off
rem ---------------------------------------------------------------------------
rem  CANCEL THE BULLET SCATTER. Hip fire should now land where the rifle points.
rem
rem  Measured 2026-09-20: aiming gives 0.005 degrees of scatter, hip fire gives
rem  8.4 degrees on average and up to 14.9. This cancels it at the moment the game
rem  applies it, so a hip shot leaves along the aim like an aimed one.
rem
rem  If bullets instead fly off at RANDOM, run SPREAD-4-ZERO-SWAP.bat - that tries
rem  it the other way round. SPREAD-4-ZERO-OFF.bat puts the game's scatter back.
rem
rem  Needs the rifle in hand. Run it while the game is up, then say so.
rem ---------------------------------------------------------------------------
setlocal

if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)

> "%~dp0reframework\data\re_spread_kill_cmd.txt" echo zero on

echo.
echo   Sent: zero on
echo   Now fire from the HIP, without holding aim, at something small.
echo.
timeout /t 2 /nobreak >nul 2>&1
