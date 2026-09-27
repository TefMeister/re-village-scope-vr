@echo off
rem ---------------------------------------------------------------------------
rem  EYE LOCK ON  (2026-09-22 evening -- the flicker fix; this is the default)
rem  The scope map keeps one eye's projection and ignores reads from the other eye.
rem  Works while the game is running.
rem ---------------------------------------------------------------------------
setlocal
if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)
> "%~dp0reframework\data\re_scope_eyelock.txt" echo 1
echo.
echo   Eye lock is ON.
echo.
timeout /t 3 /nobreak >nul 2>&1
