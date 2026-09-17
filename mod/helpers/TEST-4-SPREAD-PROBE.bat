@echo off
rem List the weapon's live spread and accuracy values in the log (read-only).
>"%~dp0reframework\data\re_scope_cmd.txt" (
echo spreadprobe
)
echo Sent: spreadprobe
timeout /t 2 >nul
