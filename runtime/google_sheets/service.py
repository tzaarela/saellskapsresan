from google.oauth2 import service_account
from googleapiclient.discovery import build
from google.oauth2 import service_account
from googleapiclient.discovery import build
from config import SCOPES, SERVICE_ACCOUNT_FILE, SPREADSHEET_ID

def get_sheets_service():
    """Create and return a Google Sheets service object."""
    credentials = service_account.Credentials.from_service_account_file(
        SERVICE_ACCOUNT_FILE, scopes=SCOPES)
    return build('sheets', 'v4', credentials=credentials)

def create_and_share_spreadsheet(admin_email):
    """
    Create a new Google Spreadsheet with the required sheets and share it with admin.
    
    Args:
        admin_email: Email address to share the spreadsheet with
        
    Returns:
        The ID of the newly created spreadsheet
    """
    from config import DEATH_LOGGER_SHEET, LAST_LOGON_SHEET, CHARACTER_PROFESSIONS_SHEET
    
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