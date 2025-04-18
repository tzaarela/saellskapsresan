@echo off
setlocal EnableDelayedExpansion

echo Installing Saellskapsresan Mod...

REM === STEP 1: Find or install Python ===
set "PYTHON_EXE="
set "FOUND_STORE_PYTHON=no"

REM Check if we have the Windows Store alias
where python 2>nul | findstr "WindowsApps" >nul
if %ERRORLEVEL% EQU 0 (
    set "FOUND_STORE_PYTHON=yes"
)

REM Try to find real Python installations
for %%P in (
    "%LocalAppData%\Programs\Python\Python311\python.exe"
    "%LocalAppData%\Programs\Python\Python312\python.exe"
    "%LocalAppData%\Programs\Python\Python310\python.exe"
    "%ProgramFiles%\Python311\python.exe"
    "%ProgramFiles%\Python312\python.exe"
    "%ProgramFiles%\Python310\python.exe"
    "%ProgramFiles(x86)%\Python311\python.exe"
    "C:\Python311\python.exe"
    "C:\Python312\python.exe"
    "C:\Python310\python.exe"
) do (
    if exist "%%~fP" (
        set "PYTHON_EXE=%%~fP"
        goto :python_found
    )
)

echo No Python installation found, installing Python...
powershell -Command "Invoke-WebRequest -Uri https://www.python.org/ftp/python/3.11.7/python-3.11.7-amd64.exe -OutFile python-installer.exe"
if %ERRORLEVEL% NEQ 0 (
    echo Failed to download Python installer.
    pause
    exit /b 1
)

echo Running Python installer...
echo Please select: Install for all users and Add Python to PATH
start /wait python-installer.exe
del python-installer.exe

:python_found
if not defined PYTHON_EXE (
    echo Checking for newly installed Python...
    
    for %%P in (
        "%LocalAppData%\Programs\Python\Python311\python.exe"
        "%LocalAppData%\Programs\Python\Python312\python.exe"
        "%ProgramFiles%\Python311\python.exe"
        "%ProgramFiles%\Python312\python.exe"
        "%ProgramFiles(x86)%\Python311\python.exe"
        "C:\Python311\python.exe"
        "C:\Python312\python.exe"
    ) do (
        if exist "%%~fP" (
            set "PYTHON_EXE=%%~fP"
            goto :python_verified
        )
    )
    
    echo Failed to find Python after installation.
    pause
    exit /b 1
)

:python_verified
echo Python found at: %PYTHON_EXE%

REM === STEP 2: Install Python packages ===
echo Installing required Python packages...
"%PYTHON_EXE%" -m ensurepip --upgrade
"%PYTHON_EXE%" -m pip install --upgrade pip
"%PYTHON_EXE%" -m pip install google-api-python-client google-auth google-auth-oauthlib google-auth-httplib2 psutil

:: Get the current directory (SaellskapsresanMod)
set "CURRENT_DIR=%~dp0"
set "BAT_FILE=%CURRENT_DIR%Saellskapsresan.bat"
set "ICON_FILE=%CURRENT_DIR%UI\addonlogo.ico"
set "SHORTCUT_PATH=%CURRENT_DIR%..\..\..\Saellskapsresan.lnk"

:: Create VBScript to generate the shortcut
echo Set oWS = WScript.CreateObject("WScript.Shell") > "%TEMP%\CreateShortcut.vbs"
echo sLinkFile = "%SHORTCUT_PATH%" >> "%TEMP%\CreateShortcut.vbs"
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> "%TEMP%\CreateShortcut.vbs"
echo oLink.TargetPath = "%BAT_FILE%" >> "%TEMP%\CreateShortcut.vbs"
echo oLink.IconLocation = "%ICON_FILE%, 0" >> "%TEMP%\CreateShortcut.vbs"
echo oLink.WorkingDirectory = "%CURRENT_DIR%" >> "%TEMP%\CreateShortcut.vbs"
echo oLink.Save >> "%TEMP%\CreateShortcut.vbs"

:: Run the VBScript
cscript //nologo "%TEMP%\CreateShortcut.vbs"

:: Clean up
del "%TEMP%\CreateShortcut.vbs"

echo Shortcut created at: %SHORTCUT_PATH%
echo Pointing to: %BAT_FILE%
echo With icon from: %ICON_FILE%

echo Saellskapsresan Mod installed successfully!
pause
exit /b 0