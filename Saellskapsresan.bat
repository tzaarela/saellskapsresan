@echo off
cd /d "%~dp0"
setlocal enabledelayedexpansion

REM CONFIG
set PYTHON_EXEC=python
set SYNC_SCRIPT=runscript.py
set FLAG_FILE=sync_ready.flag

REM Start sync script
echo Starting sync script...

REM Clean up old flag
if exist "%FLAG_FILE%" del "%FLAG_FILE%"

REM Run Python script in the background (async)
start "" %PYTHON_EXEC% "%SYNC_SCRIPT%" > sync_log.txt 2>&1

REM UNCOMMENT THIS IF U WANT TO WAIT FOR PYTHONSCRIPT TO FINISH FIRST SYNC.

REM REM Wait for flag file
REM echo Waiting for %FLAG_FILE%...
REM :waitloop
REM if exist "%FLAG_FILE%" (
    REM echo Sync complete!
REM ) else (
    REM timeout /T 1 >nul
    REM goto waitloop
REM )

exit
