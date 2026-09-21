@echo off
rem ---------------------------------------------------------------------------
rem  PICTURE SYNC ON (the default): the scope picture and the zoom window are kept in step,
rem  frame for frame. This is the fix being tested for the flicker and the head-turn stepping.
rem  Works while the game is running (takes about a second to be noticed).
rem ---------------------------------------------------------------------------
setlocal
if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)
> "%~dp0reframework\data\re_scope_sync.txt" echo 1
echo.
echo   Picture sync ON.
echo.
timeout /t 3 /nobreak >nul 2>&1
