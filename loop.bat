@echo off
REM ============================================================
REM AUTOAGENT IMMORTAL LOOP - Windows launcher
REM Double-click this file to start the infinite loop.
REM Close the window to stop.
REM ============================================================

echo ============================================
echo AUTOAGENT IMMORTAL LOOP
echo ============================================
echo.

cd /d C:\Novus\autoagent

REM Use Git Bash to run the loop script
"C:\Program Files\Git\bin\bash.exe" -l -c "./loop.sh"

REM If bash exits, restart after 30s
echo.
echo Loop exited. Restarting in 30 seconds...
timeout /t 30
goto :eof
