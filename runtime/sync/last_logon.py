from config import LAST_LOGON_SHEET, GLOBAL_ACCOUNT_PATH
from utils.file_operations import read_lua_file, clear_lua_table_in_file
from utils.lua_operations import extract_lua_table, update_lua_table_in_file
from google_sheets.operations import update_sheet
from google_sheets.converters import lua_to_sheet_format

def update_last_logon(service, lua, character, timestamp):
    """Update a character's last logon timestamp."""
    
    # Get current data
    content = read_lua_file(GLOBAL_ACCOUNT_PATH)
    data = extract_lua_table(lua, content, "LastLogonDB")
    
    # Update the timestamp
    data[character] = timestamp
    
    # Update local file
    update_lua_table_in_file(lua, GLOBAL_ACCOUNT_PATH, "LastLogonDB", data)
    
    # Update sheet
    sheet_data = lua_to_sheet_format(data, "LastLogonDB")
    update_sheet(service, LAST_LOGON_SHEET, sheet_data)
    
    print(f"[LOG] Updated last logon for {character} to {timestamp}")
    
    # Clear the local data so it doesn't get reprocessed
    from config import LOCAL_CHARACTER_PATH
    clear_lua_table_in_file(LOCAL_CHARACTER_PATH, "LocalLastLogonDB")
    
    return True