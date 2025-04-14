@echo off
setlocal EnableDelayedExpansion

echo Installing Saellskapsresan Mod...
echo Checking for Python...

REM Try to locate python executable
for %%P in (
    "%LocalAppData%\Programs\Python\Python311\python.exe"
    "%ProgramFiles%\Python311\python.exe"
    "%ProgramFiles(x86)%\Python311\python.exe"
    "%LocalAppData%\Microsoft\WindowsApps\python.exe"
) do (
    if exist "%%~fP" (
        set "PYTHON_EXE=%%~fP"
        goto found_python
    )
)

echo Python not found. Installing Python...

REM Download Python
powershell -Command "Invoke-WebRequest -Uri https://www.python.org/ftp/python/3.11.7/python-3.11.7-amd64.exe -OutFile python-installer.exe"

REM Install silently
start /wait python-installer.exe /quiet InstallAllUsers=1 PrependPath=1 Include_pip=1
del python-installer.exe

REM Try locating Python again after install
for %%P in (
    "%LocalAppData%\Programs\Python\Python311\python.exe"
    "%ProgramFiles%\Python311\python.exe"
    "%ProgramFiles(x86)%\Python311\python.exe"
) do (
    if exist "%%~fP" (
        set "PYTHON_EXE=%%~fP"
        goto found_python
    )
)

echo Failed to find Python after installation.
pause
exit /b 1

:found_python
echo Python found at: !PYTHON_EXE!

echo Installing required packages...
"!PYTHON_EXE!" -m pip install --upgrade pip
"!PYTHON_EXE!" -m pip install google-api-python-client google-auth google-auth-oauthlib google-auth-httplib2

REM === COPY THE BATCH FILE ===
call :copy_batch_file

echo Saellskapsresan Mod installed successfully.
pause
exit /b

:copy_batch_file
echo Copying Saellskapsresan.bat to turtle-wow folder...

set "SRC_FILE=%~dp0Saellskapsresan.bat"
set "DEST_DIR=%~dp0..\..\..\"

copy /Y "%SRC_FILE%" "%DEST_DIR%"
if %ERRORLEVEL% EQU 0 (
    echo File copied successfully to: %DEST_DIR%
) else (
    echo Failed to copy file from: %SRC_FILE% to %DEST_DIR%
    pause
    exit /b 1
)

goto :eof
