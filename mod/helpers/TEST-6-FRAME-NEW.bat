@echo off
rem Build the scope frame directly instead of turning it afterwards.
>"%~dp0reframework\data\re_scope_cmd.txt" (
echo framev 2
)
echo Sent: framev 2
timeout /t 2 >nul
