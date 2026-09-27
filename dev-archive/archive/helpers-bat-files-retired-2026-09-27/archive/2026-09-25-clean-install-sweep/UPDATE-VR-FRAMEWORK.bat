@echo off
rem ---------------------------------------------------------------------------
rem  Put the newest build of our patched REFramework (dinput8.dll) into the game.
rem  CLOSE THE GAME FIRST - while it is running it holds the file open.
rem
rem  Dev helper on the home PC only: it copies from the build folder on D:, so it
rem  does nothing on a machine that has not built it.
rem
rem  It keeps the file it replaces as dinput8.previous.dll, so one rename undoes it,
rem  and it says which build was there and which went in.
rem ---------------------------------------------------------------------------
setlocal

set "SRC=D:\RE2 REFramework builds\tools\REFramework-src\build\bin\RE8\dinput8.dll"
set "DST=%~dp0dinput8.dll"
set "BAK=%~dp0dinput8.previous.dll"

if not exist "%SRC%" (
  echo No built REFramework found at:
  echo   %SRC%
  echo Nothing to copy. This helper only works on the PC that builds it.
  pause
  exit /b 1
)

if not exist "%~dp0re8.exe" (
  echo This must sit in the Resident Evil Village folder, beside re8.exe.
  pause
  exit /b 1
)

tasklist /FI "IMAGENAME eq re8.exe" 2>nul | find /I "re8.exe" >nul
if not errorlevel 1 (
  echo.
  echo   THE GAME IS STILL RUNNING. Close it first - while it is open it holds the
  echo   file and the copy will fail.
  echo.
  pause
  exit /b 1
)

echo.
echo   Replacing dinput8.dll:
if exist "%DST%" (
  for %%F in ("%DST%") do echo     was  %%~zF bytes, %%~tF
  copy /Y "%DST%" "%BAK%" >nul
)
copy /Y "%SRC%" "%DST%" >nul
if errorlevel 1 (
  echo     FAILED - the file is still in use, or it is read-only.
  pause
  exit /b 1
)
for %%F in ("%DST%") do echo     now  %%~zF bytes, %%~tF
echo.
echo   The one it replaced is kept as dinput8.previous.dll.
echo   Done. Start the game as normal.
echo.
pause
