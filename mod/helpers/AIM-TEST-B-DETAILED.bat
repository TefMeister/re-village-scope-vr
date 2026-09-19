@echo off
rem ---------------------------------------------------------------------------
rem  AIM TEST B -- NORMAL. The detailed aiming maths, exactly as the mod ships.
rem
rem  This is the BASELINE for both of the other tests, and it is also how you put
rem  everything back afterwards.
rem
rem  It is the one measured on 2026-09-19 cutting the picture from (0.735, 0.064)
rem  - a long way above the middle of the frame, close to the top edge.
rem
rem  ⚠ It sends TWO settings, not one. It used to send only `geom 1`, which put
rem  back what test A changed but NOT what test C changes - so running B after C
rem  left the headset-tilt setting still switched off and quietly turned the
rem  "back to normal" run into another test C. Fixed 2026-09-20.
rem ---------------------------------------------------------------------------
setlocal

if not exist "%~dp0reframework\data" (
  echo This must sit in the Resident Evil Village folder, beside reframework\.
  pause
  exit /b 1
)

>  "%~dp0reframework\data\re_scope_cmd.txt" echo geom 1
>> "%~dp0reframework\data\re_scope_cmd.txt" echo geomusep 1

echo.
echo   Back to NORMAL (the detailed maths, headset tilt included).
echo   This is the baseline - compare the other two against it.
echo.
timeout /t 3 /nobreak >nul 2>&1
