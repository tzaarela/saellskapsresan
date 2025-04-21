import os
import time
import argparse
import subprocess
import psutil
import atexit
from lupa import LuaRuntime
from google.oauth2 import service_account
from googleapiclient.discovery import build
from datetime import datetime

# Read account name
with open("accountname.txt", "r") as f:
    currentAccountName = f.read().strip().upper()
path = "../../../WTF/Account/ACCOUNTNAME/SavedVariables/SaellskapsresanMod.lua"

# Constants
GLOBAL_ACCOUNT_PATH = path.replace("ACCOUNTNAME", currentAccountName)
LOCAL_CHARACTER_PATH = "../../../WTF/Account/" + currentAccountName + "/Nordanaar/CHARACTERNAME/SavedVariables/SaellskapsresanMod.lua" #We set characterName later in code.
SCOPES = ['https://www.googleapis.com/auth/spreadsheets']
SERVICE_ACCOUNT_FILE = 'service-account.json'
SPREADSHEET_ID = '1IarFvH3gl3y1MGlId3SwrvqLVfYiIR8KwX3dOE8R5II'  # Set this to your spreadsheet ID

# Sheet names
DEATH_LOGGER_SHEET = 'DeathLoggerDB'
LAST_LOGON_SHEET = 'LastLogonDB'
CHARACTER_PROFESSIONS_SHEET = 'CharacterProfessionsDB'

# Parse command-line arguments
parser = argparse.ArgumentParser(description="Sync SavedVariables with Google Sheets.")
parser.add_argument('-reset', action='store_true', help="Clear the remote DeathLoggerDB sheet.")
parser.add_argument('-nodownload', action='store_true', help="Don't upload, only download")
parser.add_argument('-character', type=str, help="Character name for LastLogonDB update")
args = parser.parse_args()

# Global variables
shouldReset = args.reset
shouldNotDownload = args.nodownload
character_name_debug = args.character
shouldStartGame = True
isGameRunning = False
isFirstCheck = True
wow_process = None

#### INIT/EXIT FUNCTIONS ####

def initialize_lua():
    """Initialize and return a Lua runtime."""
    lua = LuaRuntime(unpack_returned_tuples=True)

    # Add utility functions to Lua for table serialization
    lua.execute('''
    function table_to_string(tbl, indent)
        if not indent then indent = 0 end
        local result = "{"
        local indentStr = string.rep("  ", indent)
        local first = true
        
        for k, v in pairs(tbl) do
            if not first then result = result .. "," end
            first = false
            
            result = result .. "\\n" .. indentStr .. "  "
            
            -- Format the key
            if type(k) == "string" and k:match("^[_%a][_%w]*$") then
                result = result .. k
            else
                result = result .. "[" .. format_value(k, indent + 1) .. "]"
            end
            
            result = result .. " = " .. format_value(v, indent + 1)
        end
        
        if not first then result = result .. "\\n" .. indentStr end
        return result .. "}"
    end
    
    function format_value(val, indent)
        local val_type = type(val)
        
        if val_type == "table" then
            return table_to_string(val, indent)
        elseif val_type == "string" then
            return string.format("%q", val)
        elseif val_type == "nil" then
            return "nil"
        else
            return tostring(val)
        end
    end
    ''')
    
    return lua

def cleanup_before_exit():
    """Perform final cleanup operations before the script exits."""
    try:
        print("[LOG] Performing final cleanup before exit...")
        
        # Set SyncLoaded to false to indicate sync is no longer active
        lua = initialize_lua()  # Make sure this is accessible
        set_lua_var_in_file(lua, GLOBAL_ACCOUNT_PATH, "SyncLoaded", False)
        
        print("[LOG] Cleanup completed. Exiting.")
    except Exception as e:
        print(f"[ERROR] Error during cleanup: {e}")

# Register the cleanup function
atexit.register(cleanup_before_exit)

#### CORE FUNCTIONS ####

def get_sheets_service():
    """Create and return a Google Sheets service object."""
    credentials = service_account.Credentials.from_service_account_file(
        SERVICE_ACCOUNT_FILE, scopes=SCOPES)
    return build('sheets', 'v4', credentials=credentials)

def extract_lua_table(lua, content, var_name):
    """Extract a Lua table from content string using the Lua interpreter."""
    try:
        lua.execute(content)
        lua_table = lua.globals()[var_name]
        return lua_table_to_python(lua_table)
    except Exception as e:
        print(f"[ERROR] Error extracting Lua table {var_name}: {e}")
        return {}

