import os
import sys

# Get the directory where this script is located
script_dir = os.path.dirname(os.path.abspath(__file__))


print("Script Directory: " )
# Build the path to accountname.txt relative to the script location
account_file_path = os.path.join(script_dir, "..", "accountname.txt")

# Read account name
with open(account_file_path, "r") as f:
    currentAccountName = f.read().strip().upper()

# Path templates
path = "../../../../WTF/Account/ACCOUNTNAME/SavedVariables/SaellskapsresanMod.lua"
GLOBAL_ACCOUNT_PATH = path.replace("ACCOUNTNAME", currentAccountName)
LOCAL_CHARACTER_PATH = "../../../../WTF/Account/" + currentAccountName + "/Nordanaar/CHARACTERNAME/SavedVariables/SaellskapsresanMod.lua"

# Google API constants
SCOPES = ['https://www.googleapis.com/auth/spreadsheets']
SERVICE_ACCOUNT_FILE = os.path.join(script_dir, "service-account.json")
SPREADSHEET_ID = '1IarFvH3gl3y1MGlId3SwrvqLVfYiIR8KwX3dOE8R5II'

# Sheet names
DEATH_LOGGER_SHEET = 'DeathLoggerDB'
LAST_LOGON_SHEET = 'LastLogonDB'
CHARACTER_PROFESSIONS_SHEET = 'CharacterProfessionsDB'
CHARACTER_STATS_SHEET = 'CharacterStatsDB'
LEADERBOARDS_SHEET = 'LeaderboardsDB'

# Default content for saved variables file
DEFAULT_SAVEDVARS_CONTENT = "DeathLoggerDB = { }\nLastLogonDB = { }\nCharacterProfessionsDB = { }\nCharacterStatsDB = { }\LeaderboardsDB = { }\nSyncLoaded = false\nCurrentCharacter = \"\""

# Required variables that should be present in the file
REQUIRED_SAVEDVARS = [
    "DeathLoggerDB",
    "LastLogonDB",
    "CharacterProfessionsDB",
    "SyncLoaded",
    "CharacterStatsDB",
    "CurrentCharacter",
    "LeaderboardsDB"
]

# Global state variables (will be set in main.py)
shouldReset = False
shouldNotDownload = False
character_name_debug = None
shouldStartGame = True
isGameRunning = False
isFirstCheck = True
wow_process = None