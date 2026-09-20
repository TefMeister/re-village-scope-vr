@echo off
rem ---------------------------------------------------------------------------
rem  Put the newest build of our plugin into the game. CLOSE THE GAME FIRST -
rem  while it is running it holds the file open and nothing can replace it.
rem
rem  Dev helper on the home PC only: it copies from the build folder, so it does
rem  nothing on a machine that has not built the plugin.
rem
rem  It tells you which build was already there and which one went in, so a
rem  "nothing changed" is never mistaken for a successful update.
rem ---------------------------------------------------------------------------
setlocal

set "SRC=C:\Users\TD3KX\github-backups-pd\staging\re-village-scope-vr\plugin\build\Release\re_scope_vr.dll"
set "DST=%~dp0reframework\plugins\re_scope_vr.dll"

if not exist "%SRC%" (
  echo No built plugin found at:
  echo   %SRC%
  echo Nothing to copy. This helper only works on the PC that builds it.
  pause
  exit /b 1
)

if not exist "%~dp0reframework\plugins" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
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
echo   Replacing:
if exist "%DST%" ( for %%F in ("%DST%") do echo     was  %%~zF bytes )
copy /Y "%SRC%" "%DST%" >nul
if errorlevel 1 (
  echo     FAILED - the file is still in use, or it is read-only.
  pause
  exit /b 1
)
for %%F in ("%DST%") do echo     now  %%~zF bytes
echo.
echo   Done. Start the game as normal.
echo.
pause
