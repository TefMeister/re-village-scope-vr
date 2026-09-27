@echo off
rem LAUNCH-VILLAGE.bat -- save the old log, then start the game through Steam.
rem
rem WHY: this is the only moment the previous launch's log still exists. REFramework
rem empties re2_framework_log.txt at startup, so a log that is not copied aside before
rem the game runs again is gone. Use this shortcut instead of the Steam one and it is
rem taken care of without anyone having to remember.
rem
rem It does nothing clever: KEEP-LOG.bat first, then Steam's own launch URL for
rem Resident Evil Village (app 1196590, read from this machine's Steam manifest
rem 2026-09-18). Steam handles everything else exactly as it normally would.
rem
rem Put this in the game folder, beside KEEP-LOG.bat.

setlocal
set "GAME=%~dp0"
if exist "%GAME%KEEP-LOG.bat" (
  call "%GAME%KEEP-LOG.bat"
) else (
  echo KEEP-LOG.bat is not here -- starting anyway, but the old log will be lost.
  timeout /t 3 >nul
)
echo Starting Resident Evil Village through Steam...
start "" "steam://rungameid/1196590"
