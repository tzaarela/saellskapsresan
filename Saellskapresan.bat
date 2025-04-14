@echo off
cd /d "%~dp0"
setlocal enabledelayedexpansion

REM === CONFIG ===
set PYTHON_EXEC=python
set SCRIPT_DIR=Interface\AddOns\SaellskapsresanMod
set SYNC_SCRIPT=runscript.py
set WOW_EXE=VanillaFixes.exe
set FLAG_FILE=sync_ready.flag

REM === Start sync script ===
echo Starting sync script...
pushd "%SCRIPT_DIR%"

REM Clean up old flag
if exist "%FLAG_FILE%" del "%FLAG_FILE%"

REM Run Python script in the background (async)
start "" %PYTHON_EXEC% "%SYNC_SCRIPT%" > sync_log.txt 2>&1

REM Wait for flag file
echo Waiting for %FLAG_FILE%...
:waitloop
if exist "%FLAG_FILE%" (
    echo Sync complete!
) else (
    timeout /T 1 >nul
    goto waitloop
)

popd

exit
