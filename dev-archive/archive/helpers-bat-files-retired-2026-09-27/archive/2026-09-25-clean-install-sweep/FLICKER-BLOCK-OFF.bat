@echo off
rem ---------------------------------------------------------------------------
rem  FLICKER BLOCK OFF: back to normal.
rem ---------------------------------------------------------------------------
setlocal
if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)
> "%~dp0reframework\data\re_scope_cmd.txt" echo hold 0
>> "%~dp0reframework\data\re_scope_cmd.txt" echo holdt 0.08
echo.
echo   Flicker block OFF.
echo.
timeout /t 3 /nobreak >nul 2>&1
