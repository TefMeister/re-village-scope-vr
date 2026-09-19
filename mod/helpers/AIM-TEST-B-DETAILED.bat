@echo off
rem ---------------------------------------------------------------------------
rem  AIM TEST B -- the DETAILED aiming maths (what the mod uses today).
rem
rem  The other half of the pair. See AIM-TEST-A-SIMPLE.bat for why the two are
rem  being compared. This is the one currently shipped, and the one measured
rem  cutting the picture from (0.735, 0.064) - very near the top edge of the frame.
rem
rem  Run this to go back to normal after testing A.
rem ---------------------------------------------------------------------------
setlocal

if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)

echo geom 1> "%~dp0reframework\data\re_scope_cmd.txt"
echo.
echo   Switched back to the DETAILED aiming maths (the normal one).
echo   Look through the scope. Where does it point?
echo.
timeout /t 3 /nobreak >nul 2>&1