def extract_lua_var(lua, content, var_name, default=None):
    try:
        lua.execute(content)
        
        if var_name not in lua.globals():
            print(f"[WARNING] Variable '{var_name}' not found in Lua content")
            return default
            
        value = lua.globals()[var_name]
        
        return lua_value_to_python(value)
    except Exception as e:
        print(f"[ERROR] Error extracting '{var_name}': {e}")
        return default

def lua_table_to_python(lua_table):
    """Convert a Lua table to a Python dictionary or list."""
    if lua_table is None:
        return {}
    
    # Check if it's a sequence or a dictionary-like table
    is_sequence = True
    max_index = 0
    
    # First pass to determine if it's a sequence
    for k, v in lua_table.items():
        if isinstance(k, int) and k > 0:
            max_index = max(max_index, k)
        else:
            is_sequence = False
            break
    
    if is_sequence and max_index > 0:
        # Convert to a Python list
        result = [None] * max_index
        for i in range(1, max_index + 1):  # Lua tables are 1-indexed
            if i in lua_table:
                value = lua_table[i]
                result[i-1] = lua_value_to_python(value)
        return result
    else:
        # Convert to a Python dictionary
        result = {}
        for k, v in lua_table.items():
            python_key = lua_value_to_python(k)
            python_value = lua_value_to_python(v)
            result[python_key] = python_value
        return result

def lua_value_to_python(value):
    """Convert a Lua value to its Python equivalent."""
    if value is None:
        return None
    
    value_type = type(value)
    
    # Handle bytes conversion to string
    if isinstance(value, bytes):
        return value.decode('utf-8')
    
    # If it's a basic type, return as is
    if value_type in (int, float, bool, str):
        return value
    
    # If it's a Lua table, convert recursively
    if hasattr(value, 'items'):
        return lua_table_to_python(value)
    
    # Default case
    return str(value)

def python_to_lua_table(lua, data, var_name=None):
    """Convert a Python dictionary or list to a Lua table string."""
    if isinstance(data, dict):
        lua_table = lua.table()
        for k, v in data.items():
            lua_table[k] = python_to_lua_value(lua, v)
    elif isinstance(data, list):
        lua_table = lua.table()
        for i, v in enumerate(data, 1):  # Lua tables are 1-indexed
            lua_table[i] = python_to_lua_value(lua, v)
    else:
        return str(data)
    
    # Get the table as a string
    table_to_string = lua.globals().table_to_string
    lua_str = table_to_string(lua_table)
    
    # Convert from bytes to string if needed
    if isinstance(lua_str, bytes):
        table_str = lua_str.decode('utf-8')
    else:
        table_str = str(lua_str)
    
    # Return as an assignment if var_name is provided
    if var_name:
        return f"{var_name} = {table_str}"
    else:
        return table_str

def python_to_lua_value(lua, value):
    """Convert a Python value to its Lua equivalent."""
    if value is None:
        return None
    elif isinstance(value, (int, float, bool, str)):
        return value
    elif isinstance(value, dict):
        lua_table = lua.table()
        for k, v in value.items():
            lua_table[k] = python_to_lua_value(lua, v)
        return lua_table
    elif isinstance(value, list):
        lua_table = lua.table()
        for i, v in enumerate(value, 1):  # Lua tables are 1-indexed
            lua_table[i] = python_to_lua_value(lua, v)
        return lua_table
    else:
        return str(value)

# GOOGLE SHEETS FUNCTIONS

def get_sheet_data(service, sheet_name):
    """Get data from a specific sheet."""
    try:
        result = service.spreadsheets().values().get(
            spreadsheetId=SPREADSHEET_ID,
            range=f"{sheet_name}!A1:Z1000"
        ).execute()
        
        values = result.get('values', [])
        
        if not values:
            print(f"[LOG] No data found in {sheet_name}")
            return []
            
        return values
    except Exception as e:
        print(f"[ERROR] Error getting sheet data: {e}")
        return []

def clear_sheet(service, sheet_name):
    """Clear all data from a specific sheet."""
    try:
        service.spreadsheets().values().clear(
            spreadsheetId=SPREADSHEET_ID,
            range=f"{sheet_name}!A1:Z1000",
            body={}
        ).execute()
        print(f"[LOG] Cleared {sheet_name} sheet")
    except Exception as e:
        print(f"[ERROR] Error clearing sheet: {e}")

def update_sheet(service, sheet_name, data):
    """Update a specific sheet with new data."""
    try:
        service.spreadsheets().values().update(
            spreadsheetId=SPREADSHEET_ID,
            range=f"{sheet_name}!A1",
            valueInputOption="RAW",
            body={"values": data}
        ).execute()
        print(f"[LOG] Updated {sheet_name} sheet")
    except Exception as e:
        print(f"[ERROR] Error updating sheet: {e}")

