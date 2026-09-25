@echo off
rem ---------------------------------------------------------------------------
rem  PICTURE TEST, step 2: stop the scope picture following the rifle for a moment,
rem  so that ONLY your head changes it. Hold the rifle still, turn your head slowly
rem  and smoothly left and right for about 20 seconds, then run step 3.
rem ---------------------------------------------------------------------------
setlocal
if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)
> "%~dp0reframework\data\re_scope_cmd.txt" echo cropfollow 0
echo.
echo   Now: rifle STILL, turn your HEAD slowly left and right for about 20 seconds.
echo.
timeout /t 3 /nobreak >nul 2>&1
