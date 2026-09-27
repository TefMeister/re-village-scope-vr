@echo off
rem ---------------------------------------------------------------------------
rem  ONLY IF ASKED. Puts back the plugin from BEFORE the bullet-spread work
rem  (the one the scope last worked with, built 18 September).
rem
rem  This is a test, not a fix: it tells us whether the new plugin is what broke
rem  the scope picture. With it in place the rifle scatters its hip shots again.
rem
rem  UPDATE-RIFLE-PLUGIN.bat puts the new one back afterwards.
rem  CLOSE THE GAME FIRST.
rem ---------------------------------------------------------------------------
setlocal

set "OLD=%~dp0reframework\plugins\re_scope_vr.dll.pre-spread-fix-2026-09-20"
set "DST=%~dp0reframework\plugins\re_scope_vr.dll"

if not exist "%OLD%" (
  echo The saved older plugin is not here:
  echo   %OLD%
  pause
  exit /b 1
)

tasklist /FI "IMAGENAME eq re8.exe" 2>nul | find /I "re8.exe" >nul
if not errorlevel 1 (
  echo.
  echo   THE GAME IS STILL RUNNING. Close it first.
  echo.
  pause
  exit /b 1
)

echo.
for %%F in ("%DST%") do echo   was  %%~zF bytes
copy /Y "%OLD%" "%DST%" >nul
if errorlevel 1 ( echo   FAILED to copy. & pause & exit /b 1 )
for %%F in ("%DST%") do echo   now  %%~zF bytes   (235520 = the 18 September plugin)
echo.
echo   Done. Start the game and look through the scope.
echo.
pause
