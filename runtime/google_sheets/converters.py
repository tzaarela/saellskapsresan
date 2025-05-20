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