import os
import time
import psutil
import config
import sys

# Add the current directory to the Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from utils.file_operations import file_exists, validate_saved_variables, read_lua_file
from utils.lua_operations import initialize_lua, extract_lua_table, extract_lua_var, set_lua_var_in_file, update_lua_table_in_file
from utils.wow_integration import is_wow_running, sync_ready_start_wow
from google_sheets.service import get_sheets_service
from google_sheets.operations import get_sheet_data
from google_sheets.converters import sheet_to_lua_format
from sync.death_logger import upload_death_log
from sync.last_logon import update_last_logon
from sync.professions import update_character_professions

def try_and_set_character_path(lua):
    """Attempt to set the character-specific SavedVariables path based on the CurrentCharacter variable."""
    content = read_lua_file(config.GLOBAL_ACCOUNT_PATH)
    content = content.strip()
    if content:
        currentCharacter = extract_lua_var(lua, content, "CurrentCharacter", default="")
        if currentCharacter:
            print("[LOG] CurrentCharacter detected: " + currentCharacter + ". Setting local character path..")
            config.LOCAL_CHARACTER_PATH = "../../../../WTF/Account/" + config.currentAccountName + "/Nordanaar/CHARACTERNAME/SavedVariables/SaellskapsresanMod.lua"
            config.LOCAL_CHARACTER_PATH = config.LOCAL_CHARACTER_PATH.replace("CHARACTERNAME", currentCharacter)
            print("[LOG] LOCAL_CHARACTER_PATH: " + config.LOCAL_CHARACTER_PATH)
            return True
        else:
            print("[LOG] Current character not set. Should prompt user to reload!")
            return False
    else:
        print("[WARNING] Global Account path NOT detected.")
        return False

def download_all_tables():
    """Download all tables from Google Sheets to the local Lua file."""
    service = get_sheets_service()
    lua = initialize_lua()
    
    for table_name, sheet_name in [
        ("DeathLoggerDB", config.DEATH_LOGGER_SHEET),
        ("LastLogonDB", config.LAST_LOGON_SHEET),
        ("CharacterProfessionsDB", config.CHARACTER_PROFESSIONS_SHEET),
        ("CharacterStatsDB", config.CHARACTER_STATS_SHEET)]:
        
        sheet_data = get_sheet_data(service, sheet_name)
        lua_data = sheet_to_lua_format(sheet_data, table_name)
        update_lua_table_in_file(lua, config.GLOBAL_ACCOUNT_PATH, table_name, lua_data)
    
    print(f"[LOG] Downloaded all tables from Google Sheets")
    return True

def process_memory():
    """Get current process memory usage."""
    process = psutil.Process(os.getpid())
    mem_info = process.memory_info()
    return mem_info.rss

def profile(func):
    """Decorator to profile memory usage of a function."""
    def wrapper(*args, **kwargs):
        mem_before = process_memory()
        result = func(*args, **kwargs)
        mem_after = process_memory()
        print("{}:consumed memory: {:,}".format(
            func.__name__,
            mem_after - mem_before))
        return result
    return wrapper

@profile
def sync_loop():
    """Main sync loop that periodically checks for changes and syncs with Google Sheets."""
    service = get_sheets_service()
    lua = initialize_lua()
    
    global_last_modified = None
    local_last_modified = None

    if not validate_saved_variables():
        print("[ERROR] Failed to validate saved variables")
        input("Press Enter to continue...")
        return
    
    print(f"[LOG] Syncing with online database...")

    while True:
        try:
            # Check if WoW is still running or we exit
            if config.isGameRunning and not is_wow_running():
                print("[LOG] WoW has exited. Shutting down sync.")
                break

            # Lets not check local character stuff on first run as we might have changed character.
            if not config.isFirstCheck and file_exists(config.LOCAL_CHARACTER_PATH):

                #Get local character savedVariables and see if file modified
                local_file_stats = os.stat(config.LOCAL_CHARACTER_PATH)
                local_mod_time = local_file_stats.st_mtime

                if local_last_modified is None or local_mod_time != local_last_modified:

                    print("[LOG] Local changes detected!")
                    content = read_lua_file(config.LOCAL_CHARACTER_PATH)
                    
                    death_logger_data = extract_lua_table(lua, content, "LocalDeathLoggerDB")
                    if death_logger_data:
                        print("[LOG] Trying to update remote with LocalDeathLoggerDB...")
                        upload_death_log(service, lua, death_logger_data[0])

                    character_profession_data = extract_lua_table(lua, content, "LocalCharacterProfessionsDB")
                    if character_profession_data:
                        
                        # Get the first character name (first key in the dictionary)
                        print("[LOG] Trying to update remote with LocalCharacterProfessionsDB...")
                        character = next(iter(character_profession_data))
                        
                        # Get the professionString and lastModified for this character
                        profession_string = character_profession_data[character]["professionString"]
                        last_modified = character_profession_data[character]["lastModified"]
                        
                        # Call update_character_professions with the extracted values
                        update_character_professions(service, lua, character, profession_string, last_modified)

                    last_logon_data = extract_lua_table(lua, content, "LocalLastLogonDB")
                    if last_logon_data:

                        print("[LOG] Trying to update remote with LocalLastLogonDB...")
                        # Get the first character name (first key in the dictionary)
                        character = next(iter(last_logon_data))
                        
                        # Get the last logon timestamp directly (it's just a string value)
                        last_logon = last_logon_data[character]
                        
                        # Now you can use this data as needed
                        update_last_logon(service, lua, character, last_logon)

                    # Update last_modified
                    local_file_stats = os.stat(config.LOCAL_CHARACTER_PATH)
                    local_last_modified = local_file_stats.st_mtime

            # Get global savedVariables and see if file modified
            global_file_stats = os.stat(config.GLOBAL_ACCOUNT_PATH)
            global_mod_time = global_file_stats.st_mtime

            if global_last_modified is None or global_mod_time != global_last_modified:
                    
                if config.isFirstCheck:
                    print("[LOG] Doing initial setup...") 
                else:
                    print("[LOG] Global file change detected.")
                
                try_and_set_character_path(lua)
                
                if config.isFirstCheck:
                    download_all_tables()
                    config.isFirstCheck = False
                    # Set SyncLoaded to true on first check
                    set_lua_var_in_file(lua, config.GLOBAL_ACCOUNT_PATH, "SyncLoaded", True)
                    
                    if config.shouldStartGame:
                        sync_ready_start_wow()
                else:
                    download_all_tables()
                
                # Update last_modified
                global_file_stats = os.stat(config.GLOBAL_ACCOUNT_PATH)
                global_last_modified = global_file_stats.st_mtime
        
        except Exception as e:
            print(f"[WARNING] Error: {e}")

        time.sleep(2)