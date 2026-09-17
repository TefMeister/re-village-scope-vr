@echo off
rem Jitter: aim the picture from this frame's eye instead of the barrel.
>"%~dp0reframework\data\re_scope_cmd.txt" (
echo eyepar 1
)
echo Sent: eyepar 1
timeout /t 2 >nul
