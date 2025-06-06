import config
from utils.file_operations import read_lua_file, clear_lua_table_in_file
from utils.lua_operations import extract_lua_table
from google_sheets.operations import update_table_in_sheet

def update_character_stats(service, characterName, data):
    
    character_stats_data = {
        'AccountName': config.currentAccountName,
        'IsAlive': data[characterName]["IsAlive"],
        'Class': data[characterName]["Class"],
        'Level': data[characterName]["Level"],
        'Race': data[characterName]["Race"],
        'CrittersKilled': data[characterName]["CrittersKilled"],
        'HighestCrit': data[characterName]["HighestCrit"],
        'LastModified': data[characterName]["LastModified"]
    }

    print(f"[LOG] Updating Stats table in sheets")
    update_table_in_sheet(
        service=service,
        sheet_name=config.CHARACTER_STATS_SHEET,
        key_column_index=0,  # Assuming characterName is in the first column
        key_value=characterName,
        updates_dict=character_stats_data
    )
    
    print(f"[LOG] Updated stats for {characterName}")
    
    # Clear the local data so it doesn't get reprocessed
    clear_lua_table_in_file(config.LOCAL_CHARACTER_PATH, "LocalCharacterStatsDB")
    
    return True