import os
import sys
import argparse
import atexit

# Add the current directory to the Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(1, '/utils/')

from utils.lua_operations import initialize_lua, set_lua_var_in_file
from sync.sync_loop import sync_loop
from config import GLOBAL_ACCOUNT_PATH


def parse_arguments():
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(description="Sync SavedVariables with Google Sheets.")
    parser.add_argument('-reset', action='store_true', help="Clear the remote DeathLoggerDB sheet.")
    parser.add_argument('-nodownload', action='store_true', help="Don't upload, only download")
    parser.add_argument('-character', type=str, help="Character name for LastLogonDB update")
    return parser.parse_args()

def cleanup_before_exit():
    """Perform final cleanup operations before the script exits."""
    try:
        print("[LOG] Performing final cleanup before exit...")
        
        # Set SyncLoaded to false to indicate sync is no longer active
        lua = initialize_lua()
        set_lua_var_in_file(lua, GLOBAL_ACCOUNT_PATH, "SyncLoaded", False)
        
        print("[LOG] Cleanup completed. Exiting.")
    except Exception as e:
        print(f"[ERROR] Error during cleanup: {e}")

def main():
    # Register the cleanup function
    atexit.register(cleanup_before_exit)
    
    # Parse command-line arguments
    args = parse_arguments()
    
    # Set global variables based on arguments
    globals()['shouldReset'] = args.reset
    globals()['shouldNotDownload'] = args.nodownload
    globals()['character_name_debug'] = args.character
    globals()['shouldStartGame'] = True
    globals()['isGameRunning'] = False
    globals()['isFirstCheck'] = True
    globals()['wow_process'] = None
    
    # Start the sync loop
    sync_loop()

if __name__ == "__main__":
    main()