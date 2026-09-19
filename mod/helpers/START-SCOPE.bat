@echo off
rem ---------------------------------------------------------------------------
rem  Starts the VR scope. Have the sniper rifle in your hands first.
rem
rem  THIS NOW FORWARDS TO VR-TRUE-SCOPE.bat, and that is a fix, not tidying.
rem
rem  What this file used to do was send `bringup` on its own. That skips the two
rem  steps that have to come FIRST:
rem      1. choose the picture target  (fn rtex_2560)
rem      2. re-arm the picture latch   (numpad .)
rem  Without them the mod latches onto one of the game's own 1080p buffers about a
rem  millisecond after start-up and never looks again -- which is exactly the BLACK
rem  SCOPE PICTURE that cost the whole 2026-09-18 session before it was understood.
rem
rem  So the old version of this file could not work reliably, and the one that does
rem  work had a different name. Two scripts, and the wrong one was the memorable
rem  one. Now either name does the right thing. 2026-09-19.
rem ---------------------------------------------------------------------------
setlocal

if not exist "%~dp0VR-TRUE-SCOPE.bat" (
  echo.
  echo   VR-TRUE-SCOPE.bat is missing from this folder, so the scope cannot be
  echo   started properly. Sending the old bare command as a last resort -- if the
  echo   picture comes up black, that is why.
  echo.
  echo bringup> "%~dp0reframework\data\re_scope_cmd.txt"
  timeout /t 3 >nul
  exit /b 1
)

call "%~dp0VR-TRUE-SCOPE.bat"
exit /b %errorlevel%
