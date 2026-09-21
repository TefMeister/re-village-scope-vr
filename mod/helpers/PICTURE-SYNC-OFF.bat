@echo off
rem ---------------------------------------------------------------------------
rem  PICTURE SYNC OFF: the old behaviour, for comparison only.
rem  Works while the game is running (takes about a second to be noticed).
rem ---------------------------------------------------------------------------
setlocal
if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)
> "%~dp0reframework\data\re_scope_sync.txt" echo 0
echo.
echo   Picture sync OFF - old behaviour.
echo.
timeout /t 3 /nobreak >nul 2>&1
