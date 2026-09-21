@echo off
rem START-SCOPE-LOW-720.bat -- same as START-SCOPE, but with the LOW 1280x720 scope picture.
rem Made 2026-09-21 as a CHECK: if this one looks clearly pixelated next to START-SCOPE, the
rem picture sizes really do switch. Also the cheapest of the three for performance.
rem Use INSTEAD of START-SCOPE, on a fresh start of the game.
call "%~dp0VR-TRUE-SCOPE-720.bat"
