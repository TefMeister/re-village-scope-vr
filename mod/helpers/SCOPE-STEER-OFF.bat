@echo off
rem ---------------------------------------------------------------------------
rem  Scope steering OFF - puts everything back exactly as it was on 2026-09-19.
rem  The game must be CLOSED.
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

set "BAK=%~dp0Backup\scope-2026-09-19-pre-steering\dinput8.dll"

if not exist "%BAK%" (
  echo   No backup found - steering was probably never switched on.
  pause
  exit /b 1
)

copy /y "%BAK%" "%~dp0dinput8.dll" >nul
if errorlevel 1 (
  echo   Could not restore dinput8.dll. Is the game really closed?
  pause
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$p='%~dp0re2_fw_config.txt';" ^
  "(Get-Content $p) ^| ForEach-Object { if($_ -like 'VR_SteerMirrorProjection=*'){ 'VR_SteerMirrorProjection=false' } else { $_ } } ^| Set-Content -Path $p -Encoding ASCII"

echo.
echo   STEERING IS OFF. The previous build is back in place.
echo.
pause
