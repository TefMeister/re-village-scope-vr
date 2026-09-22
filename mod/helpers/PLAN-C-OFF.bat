@echo off
rem ---------------------------------------------------------------------------
rem  PLAN C OFF  (2026-09-22 evening test)
rem  The scope picture is drawn by a "mirror". Since 09-12 that mirror has been drawn
rem  from the GAME'S OWN camera (plan C), which today drifted 30-50 degrees away from
rem  where the headset looks -- and then the picture turns over. With plan C OFF the
rem  mirror is drawn from the HEADSET pose instead, which is where the scope is.
rem  This edits re2_fw_config.txt, so the game must be CLOSED (it rewrites that file
rem  on exit). Run it, then start the game. PLAN-C-ON.bat puts it back.
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
copy /y "%CFG%" "%CFG%.pre-plan-c-off" >nul
powershell -NoProfile -Command "$p='%CFG%'; $t=[IO.File]::ReadAllText($p); $t=$t -replace 'VR_MirrorUsesOriginalCamera=true','VR_MirrorUsesOriginalCamera=false'; [IO.File]::WriteAllText($p,$t)"
findstr /C:"VR_MirrorUsesOriginalCamera=false" "%CFG%" >nul && (
  echo.
  echo   Plan C is OFF: the scope picture will be drawn from the headset pose. Start the game.
  echo.
) || (
  echo.
  echo   Could not change the setting. Nothing was changed.
  echo.
)
timeout /t 4 /nobreak >nul 2>&1
