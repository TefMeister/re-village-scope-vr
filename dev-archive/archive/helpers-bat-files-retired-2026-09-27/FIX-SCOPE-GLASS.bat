@echo off
rem Puts the live picture back on the scope glass (same as pressing numpad * in game).
rem Use it whenever the plain stock crosshair shows on the glass, e.g. after switching weapons.
echo bind> "%~dp0reframework\data\re_scope_cmd.txt"
echo Glass fix sent.
timeout /t 2 >nul
