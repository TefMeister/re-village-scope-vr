@echo off
rem ---------------------------------------------------------------------------
rem  EYE LOCK OFF  (2026-09-22 evening -- the flicker fix, switched off for comparison)
rem  The one-frame flicker was the scope map being built, for one frame, from the
rem  OTHER eye's projection. The eye lock keeps one eye and ignores the other.
rem  This turns it OFF (the old behaviour, flicker expected back). EYE-LOCK-ON.bat
rem  turns it on again. Works while the game is running.
rem ---------------------------------------------------------------------------
setlocal
if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)
> "%~dp0reframework\data\re_scope_eyelock.txt" echo 0
echo.
echo   Eye lock is OFF. The flicker should be back. EYE-LOCK-ON.bat brings the fix back.
echo.
timeout /t 3 /nobreak >nul 2>&1
