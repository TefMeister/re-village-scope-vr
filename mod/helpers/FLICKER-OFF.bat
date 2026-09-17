@echo off
rem Puts both flicker knobs back off, so the scope looks as it did before the test.
>"%~dp0reframework\data\re_scope_cmd.txt" (
echo hold 0
echo src8 0
)
echo Flicker knobs off.
timeout /t 2 >nul
