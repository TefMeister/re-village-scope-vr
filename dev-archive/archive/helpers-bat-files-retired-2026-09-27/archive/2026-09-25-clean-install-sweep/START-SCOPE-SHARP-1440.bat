@echo off
rem START-SCOPE-SHARP-1440.bat -- same as START-SCOPE, but with the sharper 2560x1440 scope
rem picture. Costs noticeably more performance in the headset. Use INSTEAD of START-SCOPE.
call "%~dp0VR-TRUE-SCOPE-1440.bat"
exit /b %errorlevel%
