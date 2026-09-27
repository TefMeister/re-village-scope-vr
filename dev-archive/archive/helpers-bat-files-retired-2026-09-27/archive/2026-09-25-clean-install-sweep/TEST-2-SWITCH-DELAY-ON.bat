@echo off
rem Weapon-switch glass flash: wait 1.5s before putting the stock glass back.
>"%~dp0reframework\data\re_scope_cmd.txt" (
echo swdelay 1500
)
echo Sent: swdelay 1500
timeout /t 2 >nul