# CONVERSION FUNCTIONS

def lua_to_sheet_format(data, table_name):
    """Convert Lua table data (in Python form) to Google Sheets format."""
    if table_name == "DeathLoggerDB":
        # For indexed log entries
        sheet_data = [["Index", "timestamp", "playerName", "playerClass", "level", "killer", "zone", "accountName"]]
        if isinstance(data, dict):
            for idx, log_entry in sorted(data.items()):
                sheet_data.append([idx, log_entry])
        elif isinstance(data, list):
            for i, log_entry in enumerate(data, 1):
                sheet_data.append([i, log_entry])
        return sheet_data
    
    elif table_name == "LastLogonDB":
        # For character-timestamp mapping
        sheet_data = [["Character", "Last Logon"]]
        for char_name, timestamp in sorted(data.items()):
            sheet_data.append([char_name, timestamp])
        return sheet_data
    
    elif table_name == "CharacterProfessionsDB":
        # For character professions data
        sheet_data = [["Character", "Profession String", "Last Modified"]]
        for char_name, char_data in sorted(data.items()):
            sheet_data.append([
                char_name,
                char_data.get("professionString", ""),
                char_data.get("lastModified", "")
            ])
        return sheet_data
    
    return []

def sheet_to_lua_format(sheet_data, table_name):
    """Convert Google Sheets data to Lua table format (in Python form)."""
    if not sheet_data or len(sheet_data) <= 1:  # Empty or just header
        return {}
    
    if table_name == "DeathLoggerDB":
        result = {}
        # Skip header row
        for i in range(1, len(sheet_data)):
            row = sheet_data[i]
            
            if len(row) >= 8:
                index = int(row[0])
                result[index] = {
                    'timestamp': row[1],
                    'playerName': row[2],
                    'playerClass': row[3],
                    'level': row[4],
                    'killer': row[5],
                    'zone': row[6],
                    'accountName': row[7]
                }
        return result
           
    
    elif table_name == "LastLogonDB":
        result = {}
        # Skip header row
        for i in range(1, len(sheet_data)):
            row = sheet_data[i]
            if len(row) >= 2:
                char_name = row[0]
                timestamp = row[1]
                result[char_name] = timestamp
        return result
    
    elif table_name == "CharacterProfessionsDB":
        result = {}
        # Skip header row
        for i in range(1, len(sheet_data)):
            row = sheet_data[i]
            if len(row) >= 3:
                char_name = row[0]
                result[char_name] = {
                    'professionString': row[1],
                    'lastModified': row[2]
                }
        return result
    
    return {}

# FILE OPERATIONS

