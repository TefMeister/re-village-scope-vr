@echo off
rem Flicker step 2: hide the flicker by re-showing the last good frame.
>"%~dp0reframework\data\re_scope_cmd.txt" (
echo hold 2
)
echo Flicker hiding is ON. Play for about a minute.
timeout /t 2 >nul
