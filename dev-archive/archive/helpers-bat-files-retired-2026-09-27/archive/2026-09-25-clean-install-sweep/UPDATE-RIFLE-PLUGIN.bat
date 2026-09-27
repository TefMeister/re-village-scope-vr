@echo off
rem ---------------------------------------------------------------------------
rem  Put the newest build of our plugin into the game. CLOSE THE GAME FIRST -
rem  while it is running it holds the file open and nothing can replace it.
rem
rem  Dev helper on the home PC only: it copies from the build folders, so it does
rem  nothing on a machine that has not built the plugin.
rem
rem  2026-09-21: the plugin gets built in MORE THAN ONE working folder (each kind of
rem  Claude session has its own), and this used to copy from one fixed folder - so it
rem  could quietly install an OLDER build over a newer one. It now looks at all of
rem  them and takes the NEWEST, and says which one that was.
rem
rem  It keeps the file it replaces as re_scope_vr.dll.previous (one rename undoes it).
rem ---------------------------------------------------------------------------
setlocal

set "DST=%~dp0reframework\plugins\re_scope_vr.dll"

if not exist "%~dp0reframework\plugins" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)

set "SRC="
for /f "usebackq delims=" %%F in (`powershell -NoProfile -Command "Get-ChildItem -Path ($env:USERPROFILE + '\github-backups*\staging\re-village-scope-vr\plugin\build\Release\re_scope_vr.dll') -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName"`) do set "SRC=%%F"

if not defined SRC (
  echo No built plugin found in any working folder.
  echo Nothing to copy. This helper only works on the PC that builds it.
  pause
  exit /b 1
)

tasklist /FI "IMAGENAME eq re8.exe" 2>nul | find /I "re8.exe" >nul
if not errorlevel 1 (
  echo.
  echo   THE GAME IS STILL RUNNING. Close it first - while it is open it holds the
  echo   plugin file and the copy will fail.
  echo.
  pause
  exit /b 1
)

echo.
echo   Newest build found:
for %%F in ("%SRC%") do echo     %%~zF bytes, %%~tF
echo     %SRC%
echo.
echo   Replacing:
if exist "%DST%" (
  for %%F in ("%DST%") do echo     was  %%~zF bytes, %%~tF
  copy /Y "%DST%" "%DST%.previous" >nul
)
copy /Y "%SRC%" "%DST%" >nul
if errorlevel 1 (
  echo     FAILED - the file is still in use, or it is read-only.
  pause
  exit /b 1
)
for %%F in ("%DST%") do echo     now  %%~zF bytes, %%~tF
echo.
echo   Done. Start the game as normal.
echo.
pause
