@echo off
rem Starts the VR scope: the whole set-up in one go, about 35 seconds.
rem Have the sniper rifle in your hands first.
echo bringup> "%~dp0reframework\data\re_scope_cmd.txt"
echo Scope start sent. Give it about 35 seconds.
timeout /t 3 >nul