def read_lua_file(file_path):
    """Read a Lua file and return its content."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return f.read()
    except UnicodeDecodeError:
        # Try with different encoding if UTF-8 fails
        with open(file_path, 'r', encoding='cp1252') as f:
            return f.read()

def write_lua_file(file_path, content):
    """Write content to a Lua file."""
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

def clear_lua_table_in_file(file_path, table_name):
    """
    Clears a Lua table in a file by replacing its contents with an empty table
    while preserving all other content in the file.
    
    Args:
        file_path (str): Path to the Lua file
        table_name (str): Name of the Lua table to clear
    
    Returns:
        bool: True if successful, False otherwise
    """
    try:
        # Read the file content
        with open(file_path, 'r', encoding='utf-8') as file:
            lines = file.readlines()
        
        # Find the table in the file
        table_start_line = -1
        table_end_line = -1
        inside_table = False
        brace_count = 0
        
        for i, line in enumerate(lines):
            # Look for the table declaration
            if table_start_line == -1 and f"{table_name} = " in line and "{" in line:
                table_start_line = i
                inside_table = True
                brace_count = line.count("{") - line.count("}")
                
                # If the table opens and closes on the same line
                if brace_count == 0:
                    table_end_line = i
                    break
            
            # If we're inside the table, track braces to find the end
            elif inside_table:
                brace_count += line.count("{") - line.count("}")
                
                if brace_count == 0:
                    table_end_line = i
                    break
        
        # If we found the table
        if table_start_line != -1 and table_end_line != -1:
            # Create a new list of lines with the table cleared
            new_lines = lines[:table_start_line]  # Lines before table
            new_lines.append(f"{table_name} = {{}}\n")  # Empty table
            new_lines.extend(lines[table_end_line + 1:])  # Lines after table
            
            # Write the modified content back to the file
            with open(file_path, 'w', encoding='utf-8') as file:
                file.writelines(new_lines)
            
            return True
        else:
            print(f"Table '{table_name}' not found in the file.")
            return False
            
    except Exception as e:
        print(f"Error clearing Lua table: {e}")
        return False
    
def update_lua_table_in_file(lua, file_path, var_name, new_data):
    """Update a specific Lua table in a file without affecting other content."""
    try:
        # Read the current file content
        content = read_lua_file(file_path)
        
        # Load all existing variables from the file
        lua.execute(content)
        
        # Update the specified table with new data
        if var_name in lua.globals():
            # Convert new_data to Lua
            lua_table = lua.table()
            if isinstance(new_data, dict):
                for k, v in new_data.items():
                    lua_table[k] = python_to_lua_value(lua, v)
            elif isinstance(new_data, list):
                for i, v in enumerate(new_data, 1):
                    lua_table[i] = python_to_lua_value(lua, v)
            
            # Assign to the global variable
            lua.globals()[var_name] = lua_table
        else:
            # If variable doesn't exist, create it
            lua.execute(f"{var_name} = {{}}")
            # Then update it
            lua_table = lua.table()
            if isinstance(new_data, dict):
                for k, v in new_data.items():
                    lua_table[k] = python_to_lua_value(lua, v)
            elif isinstance(new_data, list):
                for i, v in enumerate(new_data, 1):
                    lua_table[i] = python_to_lua_value(lua, v)
            
            # Assign to the global variable
            lua.globals()[var_name] = lua_table
        
        # Now generate the updated file content
        variables = []
        
        # Get all known table variables
        table_names = ["DeathLoggerDB", "LastLogonDB", "CharacterProfessionsDB"]
        for name in table_names:
            if name in lua.globals():
                table_data = lua_table_to_python(lua.globals()[name])
                table_str = python_to_lua_table(lua, table_data, name)
                variables.append(table_str)
        
        # Get boolean variables
        bool_names = ["SyncLoaded"]
        for name in bool_names:
            if name in lua.globals():
                value = bool(lua.globals()[name])
                variables.append(f"{name} = {str(value).lower()}")
        
        # Get string variables (new)
        # You can extend this list with known string variable names
        string_names = ["CurrentCharacter"]
        for name in string_names:
            if name in lua.globals():
                value = lua.globals()[name]
                if isinstance(value, str):
                    # Properly escape the string and wrap in quotes
                    escaped_value = value.replace("\\", "\\\\").replace('"', '\\"')
                    variables.append(f'{name} = "{escaped_value}"')
        
        # Check for any other variables that might be in the globals but not in our predefined lists
        # This is a more generic approach to preserve all variables
        all_globals = [name for name in lua.globals() 
                      if not name.startswith('_') and name not in table_names 
                      and name not in bool_names and name not in string_names
                      and not callable(lua.globals()[name])]  # Filter out functions
        
        for name in all_globals:
            value = lua.globals()[name]
            if isinstance(value, str):
                # Handle strings
                escaped_value = value.replace("\\", "\\\\").replace('"', '\\"')
                variables.append(f'{name} = "{escaped_value}"')
            elif isinstance(value, (int, float)):
                # Handle numbers
                variables.append(f"{name} = {value}")
            elif isinstance(value, bool):
                # Handle booleans
                variables.append(f"{name} = {str(value).lower()}")
            # We already handled tables separately above
        
        # Combine everything into a new file
        new_content = "\n\n".join(variables)
        
        # Write back to the file
        write_lua_file(file_path, new_content)
        print(f"[LOG] Updated {var_name} in {file_path}")
        return True
    except Exception as e:
        print(f"[ERROR] Error updating Lua table: {e}")
        return False

def set_lua_var_in_file(lua, file_path, var_name, value):
    """
    Set a variable in a Lua file.
    Works with various data types (boolean, string, number, table).
    Preserves ALL existing content in the file and only updates the specific variable.
    
    Args:
        lua: The LuaRuntime instance
        file_path: Path to the Lua file
        var_name: Name of the variable to set
        value: Value to assign (can be bool, str, int, float, dict, list)
    
    Returns:
        bool: True if successful, False otherwise
    """
    try:
        # Read the current file content
        content = read_lua_file(file_path)
        
        # Prepare the new value as a string
        if isinstance(value, bool):
            value_str = str(value).lower()
        elif isinstance(value, (int, float)):
            value_str = str(value)
        elif isinstance(value, str):
            value_str = f'"{value}"'
        elif isinstance(value, (dict, list)):
            # For complex types, use the table conversion
            value_str = python_to_lua_table(lua, value).replace(f"{var_name} = ", "")
        else:
            value_str = f'"{str(value)}"'
            
        # Check if variable already exists in the file
        import re
        pattern = re.compile(rf'{var_name}\s*=\s*[^,\r\n]*')
        match = pattern.search(content)
        
        if match:
            # Variable exists, update it in place
            old_assignment = match.group(0)
            new_assignment = f"{var_name} = {value_str}"
            modified_content = content.replace(old_assignment, new_assignment)
            
            print(f"[LOG] Updated existing variable {var_name} in {file_path}")
        else:
            # Variable doesn't exist, append it to the end of the file
            if content and not content.endswith('\n'):
                modified_content = content + f"\n\n{var_name} = {value_str}"
            else:
                modified_content = content + f"{var_name} = {value_str}"
                
            print(f"[LOG] Added new variable {var_name} to {file_path}")
        
        # Write back to file
        write_lua_file(file_path, modified_content)
        return True
        
    except Exception as e:
        print(f"[ERROR] Error setting variable in Lua file: {e}")
        return False

# WOW INTEGRATION

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

    global shouldStartGame
    shouldStartGame = False
    print("[LOG] Sync done.")
    
    # Get the full path to wow.exe/vanilla.exe
    exe_path = "../../../VanillaFixes.exe"

    # Check if the VanillaFixes exists, if not, set it to WoW.exe
    if not os.path.exists(exe_path):
        exe_path = "../../../WoW.exe"
    
    print("[DEBUG] Attempting to launch WoW from:", exe_path)

    # Then launch it
    try:
        global wow_process, isGameRunning
        wow_process = subprocess.Popen([exe_path])
        isGameRunning = True
        
    except FileNotFoundError:
        print("[ERROR] WoW executable not found at:", exe_path)
        exit(1)

    print("[LOG] Launching Turtle WoW... Please dont close this window while playing!")

# MAIN SYNC FUNCTION

def sync_loop():
    """Main sync loop that periodically checks for changes and syncs with Google Sheets."""
    service = get_sheets_service()
    lua = initialize_lua()
    
    global_last_modified = None
    local_last_modified = None

    validate_saved_variables()

    print(f"[LOG] Syncing with online database...")

    while True:
        try:
            global LOCAL_CHARACTER_PATH
            global isFirstCheck, isGameRunning, shouldReset 

            # Check if WoW is still running or we exit
            if isGameRunning and not is_wow_running():
                print("[LOG] WoW has exited. Shutting down sync.")
                break

            # Lets not check local character stuff on first run as we might have changed character.
            if not isFirstCheck and file_exists(LOCAL_CHARACTER_PATH):

                #Get local character savedVariables and see if file modified
                local_file_stats = os.stat(LOCAL_CHARACTER_PATH)
                local_mod_time = local_file_stats.st_mtime

                if local_last_modified is None or local_mod_time != local_last_modified:

                    print("[LOG] Local changes detected!")
                    content = read_lua_file(LOCAL_CHARACTER_PATH)
                    
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
                    local_file_stats = os.stat(LOCAL_CHARACTER_PATH)
                    local_last_modified = local_file_stats.st_mtime


            # Get global savedVariables and see if file modified
            global_file_stats = os.stat(GLOBAL_ACCOUNT_PATH)
            global_mod_time = global_file_stats.st_mtime

            if global_last_modified is None or global_mod_time != global_last_modified:
                    
                if isFirstCheck:
                    print("[LOG] Doing initial setup...") 
                else:
                    print("[LOG] Global file change detected.")
                
                try_and_set_character_path(lua)
                
                if isFirstCheck:
                    download_all_tables()
                    isFirstCheck = False
                    # Set SyncLoaded to true on first check
                    set_lua_var_in_file(lua, GLOBAL_ACCOUNT_PATH, "SyncLoaded", True)
                    
                    if shouldStartGame:
                        sync_ready_start_wow()
                else:
                    download_all_tables()
                
                # Update last_modified
                global_file_stats = os.stat(GLOBAL_ACCOUNT_PATH)
                global_last_modified = global_file_stats.st_mtime
        
        except Exception as e:
            print(f"[WARNING] Error: {e}")

        time.sleep(2)

# UTILITY FUNCTIONS

def validate_saved_variables():
    # Required variables that should be present in the file
    required_vars = [
        "DeathLoggerDB",
        "LastLogonDB",
        "CharacterProfessionsDB",
        "SyncLoaded",
        "CurrentCharacter"
    ]
    
    # Default content to write if file is missing or invalid
    default_content = "DeathLoggerDB = { }\nLastLogonDB = { }\nCharacterProfessionsDB = { }\nSyncLoaded = false\nCurrentCharacter = \"\""
    
    # Check if SavedVariables file exists
    if os.path.exists(GLOBAL_ACCOUNT_PATH):
        print(f"[LOG] File '{GLOBAL_ACCOUNT_PATH}' exists. Validating content...")
        
        # Read file content
        with open(GLOBAL_ACCOUNT_PATH, 'r', encoding='cp1252') as f:
            content = f.read()
        
        # Check if all required variables are present
        all_vars_present = all(var in content for var in required_vars)
        
        if not all_vars_present:
            print(f"[LOG] File '{GLOBAL_ACCOUNT_PATH}' is missing required variables. Recreating it...")
            with open(GLOBAL_ACCOUNT_PATH, 'w', encoding='cp1252') as f:
                f.write(default_content)
        else:
            print(f"[LOG] File '{GLOBAL_ACCOUNT_PATH}' is valid.")
    else:
        # File doesn't exist, create it
        print(f"[LOG] File '{GLOBAL_ACCOUNT_PATH}' does not exist. Creating it...")
        with open(GLOBAL_ACCOUNT_PATH, 'w', encoding='cp1252') as f:
            f.write(default_content)

def try_and_set_character_path(lua):
    content = read_lua_file(GLOBAL_ACCOUNT_PATH)
    content = content.strip()
    if content:
        currentCharacter = extract_lua_var(lua, content, "CurrentCharacter", default= "")
        if currentCharacter:
            print("[LOG] CurrentCharacter detected: " + currentCharacter + ". Setting local character path..")
            LOCAL_CHARACTER_PATH = "../../../WTF/Account/" + currentAccountName + "/Nordanaar/CHARACTERNAME/SavedVariables/SaellskapsresanMod.lua"
            LOCAL_CHARACTER_PATH = LOCAL_CHARACTER_PATH.replace("CHARACTERNAME", currentCharacter)
            print("[LOG] LOCAL_CHARACTER_PATH: " + LOCAL_CHARACTER_PATH)
            return True
        else:
            print("[LOG] Current character not set. Should prompt user to reload!")
            return False
    else:
        print("[WARNING] Global Account path NOT detected.")
        return False

def file_exists(file_path):
    """
    Safely check if a file exists at the specified location.
    
    Args:
        file_path (str): Path to the file to check
        
    Returns:
        bool: True if the file exists, False otherwise
    """
    return os.path.isfile(file_path) and os.access(file_path, os.R_OK)

def upload_death_log(service, lua, deathLog):
    """Add a death log entry to the DeathLoggerDB sheet."""
    
    global currentAccountName
    timestamp = deathLog["timestamp"]
    playerName = deathLog["playerName"]
    playerClass = deathLog["playerClass"]
    level = deathLog["level"]
    killer = deathLog["killer"]
    zone = deathLog["zone"]
    accountName = currentAccountName.capitalize()

    sheet_data = get_sheet_data(service, DEATH_LOGGER_SHEET)

    # Find the highest index currently in use
    highest_index = 0
    if sheet_data and len(sheet_data) > 1:  # If there's data beyond the header
        try:
            # Assuming first column contains indices
            indices = [int(row[0]) for row in sheet_data[1:] if row and row[0] and str(row[0]).isdigit()]
            if indices:
                highest_index = max(indices)
        except Exception as e:
            print(f"[ERROR] Error finding highest index: {e}")
    
    # Use the next available index
    next_index = highest_index + 1

    # Create the row data for this character
    row_data = [next_index, timestamp, playerName, playerClass, level, killer, zone, accountName]

    # Add the new row to the sheet
    if sheet_data:
        append_to_sheet(service, DEATH_LOGGER_SHEET, [row_data])
    else:
        header = ["Index", "timestamp", "playerName", "playerClass", "level", "killer", "zone", "accountName"]
        update_sheet(service, DEATH_LOGGER_SHEET, [header, row_data])

    print(f"[LOG] Added new deathlog for player {playerName} on index: {next_index}")

    # Also update global Lua file to keep in sync
    content = read_lua_file(GLOBAL_ACCOUNT_PATH)
    data = extract_lua_table(lua, content, "DeathLoggerDB")
    
    # Convert list to dict with 1-based indexing
    if isinstance(data, list):
        dictData = {}
        for i, item in enumerate(data):
            dictData[i+1] = item  # i+1 gives 1-based indexing
        data = dictData

    if next_index not in data:
        data[next_index] = {}
    
    data[next_index]["timestamp"] = timestamp
    data[next_index]["playerName"] = playerName
    data[next_index]["playerClass"] = playerClass
    data[next_index]["level"] = level
    data[next_index]["killer"] = killer
    data[next_index]["zone"] = zone
    data[next_index]["accountName"] = accountName

    update_lua_table_in_file(lua, GLOBAL_ACCOUNT_PATH, "DeathLoggerDB", data)

    #We can now remove the local entry, so we dont upload it again
    clear_lua_table_in_file(LOCAL_CHARACTER_PATH, "LocalDeathLoggerDB")
    
    return True

def update_character_professions(service, lua, character, profession_string, last_modified=None):
    """Update a single character's profession with timestamp-based conflict resolution."""
    
    if last_modified is None:
        last_modified = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    # First, get the current sheet data to find info about this character
    sheet_data = get_sheet_data(service, CHARACTER_PROFESSIONS_SHEET)
    
    # Find the row index and current data for this character
    character_row = None
    remote_last_modified = None
    
    for i, row in enumerate(sheet_data):
        if row and len(row) > 0 and row[0] == character:
            character_row = i
            if len(row) >= 3:  # Make sure we have a timestamp column
                remote_last_modified = row[2]
            break
    
    # Check for timestamp conflicts
    if remote_last_modified:
        try:
            remote_timestamp = datetime.strptime(remote_last_modified, "%Y-%m-%d %H:%M:%S")
            local_timestamp = datetime.strptime(last_modified, "%Y-%m-%d %H:%M:%S")
            
            # If remote is newer, don't overwrite it
            if remote_timestamp > local_timestamp:
                print(f"[WARNING] Remote data for {character} is newer. Not updating.")
                return False
        except ValueError:
            # If timestamp parsing fails, proceed with update
            print(f"[WARNING] Could not parse timestamp for {character}, proceeding with update.")
    
    # Create the row data for this character
    row_data = [[character, profession_string, last_modified]]
    
    # Update or append to the sheet
    if character_row is not None:
        # Update existing row
        update_range = f"{CHARACTER_PROFESSIONS_SHEET}!A{character_row+1}:C{character_row+1}"
        result = update_sheet_range(service, update_range, row_data)
        print(f"[LOG] Updated existing row for {character}")
    else:
        # Append new row
        result = append_to_sheet(service, CHARACTER_PROFESSIONS_SHEET, row_data)
        print(f"[LOG] Added new row for {character}")
    
    # Also update local Lua file to keep in sync
    content = read_lua_file(GLOBAL_ACCOUNT_PATH)
    data = extract_lua_table(lua, content, "CharacterProfessionsDB")
    
    if character not in data:
        data[character] = {}
    
    data[character]["professionString"] = profession_string
    data[character]["lastModified"] = last_modified
    
    update_lua_table_in_file(lua, GLOBAL_ACCOUNT_PATH, "CharacterProfessionsDB", data)
    
    return True

