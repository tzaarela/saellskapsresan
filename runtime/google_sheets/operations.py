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