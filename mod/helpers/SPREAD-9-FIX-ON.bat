@echo off
rem ---------------------------------------------------------------------------
rem  THE FIX THAT CHECKS ITSELF.
rem
rem  It writes the barrel's own direction over the scattered one, then reads it back
rem  and measures again. So the log says whether it worked before you even look at
rem  where the bullets went:
rem
rem     "scatter after the write = 0.000 deg"   -> it landed
rem     "THE WRITE DID NOT LAND"                -> it did not, and we move on
rem
rem  It also works out by itself which of the two directions is the one you are
rem  pointing, by comparing both against the rifle's muzzle. No more guessing at it.
rem
rem  SPREAD-7-ALL-OFF.bat puts everything back.
rem  Needs the rifle in hand and a couple of bullets. Run it, fire from the HIP,
rem  then say so.
rem ---------------------------------------------------------------------------
setlocal

if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)

> "%~dp0reframework\data\re_spread_kill_cmd.txt" (
echo trace on
echo fix on
)

echo.
echo   Sent: trace on / fix on
echo   Now fire three or four shots from the HIP, without holding aim.
echo.
timeout /t 2 /nobreak >nul 2>&1
