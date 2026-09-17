@echo off
rem Back to the old frame with the turn applied afterwards.
>"%~dp0reframework\data\re_scope_cmd.txt" (
echo framev 1
)
echo Sent: framev 1
timeout /t 2 >nul
