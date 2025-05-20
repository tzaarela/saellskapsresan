from config import DEATH_LOGGER_SHEET, GLOBAL_ACCOUNT_PATH, LOCAL_CHARACTER_PATH, currentAccountName
from google_sheets.operations import get_sheet_data, append_to_sheet, update_sheet
from utils.lua_operations import extract_lua_table, update_lua_table_in_file
from utils.file_operations import read_lua_file, clear_lua_table_in_file

def upload_death_log(service, lua, deathLog):
    """Add a death log entry to the DeathLoggerDB sheet."""
    
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

    # We can now remove the local entry, so we dont upload it again
    clear_lua_table_in_file(LOCAL_CHARACTER_PATH, "LocalDeathLoggerDB")
    
    return True