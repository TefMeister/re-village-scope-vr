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

set "SRC=D:\RE2 REFramework builds\dinput8_pd-upscaler_76298bd_mirror-steering_2026-09-19_NOT-YET-TESTED.dll"
set "DST=%~dp0dinput8.dll"
set "BAK=%~dp0Backup\scope-2026-09-19-pre-steering"

if not exist "%SRC%" (
  echo   Cannot find the steering build:
  echo   %SRC%
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

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$p='%~dp0re2_fw_config.txt';" ^
  "$want=@{'VR_SteerMirrorProjection'='true';'VR_MirrorSteerFromPlugin'='false';'VR_MirrorSteerYaw'='0.000000';'VR_MirrorSteerPitch'='0.000000';'VR_MirrorSteerInvert'='false';'VR_SteerMirrorFromNative'='false'};" ^
  "$lines=Get-Content $p;" ^
  "foreach($k in $want.Keys){ $hit=$false; $lines=$lines ^| ForEach-Object { if($_ -like ($k+'=*')){ $hit=$true; $k+'='+$want[$k] } else { $_ } }; if(-not $hit){ $lines+=($k+'='+$want[$k]) } };" ^
  "Set-Content -Path $p -Value $lines -Encoding ASCII"

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
