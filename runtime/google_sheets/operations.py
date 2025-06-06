from config import SPREADSHEET_ID
from google_sheets.service import get_sheets_service

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

def update_sheet_value_by_key(service, sheet_name, key_column_index, key_value, update_column_index, update_value):
    """
    Update a specific value in a Google Sheet based on a matching key.
    
    Parameters:
    - service: Google Sheets API service object
    - sheet_name: Name of the sheet
    - key_column_index: Index of the column containing keys (0-based)
    - key_value: The key value to match (string or number)
    - update_column_index: Index of the column to update (0-based)
    - update_value: New value to set
    
    Returns:
    - Result of the update operation or None if key not found

    # Example: Update a player's gold amount by player ID
    update_sheet_value_by_key(
        service=service,
        sheet_name='Players',
        key_column_index=0,  # Assuming player ID is in the first column
        key_value='player123',
        update_column_index=2,  # Assuming gold is in the third column
        update_value=500
    )
    """
    # First, get all values from the sheet
    result = service.spreadsheets().values().get(
        spreadsheetId=SPREADSHEET_ID,
        range=sheet_name
    ).execute()
    
    rows = result.get('values', [])
    if not rows:
        return None
    
    # Find the row with the matching key
    row_index = None
    for i, row in enumerate(rows):
        if len(row) > key_column_index and str(row[key_column_index]) == str(key_value):
            row_index = i
            break
    
    if row_index is None:
        return None  # Key not found
    
    # Calculate the cell range to update (e.g., 'Sheet1!C5')
    row_position = row_index + 1  # Sheets are 1-indexed
    update_column_letter = chr(ord('A') + update_column_index)
    cell_range = f"{sheet_name}!{update_column_letter}{row_position}"
    
    # Update the cell
    update_body = {
        'values': [[update_value]]
    }
    
    update_result = service.spreadsheets().values().update(
        spreadsheetId=SPREADSHEET_ID,
        range=cell_range,
        valueInputOption='USER_ENTERED',
        body=update_body
    ).execute()
    
    return update_result

def update_table_in_sheet(service, sheet_name, key_column_index, key_value, updates_dict, header_row=0):
    """
    Update multiple values in a Google Sheet row based on a matching key and a dictionary of updates.
    If the key doesn't exist, create a new row with the key and provided values.
    
    Parameters:
    - service: Google Sheets API service object
    - sheet_name: Name of the sheet
    - key_column_index: Index of the column containing keys (0-based)
    - key_value: The key value to match (string or number)
    - updates_dict: Dictionary where keys are column headers and values are new values to set
    - header_row: Index of the row containing headers (0-based), default is 0 (first row)
    
    Returns:
    - Dictionary of update results or dictionary with create result if new row added
    """

    print(f"[DEBUG] Starting update_table_in_sheet for key '{key_value}' in sheet '{sheet_name}'")
    print(f"[DEBUG] Updates to apply: {updates_dict}")

    # Get all values from the sheet
    try:
        print(f"[DEBUG] Fetching data from sheet '{sheet_name}'")
        result = service.spreadsheets().values().get(
            spreadsheetId=SPREADSHEET_ID,
            range=sheet_name
        ).execute()
        print(f"[DEBUG] Successfully fetched sheet data")
    except Exception as e:
        print(f"[ERROR] Failed to fetch sheet data: {str(e)}")
        return {"error": f"Failed to fetch sheet data: {str(e)}"}
    
    rows = result.get('values', [])
    print(f"[DEBUG] Found {len(rows)} rows in sheet")
    
    if not rows or len(rows) <= header_row:
        print(f"[WARNING] No rows found or header row ({header_row}) out of range")
        return None
    
    # Get the headers
    headers = rows[header_row]
    print(f"[DEBUG] Headers: {headers}")
    
    # Find the row with the matching key
    data_row_index = None
    print(f"[DEBUG] Searching for key '{key_value}' in column {key_column_index}")
    
    for i, row in enumerate(rows):
        # Skip header row and rows that are too short
        if i == header_row:
            print(f"[DEBUG] Skipping header row {i}")
            continue
            
        if len(row) <= key_column_index:
            print(f"[DEBUG] Skipping row {i} - too short (length {len(row)}, need at least {key_column_index+1})")
            continue
            
        print(f"[DEBUG] Row {i}, key column value: '{row[key_column_index]}' vs '{key_value}'")
        if str(row[key_column_index]) == str(key_value):
            data_row_index = i
            print(f"[DEBUG] Key found at row index {data_row_index}")
            break
    
    # Map header names to column indices
    header_to_index = {header: idx for idx, header in enumerate(headers)}
    print(f"[DEBUG] Header to index mapping: {header_to_index}")
    
    if data_row_index is None:
        print(f"[INFO] Key '{key_value}' not found, creating a new entry")
        
        # Create a new row with the key and values
        new_row = [""] * len(headers)  # Initialize with empty strings
        new_row[key_column_index] = key_value  # Set the key value
        
        # Fill in the values from updates_dict
        for column_header, new_value in updates_dict.items():
            if column_header in header_to_index:
                column_index = header_to_index[column_header]
                new_row[column_index] = new_value
                print(f"[DEBUG] Setting column '{column_header}' (index {column_index}) to '{new_value}'")
            else:
                print(f"[WARNING] Column header '{column_header}' not found in headers")
        
        print(f"[DEBUG] New row to be created: {new_row}")
        
        # Append the new row to the sheet
        append_range = f"{sheet_name}!A{len(rows) + 1}"
        append_body = {
            'values': [new_row]
        }
        
        print(f"[DEBUG] Appending to range: {append_range}")
        
        try:
            append_result = service.spreadsheets().values().append(
                spreadsheetId=SPREADSHEET_ID,
                range=append_range,
                valueInputOption='USER_ENTERED',
                insertDataOption='INSERT_ROWS',
                body=append_body
            ).execute()
            
            print(f"[INFO] Created new row successfully: {append_result.get('updates', {}).get('updatedRows', 0)} rows updated")
            return {"created": True, "row": new_row}
        except Exception as e:
            print(f"[ERROR] Error creating new row: {str(e)}")
            return {"created": False, "error": str(e)}
    
    # Update each field in the updates_dict for existing row
    print(f"[DEBUG] Updating existing row at index {data_row_index}")
    results = {}
    for column_header, new_value in updates_dict.items():
        # Look up the column index for this header
        if column_header not in header_to_index:
            print(f"[WARNING] Column header '{column_header}' not found in headers, skipping")
            continue  # Skip headers that don't exist
            
        column_index = header_to_index[column_header]
        column_letter = chr(ord('A') + column_index)
        row_position = data_row_index + 1  # Sheets are 1-indexed
        
        cell_range = f"{sheet_name}!{column_letter}{row_position}"
        print(f"[DEBUG] Updating cell range: {cell_range} with value: '{new_value}'")
        
        update_body = {
            'values': [[new_value]]
        }
        
        try:
            update_result = service.spreadsheets().values().update(
                spreadsheetId=SPREADSHEET_ID,
                range=cell_range,
                valueInputOption='USER_ENTERED',
                body=update_body
            ).execute()
            
            print(f"[DEBUG] Updated column '{column_header}' successfully: {update_result.get('updatedCells', 0)} cells updated")
            results[column_header] = True
        except Exception as e:
            print(f"[ERROR] Error updating column '{column_header}': {str(e)}")
            results[column_header] = False
    
    print(f"[INFO] Update complete, results: {results}")
    return results

