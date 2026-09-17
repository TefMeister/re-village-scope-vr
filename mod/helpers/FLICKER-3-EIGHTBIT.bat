@echo off
rem Flicker step 3: take the scope picture from the safe 8-bit copy.
rem Bright sunlight will look washed out on this one - that is expected, it is a test, not the fix.
>"%~dp0reframework\data\re_scope_cmd.txt" (
echo hold 1
echo src8 1
)
echo Now on the 8-bit picture. Play for about a minute.
timeout /t 2 >nul
