@echo off
rem ---------------------------------------------------------------------------
rem  Print every live setting of the rifle in your hands, with its value. READ-ONLY.
rem
rem  Needs the rifle EQUIPPED, and one shot fired first so the tool has hold of it.
rem  Part of the sniper-accuracy work (2026-09-20). The tool is
rem  reframework\autorun\re8_spread_kill.lua and it starts read-only.
rem
rem  Run it while the game is up, then say so - the log gets read from here.
rem ---------------------------------------------------------------------------
setlocal

if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)

> "%~dp0reframework\data\re_spread_kill_cmd.txt" echo read

echo.
echo   Sent: read
echo   It runs within a second and writes to the REFramework log.
echo.
timeout /t 2 /nobreak >nul 2>&1
