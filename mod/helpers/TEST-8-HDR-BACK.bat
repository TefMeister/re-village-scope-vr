@echo off
rem Turn OFF yesterdays save-reload fallback, which is holding the scope on the low-quality source.
>"%~dp0reframework\data\re_scope_cmd.txt" (
echo rbfb 0
)
echo Sent: rbfb 0 -- now press ". Re-arm mirror latch" on the VR panel.
timeout /t 2 >nul
