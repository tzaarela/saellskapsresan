from datetime import datetime
from config import CHARACTER_PROFESSIONS_SHEET, GLOBAL_ACCOUNT_PATH, LOCAL_CHARACTER_PATH
from google_sheets.operations import get_sheet_data, update_sheet_range, append_to_sheet
from utils.lua_operations import extract_lua_table, update_lua_table_in_file
from utils.file_operations import read_lua_file, clear_lua_table_in_file

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
    
    # Clear the local data so it doesn't get reprocessed
    clear_lua_table_in_file(LOCAL_CHARACTER_PATH, "LocalCharacterProfessionsDB")
    
    return True