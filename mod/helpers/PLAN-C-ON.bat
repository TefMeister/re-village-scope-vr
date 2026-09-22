@echo off
rem ---------------------------------------------------------------------------
rem  PLAN C ON  (puts back the setting used since 2026-09-12)
rem  The scope mirror is drawn from the GAME'S OWN camera again.
rem  The game must be CLOSED (it rewrites re2_fw_config.txt on exit).
rem ---------------------------------------------------------------------------
setlocal
tasklist /FI "IMAGENAME eq re8.exe" 2>nul | find /I "re8.exe" >nul
if not errorlevel 1 (
  echo.
  echo   THE GAME IS STILL RUNNING. Close it first, then run this again.
  echo.
  pause
  exit /b 1
)
set "CFG=%~dp0re2_fw_config.txt"
if not exist "%CFG%" (
  echo re2_fw_config.txt not found beside this file.
  pause
  exit /b 1
)
copy /y "%CFG%" "%CFG%.pre-plan-c-on" >nul
powershell -NoProfile -Command "$p='%CFG%'; $t=[IO.File]::ReadAllText($p); $t=$t -replace 'VR_MirrorUsesOriginalCamera=false','VR_MirrorUsesOriginalCamera=true'; [IO.File]::WriteAllText($p,$t)"
findstr /C:"VR_MirrorUsesOriginalCamera=true" "%CFG%" >nul && (
  echo.
  echo   Plan C is ON again (the setting used since 09-12). Start the game.
  echo.
) || (
  echo.
  echo   Could not change the setting. Nothing was changed.
  echo.
)
timeout /t 4 /nobreak >nul 2>&1
