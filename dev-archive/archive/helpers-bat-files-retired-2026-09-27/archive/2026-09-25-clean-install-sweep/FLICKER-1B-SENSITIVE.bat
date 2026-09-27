@echo off
rem Flicker: turn the counter up to its most sensitive setting.
>"%~dp0reframework\data\re_scope_cmd.txt" (
echo hold 1
echo holdt 0.005
)
echo Sent: hold 1 + holdt 0.005
timeout /t 2 >nul
