@echo off
rem Flicker step 1: count the flickers in the log. The picture does not change.
>"%~dp0reframework\data\re_scope_cmd.txt" (
echo hold 1
)
echo Counting flickers. Play for about a minute.
timeout /t 2 >nul
