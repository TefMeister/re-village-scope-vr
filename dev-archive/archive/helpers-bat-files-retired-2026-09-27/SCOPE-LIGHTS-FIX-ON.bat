@echo off
rem ---------------------------------------------------------------------------
rem  SCOPE LIGHTS FIX ON  (2026-09-25)  -- this is the default
rem  The scope moves its two hidden views to draw AFTER your eyes, so the
rem  world's lights stop following the rifle. Works while the game is running
rem  (applies within a couple of seconds).
rem ---------------------------------------------------------------------------
setlocal
if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)
> "%~dp0reframework\data\re_scope_layer_order.txt" echo 1
echo.
echo   Scope lights fix is ON (the default).
echo.
timeout /t 5 /nobreak >nul 2>&1
