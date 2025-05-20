import os

# Read account name
with open("../accountname.txt", "r") as f:
    currentAccountName = f.read().strip().upper()

# Path templates
path = "../../../../WTF/Account/ACCOUNTNAME/SavedVariables/SaellskapsresanMod.lua"
GLOBAL_ACCOUNT_PATH = path.replace("ACCOUNTNAME", currentAccountName)
LOCAL_CHARACTER_PATH = "../../../../WTF/Account/" + currentAccountName + "/Nordanaar/CHARACTERNAME/SavedVariables/SaellskapsresanMod.lua"

# Google API constants
SCOPES = ['https://www.googleapis.com/auth/spreadsheets']
SERVICE_ACCOUNT_FILE = 'service-account.json'
SPREADSHEET_ID = '1IarFvH3gl3y1MGlId3SwrvqLVfYiIR8KwX3dOE8R5II'

# Sheet names
DEATH_LOGGER_SHEET = 'DeathLoggerDB'
LAST_LOGON_SHEET = 'LastLogonDB'
CHARACTER_PROFESSIONS_SHEET = 'CharacterProfessionsDB'

# Default content for saved variables file
DEFAULT_SAVEDVARS_CONTENT = "DeathLoggerDB = { }\nLastLogonDB = { }\nCharacterProfessionsDB = { }\nSyncLoaded = false\nCurrentCharacter = \"\""

# Required variables that should be present in the file
REQUIRED_SAVEDVARS = [
    "DeathLoggerDB",
    "LastLogonDB",
    "CharacterProfessionsDB",
    "SyncLoaded",
    "CurrentCharacter"
]

# Global state variables (will be set in main.py)
shouldReset = False
shouldNotDownload = False
character_name_debug = None
shouldStartGame = True
isGameRunning = False
isFirstCheck = True
wow_process = None