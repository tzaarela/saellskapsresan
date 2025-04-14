@echo off
cd /d "%~dp0"

REM === CONFIG ===
set PYTHON_EXEC=python
set SCRIPT_DIR=Interface\AddOns\SaellskapsresanMod
set SYNC_SCRIPT=runscript.py
set WOW_EXE=VanillaFixes.exe
set TASK_NAME=DeathLoggerSync

REM === Prevent multiple instances of sync script ===
tasklist /FI "IMAGENAME eq python.exe" /FI "WINDOWTITLE eq %SYNC_SCRIPT%" 2>NUL | find /I "%SYNC_SCRIPT%" >NUL
if %ERRORLEVEL%==0 (
    echo Sync script already running.
) else (
    echo Starting sync script...
    pushd "%SCRIPT_DIR%"
    start "%SYNC_SCRIPT%" %PYTHON_EXEC% "%SYNC_SCRIPT%"
    popd
)

REM === Launch WoW ===
if exist "%WOW_EXE%" (
    echo Launching Turtle WoW...
    start "" "%WOW_EXE%"
) else (
    echo Error: Wow.exe not found in this folder.
)

exit
