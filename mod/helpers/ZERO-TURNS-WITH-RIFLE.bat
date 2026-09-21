@echo off
rem ---------------------------------------------------------------------------
rem  ZERO TURNS WITH THE RIFLE: the old behaviour, for comparison (up -10.7, right -9.5).
rem ---------------------------------------------------------------------------
setlocal
if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)
> "%~dp0reframework\data\re_scope_zeroframe.txt" echo 0
> "%~dp0reframework\data\re_scope_cmd.txt" echo zeroup -10.7
>> "%~dp0reframework\data\re_scope_cmd.txt" echo zeroright -9.5
echo.
echo   Zero turns with the rifle again (old behaviour).
echo.
timeout /t 3 /nobreak >nul 2>&1
