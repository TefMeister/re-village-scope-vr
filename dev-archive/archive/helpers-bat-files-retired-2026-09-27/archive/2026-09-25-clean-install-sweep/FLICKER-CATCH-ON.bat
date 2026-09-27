@echo off
rem ---------------------------------------------------------------------------
rem  FLICKER CATCH ON  (2026-09-22 evening)
rem  The plugin keeps the last 90 scope pictures (1.25 s). When you SEE a flicker,
rem  pull the trigger straight away: all 90 pictures from just before that shot are
rem  written to reframework\data\flicker-ring-N\ so Claude can find the odd frame.
rem  Up to 4 catches per launch. Also turns the change measure on (hold 1) so each
rem  saved picture carries its numbers.
rem  Works while the game is running. FLICKER-CATCH-OFF.bat turns it off.
rem ---------------------------------------------------------------------------
setlocal
if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)
> "%~dp0reframework\data\re_scope_ring.txt" echo 1
> "%~dp0reframework\data\re_scope_cmd.txt" echo hold 1
echo.
echo   Flicker catch is ON. Look through the scope, hold still. The moment you see a
echo   flicker, pull the trigger. Do that up to four times, then run FLICKER-CATCH-OFF.
echo.
timeout /t 3 /nobreak >nul 2>&1
