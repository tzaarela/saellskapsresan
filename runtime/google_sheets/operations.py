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
    
    Parameters:
    - service: Google Sheets API service object
    - sheet_name: Name of the sheet
    - key_column_index: Index of the column containing keys (0-based)
    - key_value: The key value to match (string or number)
    - updates_dict: Dictionary where keys are column headers and values are new values to set
    - header_row: Index of the row containing headers (0-based), default is 0 (first row)
    
    Returns:
    - Dictionary of update results or None if key not found
    
    Example: Update multiple stats for a player using column headers
    player_updates = {
        'Gold': 500,
        'Level': 10,
        'LastLogin': '2025-05-21',
        'Status': 'Active'
    }

    update_table_in_sheet(
    service=service,
    sheet_name='Players',
    key_column_index=0,  # Assuming player ID is in the first column
    key_value='player123',
    updates_dict=player_updates
)
    """


    # Get all values from the sheet
    result = service.spreadsheets().values().get(
        spreadsheetId=SPREADSHEET_ID,
        range=sheet_name
    ).execute()
    
    rows = result.get('values', [])
    if not rows or len(rows) <= header_row:
        return None
    
    # Get the headers
    headers = rows[header_row]
    
    # Find the row with the matching key
    data_row_index = None
    for i, row in enumerate(rows):
        # Skip header row and rows that are too short
        if i == header_row or len(row) <= key_column_index:
            continue
            
        if str(row[key_column_index]) == str(key_value):
            data_row_index = i
            break
    
    if data_row_index is None:
        return None  # Key not found
    
    # Map header names to column indices
    header_to_index = {header: idx for idx, header in enumerate(headers)}
    
    # Update each field in the updates_dict
    results = {}
    for column_header, new_value in updates_dict.items():
        # Look up the column index for this header
        if column_header not in header_to_index:
            continue  # Skip headers that don't exist
            
        column_index = header_to_index[column_header]
        column_letter = chr(ord('A') + column_index)
        row_position = data_row_index + 1  # Sheets are 1-indexed
        
        cell_range = f"{sheet_name}!{column_letter}{row_position}"
        
        update_body = {
            'values': [[new_value]]
        }
        
        update_result = service.spreadsheets().values().update(
            spreadsheetId=SPREADSHEET_ID,
            range=cell_range,
            valueInputOption='USER_ENTERED',
            body=update_body
        ).execute()
        
        results[column_header] = update_result
    
    return results


