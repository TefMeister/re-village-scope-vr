@echo off
rem ---------------------------------------------------------------------------
rem  DIG into where the bullet spread comes from.  READ-ONLY - changes nothing.
rem
rem  Dumps every field and method of the six game types most likely to hold or
rem  apply the sniper's spread, with NO name filter. The 2026-09-17 probe searched
rem  by name and found nothing, which only rules out the names it guessed.
rem
rem  Safe to run any time the game is up. Output goes to the REFramework log,
rem  every line marked [spread-dig]. Numeric fields are marked >>.
rem
rem  Run it, then say so - the log gets read from here.
rem ---------------------------------------------------------------------------
setlocal

if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)

> "%~dp0reframework\data\re_spread_dig_cmd.txt" echo dig all

echo.
echo   Dig requested. It runs within a second and writes to the log.
echo   Nothing in the game is changed.
echo.
timeout /t 3 /nobreak >nul 2>&1
