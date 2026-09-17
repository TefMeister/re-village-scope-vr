@echo off
rem Clutter: drop the hidden mirror host 40cm below the rifle.
>"%~dp0reframework\data\re_scope_cmd.txt" (
echo propu -0.4
)
echo Sent: propu -0.4
timeout /t 2 >nul
