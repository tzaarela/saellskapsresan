@echo off
cd /d "%~dp0runtime"
setlocal enabledelayedexpansion

REM CONFIG
set PYTHON_EXEC=python
set SYNC_SCRIPT=main.py
set LOG_FILE=sync_log.txt

REM Check if Python is available
%PYTHON_EXEC% --version >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Error: Python not found or not in PATH
    echo Trying 'py' command instead...
    set PYTHON_EXEC=py
    py --version >nul 2>&1
    if !ERRORLEVEL! neq 0 (
        echo Error: Neither 'python' nor 'py' commands work
        pause
        exit /b 1
    )
)

REM Check if script exists
if not exist "%SYNC_SCRIPT%" (
    echo Error: Sync script not found at "%SYNC_SCRIPT%"
    echo Current directory: %CD%
    pause
    exit /b 1
)

REM Start sync script
echo Starting sync script...
echo Running: %PYTHON_EXEC% "%SYNC_SCRIPT%"
call %PYTHON_EXEC% "%SYNC_SCRIPT%"
if %ERRORLEVEL% neq 0 (
    echo Error: Sync script failed with error code %ERRORLEVEL%
    echo Check %LOG_FILE% for details:
    echo.
    type "%LOG_FILE%"
    echo.
    pause
    exit /b %ERRORLEVEL%
)

echo Sync complete
pause