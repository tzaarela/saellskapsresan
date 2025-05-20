import os
import subprocess
import psutil
import config

def is_wow_running():
    """Check if WoW is currently running."""
    for proc in psutil.process_iter(['name']):
        if proc.info['name'] and "wow" in proc.info['name'].lower():
            return True
    return False

def sync_ready_start_wow():
    """Start WoW after sync is complete."""
    # Creating a sync_ready flag for the .bat file to know it's ready to close.
    with open("sync_ready.flag", "w") as f:
        f.write("ready")

    config.shouldStartGame = False
    print("[LOG] Sync done.")
    
    # Check if SuperwoWLauncher exists, if not, try setting it to vanillafixes
    exe_path = "../../../../SuperWoWlauncher.exe"

    # Check if the VanillaFixes exists, if not, set it to WoW.exe
    if not os.path.exists(exe_path):
        exe_path = "../../../../VanillaFixes.exe"
    
    # Running game with WoW.exe
    if not os.path.exists(exe_path):
        exe_path = "../../../../WoW.exe"
    
    print("[DEBUG] Attempting to launch WoW from:", exe_path)

    # Then launch it
    try:
        config.wow_process = subprocess.Popen([exe_path])
        config.isGameRunning = True
        
    except FileNotFoundError:
        print("[ERROR] WoW executable not found at:", exe_path)
        exit(1)

    print("[LOG] Launching Turtle WoW... Please dont close this window while playing!")