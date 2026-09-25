@echo off
rem ---------------------------------------------------------------------------
rem  ZEROING: show the current values without changing them.
rem
rem  Sends a nudge of ZERO degrees. The mod logs the values on every zero command,
rem  so a nudge of nothing prints them and moves nothing - which is exactly what
rem  was missing when ZERO-B was mistaken for a save button.
rem
rem  The line appears in the mod's log as:   zero: up <n> right <n>
rem  Ask and the values get read out and, if you want, written in permanently.
rem ---------------------------------------------------------------------------
setlocal

if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)

> "%~dp0reframework\data\re_scope_cmd.txt" echo dzeroup 0

echo.
echo   Current zero written to the log. Nothing was changed.
echo.
timeout /t 2 /nobreak >nul 2>&1
