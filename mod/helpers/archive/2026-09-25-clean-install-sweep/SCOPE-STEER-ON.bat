@echo off
rem ---------------------------------------------------------------------------
rem  Scope steering ON.
rem  Swaps in the REFramework build that can AIM the scope's picture at the
rem  barrel instead of drawing it wider, and switches the option on.
rem  Undo with SCOPE-STEER-OFF.bat. The game must be CLOSED.
rem ---------------------------------------------------------------------------
setlocal

tasklist /fi "imagename eq re8.exe" 2>nul | find /i "re8.exe" >nul
if not errorlevel 1 (
  echo.
  echo   The game is still running. Close Resident Evil Village first,
  echo   then run this again.
  echo.
  pause
  exit /b 1
)

rem  Points at the build that also carries SHOUT mode (2026-09-19) - the diagnostic that
rem  answers whether this projection reaches the scope picture at all. Steering itself is
rem  unchanged; the previous build is still on disk under its own name if it is ever wanted.
set "SRC=D:\RE2 REFramework builds\dinput8_pd-upscaler_76298bd_mirror-steering-plus-shout_2026-09-19_NOT-YET-TESTED.dll"
set "DST=%~dp0dinput8.dll"
set "BAK=%~dp0Backup\scope-2026-09-19-pre-steering"

if not exist "%SRC%" (
  echo   Cannot find the steering build:
  echo   %SRC%
  pause
  exit /b 1
)

if not exist "%~dp0scope-steer-config.ps1" (
  echo   Cannot find scope-steer-config.ps1 next to this script.
  pause
  exit /b 1
)

if not exist "%BAK%" mkdir "%BAK%"
if not exist "%BAK%\dinput8.dll" copy /y "%DST%" "%BAK%\dinput8.dll" >nul
if not exist "%BAK%\re2_fw_config.txt" copy /y "%~dp0re2_fw_config.txt" "%BAK%\re2_fw_config.txt" >nul

copy /y "%SRC%" "%DST%" >nul
if errorlevel 1 (
  echo   Could not replace dinput8.dll. Is the game really closed?
  pause
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scope-steer-config.ps1" -ConfigPath "%~dp0re2_fw_config.txt" -Mode on
if errorlevel 1 (
  echo.
  echo   THE SETTING DID NOT GET WRITTEN - see the error above.
  echo   The new build IS in place, but steering will be OFF until this works.
  echo.
  pause
  exit /b 1
)

echo.
echo   STEERING IS ON.
echo.
echo   The old build and config are saved in:
echo     Backup\scope-2026-09-19-pre-steering
echo.
echo   In game, open the REFramework menu (Insert) - VR, and look for
echo     "Steer Mirror Projection (scope, fix 1b)"
echo   Drag "Manual steer yaw (deg)" left and right and watch whether the
echo   scope picture moves. If it moves the WRONG way, tick
echo     "Invert steer sign".
echo.
pause
