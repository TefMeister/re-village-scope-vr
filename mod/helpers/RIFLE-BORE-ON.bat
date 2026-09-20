@echo off
rem ---------------------------------------------------------------------------
rem  PUT THE RIFLE'S OWN AIM INTO THE BULLET.
rem
rem  Everything tried before changed a number the bullet had already stopped
rem  listening to. This changes the bullet's own direction, at the moment it is
rem  made - and it writes in the direction our scope already works out for you
rem  every frame, which is where the rifle is really pointing.
rem
rem  It checks its own work. The log will say:
rem      "WROTE the muzzle axis  was 8.4 deg off, now 0.000 deg"   it worked
rem      "WARNING -- the write did not take"                       it did not
rem      "not touched -- no verified muzzle axis"                  rifle not ready
rem
rem  Only the scoped rifle. RIFLE-OFF.bat puts it back. Works instantly.
rem ---------------------------------------------------------------------------
setlocal

if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)

> "%~dp0reframework\data\re_scope_spread.txt" echo 4 0

echo.
echo   Sent: put the muzzle axis into the bullet.
echo   Fire a few shots from the HIP, without holding aim.
echo.
timeout /t 2 /nobreak >nul 2>&1
