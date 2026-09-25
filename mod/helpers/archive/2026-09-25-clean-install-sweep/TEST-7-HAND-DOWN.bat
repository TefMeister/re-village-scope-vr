@echo off
rem Draw the left hand 5cm lower than the controller.
>"%~dp0reframework\data\re_scope_cmd.txt" (
echo handhigher L 0.05
)
echo Sent: handhigher L 0.05
timeout /t 2 >nul