def update_last_logon(service, lua, character, timestamp):
    """Update a character's last logon timestamp."""
    
    # Get current data
    content = read_lua_file(GLOBAL_ACCOUNT_PATH)
    data = extract_lua_table(lua, content, "LastLogonDB")
    
    # Update the timestamp
    data[character] = timestamp
    
    # Update local file
    # update_lua_table_in_file(lua, GLOBAL_ACCOUNT_PATH, "LastLogonDB", data)
    
    # Update sheet
    sheet_data = lua_to_sheet_format(data, "LastLogonDB")
    update_sheet(service, LAST_LOGON_SHEET, sheet_data)
    
    print(f"[LOG] Updated last logon for {character} to {timestamp}")
    return True

def update_sheet_range(service, range_name, values):
    """Update a specific range in the Google Sheet."""
    body = {
        'values': values
    }
    result = service.spreadsheets().values().update(
        spreadsheetId=SPREADSHEET_ID, 
        range=range_name,
        valueInputOption='USER_ENTERED', 
        body=body).execute()
    return result

def append_to_sheet(service, sheet_name, values):
    """Append rows to the Google Sheet."""
    body = {
        'values': values
    }
    result = service.spreadsheets().values().append(
        spreadsheetId=SPREADSHEET_ID, 
        range=sheet_name,
        valueInputOption='USER_ENTERED', 
        insertDataOption='INSERT_ROWS',
        body=body).execute()
    return result

