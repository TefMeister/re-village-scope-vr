@echo off
rem ---------------------------------------------------------------------------
rem  PICTURE TEST, step 1: switch the flicker counter and the rate watch ON.
rem  Play as normal with the scope up. Costs a little performance while it is on.
rem ---------------------------------------------------------------------------
setlocal
if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)
> "%~dp0reframework\data\re_scope_cmd.txt" echo hold 1
echo.
echo   Picture test ON. Look through the scope and play as normal.
echo.
timeout /t 3 /nobreak >nul 2>&1
