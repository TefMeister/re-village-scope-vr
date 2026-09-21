@echo off
rem ---------------------------------------------------------------------------
rem  FLICKER BLOCK ON: when the scope picture suddenly shows a different picture for one
rem  frame, the mod shows the previous good frame again instead. Costs a few frames per
rem  second. Works while the game is running. Run it AFTER START-SCOPE.
rem ---------------------------------------------------------------------------
setlocal
if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)
> "%~dp0reframework\data\re_scope_cmd.txt" echo holdt 0.05
>> "%~dp0reframework\data\re_scope_cmd.txt" echo hold 2
echo.
echo   Flicker block ON.
echo.
timeout /t 3 /nobreak >nul 2>&1