def get_sheet_data(service, sheet_name):
    """Retrieve all data from the specified sheet."""
    result = service.spreadsheets().values().get(
        spreadsheetId=SPREADSHEET_ID,
        range=sheet_name).execute()
    return result.get('values', [])

def download_all_tables():
    """Download all tables from Google Sheets to the local Lua file."""
    service = get_sheets_service()
    lua = initialize_lua()
    
    for table_name, sheet_name in [
        ("DeathLoggerDB", DEATH_LOGGER_SHEET),
        ("LastLogonDB", LAST_LOGON_SHEET),
        ("CharacterProfessionsDB", CHARACTER_PROFESSIONS_SHEET)
    ]:
        sheet_data = get_sheet_data(service, sheet_name)
        lua_data = sheet_to_lua_format(sheet_data, table_name)
        update_lua_table_in_file(lua, GLOBAL_ACCOUNT_PATH, table_name, lua_data)
    
    print(f"[LOG] Downloaded all tables from Google Sheets")
    return True

def create_and_share_spreadsheet(admin_email):
    """
    Create a new Google Spreadsheet with the required sheets and share it with admin.
    
    Args:
        admin_email: Email address to share the spreadsheet with
        
    Returns:
        The ID of the newly created spreadsheet
    """
    # We need additional scope for creating and sharing files
    credentials = service_account.Credentials.from_service_account_file(
        SERVICE_ACCOUNT_FILE,
        scopes=['https://www.googleapis.com/auth/spreadsheets',
                'https://www.googleapis.com/auth/drive']
    )
    
    # Create Drive and Sheets services
    drive_service = build('drive', 'v3', credentials=credentials)
    sheets_service = build('sheets', 'v4', credentials=credentials)
    
    try:
        # Create a new spreadsheet with the required sheets
        spreadsheet_body = {
            'properties': {'title': 'SaellskapsresanMod'},
            'sheets': [
                {'properties': {'title': DEATH_LOGGER_SHEET}},
                {'properties': {'title': LAST_LOGON_SHEET}},
                {'properties': {'title': CHARACTER_PROFESSIONS_SHEET}}
            ]
        }
        
        spreadsheet = sheets_service.spreadsheets().create(body=spreadsheet_body).execute()
        spreadsheet_id = spreadsheet['spreadsheetId']
        print(f"[LOG] Created new spreadsheet with ID: {spreadsheet_id}")
        
        # Initialize each sheet with headers
        # DeathLoggerDB headers
        sheets_service.spreadsheets().values().update(
            spreadsheetId=spreadsheet_id,
            range=f"{DEATH_LOGGER_SHEET}!A1",
            valueInputOption="RAW",
            body={"values": [["ID", "Log Entry"]]}
        ).execute()
        
        # LastLogonDB headers
        sheets_service.spreadsheets().values().update(
            spreadsheetId=spreadsheet_id,
            range=f"{LAST_LOGON_SHEET}!A1",
            valueInputOption="RAW",
            body={"values": [["Character", "Last Logon"]]}
        ).execute()
        
        # CharacterProfessionsDB headers
        sheets_service.spreadsheets().values().update(
            spreadsheetId=spreadsheet_id,
            range=f"{CHARACTER_PROFESSIONS_SHEET}!A1",
            valueInputOption="RAW",
            body={"values": [["Character", "Profession String", "Last Modified"]]}
        ).execute()
        
        # Share the spreadsheet with the admin
        permission = {
            'type': 'user',
            'role': 'writer',
            'emailAddress': admin_email
        }
        
        drive_service.permissions().create(
            fileId=spreadsheet_id,
            body=permission,
            fields='id',
            sendNotificationEmail=True
        ).execute()
        
        print(f"[LOG] Shared spreadsheet with {admin_email}")
        
        # Return the spreadsheet ID for further use
        return spreadsheet_id
    
    except Exception as e:
        print(f"[ERROR] Error creating/sharing spreadsheet: {e}")
        return None

if __name__ == "__main__":

    # Create a new spreadsheet and share it with your admin account
    # You only need to run this once for initial setup
    # admin_email = "jimmy.saarela@gmail.com"  # Replace with your email
    # new_spreadsheet_id = create_and_share_spreadsheet(admin_email)
    # if new_spreadsheet_id:
    #     print(f"Created and shared new spreadsheet. Use this ID: {new_spreadsheet_id}")
    #     # You can now update your script with this ID:
    #     print("Updating spreadsheet_id")
    #     SPREADSHEET_ID = new_spreadsheet_id
        
    # Start the sync loop (main function)
    sync_loop()