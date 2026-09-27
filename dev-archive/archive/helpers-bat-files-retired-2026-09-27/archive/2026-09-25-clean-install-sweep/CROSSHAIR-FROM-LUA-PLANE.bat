@echo off
rem ---------------------------------------------------------------------------
rem  CROSSHAIR FROM THE LUA'S PLANE  (the 2026-09-22 afternoon zero test)
rem  The scope picture is a mirror. The maths that places the crosshair has been
rem  working out where that mirror plane is from the sliders, and the log shows it
rem  lands 4-5 degrees off the plane the picture really uses. A mirror 4.5 degrees
rem  off bends the aim by 9 -- the size of the zero you keep having to tune.
rem  This makes the crosshair maths use the real plane instead, and sets the zero
rem  to 0 / 0. Hold the rifle STILL for a second before each shot (the real plane
rem  is passed over twice a second). Hits on the cross = the plane was the zero.
rem  CROSSHAIR-FROM-JOINT-POSE.bat puts everything back. Works while running.
rem ---------------------------------------------------------------------------
setlocal
if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)
> "%~dp0reframework\data\re_scope_panesrc.txt" echo 1
> "%~dp0reframework\data\re_scope_zeroframe.txt" echo 1
> "%~dp0reframework\data\re_scope_cmd.txt" echo zeroup 0
>> "%~dp0reframework\data\re_scope_cmd.txt" echo zeroright 0
echo.
echo   Crosshair maths now uses the plane the picture really has. Zero set to 0 / 0.
echo   Hold the rifle still a second before each shot.
echo.
timeout /t 3 /nobreak >nul 2>&1
