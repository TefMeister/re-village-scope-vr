@echo off
rem ---------------------------------------------------------------------------
rem  SCOPE LIGHTS FIX OFF  (2026-09-25)
rem  The scope normally moves its two hidden views to draw AFTER your eyes, so
rem  the world's lights stop following the rifle. This switches that off, for
rem  comparing. Works while the game is running (within a couple of seconds
rem  for the next launch; this launch keeps what it already moved).
rem ---------------------------------------------------------------------------
setlocal
if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)
> "%~dp0reframework\data\re_scope_layer_order.txt" echo 0
echo.
echo   Scope lights fix is OFF (from the next launch). SCOPE-LIGHTS-FIX-ON.bat puts it back.
echo.
timeout /t 5 /nobreak >nul 2>&1
