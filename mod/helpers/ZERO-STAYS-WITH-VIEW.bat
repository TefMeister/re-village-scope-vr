@echo off
rem ---------------------------------------------------------------------------
rem  ZERO FIXED TO YOUR VIEW (new, 2026-09-21): tilting the rifle sideways no longer moves the zero.
rem  Starts from the zero you made today, as you SAW it (up -10.9, right -9.2). Nudge from there
rem  with the usual ZERO-UP / DOWN / LEFT / RIGHT files. Works while the game is running.
rem ---------------------------------------------------------------------------
setlocal
if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)
> "%~dp0reframework\data\re_scope_zeroframe.txt" echo 1
> "%~dp0reframework\data\re_scope_cmd.txt" echo zeroup -10.9
>> "%~dp0reframework\data\re_scope_cmd.txt" echo zeroright -9.2
echo.
echo   Zero is now fixed to your view (up -10.9, right -9.2).
echo.
timeout /t 3 /nobreak >nul 2>&1
