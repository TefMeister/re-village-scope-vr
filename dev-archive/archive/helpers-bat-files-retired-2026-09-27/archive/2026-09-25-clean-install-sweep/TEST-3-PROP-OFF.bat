@echo off
rem Put the hidden prop back where it was.
>"%~dp0reframework\data\re_scope_cmd.txt" (
echo propoff
)
echo Sent: propoff
timeout /t 2 >nul
