@echo off
rem KEEP-LOG.bat -- save the current REFramework log before it is lost.
rem
rem WHY: REFramework empties re2_framework_log.txt every time the game starts. On
rem 2026-09-17 a session made three launches and the two that mattered were gone by
rem the end -- their lines survive only as something typed out by hand.
rem
rem WHEN: click this AFTER closing the game and BEFORE starting it again. Clicking it
rem while the game is running saves the log so far, which is also fine.
rem
rem WHERE IT GOES: reframework\logs\re2_framework_log-YYYY-MM-DD_HH-MM-SS.txt
rem Nothing is deleted, ever -- old copies just pile up, and they are small.

setlocal
set "GAME=%~dp0"
if not exist "%GAME%re2_framework_log.txt" (
  echo No log found next to this file.
  echo Put KEEP-LOG.bat in the game folder, beside re2_framework_log.txt.
  pause
  exit /b 1
)
if not exist "%GAME%reframework\logs" mkdir "%GAME%reframework\logs"

rem A sortable timestamp that does not depend on the machine's date format: WMIC
rem reports local time as YYYYMMDDHHMMSS.
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value 2^>nul') do set "LDT=%%I"
if "%LDT%"=="" (
  rem No WMIC (it is gone on newer Windows builds) -- fall back to PowerShell.
  for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMddHHmmss"') do set "LDT=%%I"
)
set "STAMP=%LDT:~0,4%-%LDT:~4,2%-%LDT:~6,2%_%LDT:~8,2%-%LDT:~10,2%-%LDT:~12,2%"

copy /y "%GAME%re2_framework_log.txt" "%GAME%reframework\logs\re2_framework_log-%STAMP%.txt" >nul
if errorlevel 1 (
  echo Could not copy the log.
  pause
  exit /b 1
)
echo Saved: reframework\logs\re2_framework_log-%STAMP%.txt
rem /nobreak, and the error swallowed: timeout fails when stdin is redirected, which is what
rem happens when LAUNCH-VILLAGE.bat calls this. Always leave with a clean exit code.
timeout /t 3 /nobreak >nul 2>&1
exit /b 0
