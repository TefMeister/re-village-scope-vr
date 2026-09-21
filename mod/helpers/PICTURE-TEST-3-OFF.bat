@echo off
rem ---------------------------------------------------------------------------
rem  PICTURE TEST, step 3: everything back to normal.
rem ---------------------------------------------------------------------------
setlocal
if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)
> "%~dp0reframework\data\re_scope_cmd.txt" echo cropfollow 1
>> "%~dp0reframework\data\re_scope_cmd.txt" echo hold 0
echo.
echo   Picture test OFF. Everything is back to normal.
echo.
timeout /t 3 /nobreak >nul 2>&1
