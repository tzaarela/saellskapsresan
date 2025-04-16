import os
import time
import re
import io
import ast
import argparse
import subprocess
import psutil

from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload, MediaIoBaseDownload
from googleapiclient.errors import HttpError
from datetime import datetime


SCOPES = ['https://www.googleapis.com/auth/drive.file']
SERVICE_ACCOUNT_FILE = 'service-account.json'
LOCAL_FILE_PATH = "../../../WTF/Account/TZAA/SavedVariables/SaellskapsresanMod.lua"
FILE_NAME = "SaellskapsresanMod.lua"
TEMP_REMOTE_COPY = "temp_remote.lua"

# Parse command-line arguments
parser = argparse.ArgumentParser(description="Sync DeathLoggerDB with Google Drive.")
parser.add_argument('-reset', action='store_true', help="Clear the remote DeathLoggerDB file.")
parser.add_argument('-noupload', action='store_true', help="Dont upload, only download")
parser.add_argument('-character', type=str, help="Character name for LastLogonDB update")
args = parser.parse_args()
shouldReset = args.reset
shouldNotUpload = args.noupload
character_name_debug = args.character
shouldStartGame = True
shouldUpload_lastlogon = True
wow_process = None
isGameRunning = False

# Admin account
user_email = 'jimmysaarela@gmail.com'
permission = {
    'type': 'user',
    'role': 'writer',  # or 'writer', 'commenter'
    'emailAddress': user_email
}

#DEFINITIONS
def get_drive_service():
    credentials = service_account.Credentials.from_service_account_file(
        SERVICE_ACCOUNT_FILE,
        scopes=SCOPES)
    return build('drive', 'v3', credentials=credentials)

def find_or_create_file(service, name):
    results = service.files().list(q=f"name='{name}'", fields="files(id)").execute()
    files = results.get('files', [])
    if files:
        return files[0]['id']
    else:
        file_metadata = {'name': name}
        media = MediaFileUpload(name, resumable=True)
        file = service.files().create(body=file_metadata, media_body=media, fields='id').execute()
        return file.get('id')

def download_file(service, file_id, dest_path):
    request = service.files().get_media(fileId=file_id)
    fh = io.FileIO(dest_path, 'wb')
    downloader = MediaIoBaseDownload(fh, request)
    done = False
    while not done:
        _, done = downloader.next_chunk()

# Uploads a file to Google Drive by replacing the file with the given file_id.
# Logs whether the upload succeeded or failed.
def upload_file(service, file_id, local_path):
    try:
        media = MediaFileUpload(local_path, resumable=True)
        response = service.files().update(fileId=file_id, media_body=media).execute()
        if response and 'id' in response:
            print(f"[LOG] Upload successful! File ID: {response['id']}")
        else:
            print("[WARNING] Upload completed, but no file ID returned.")
    except HttpError as error:
        print(f"[ERROR] Upload failed: {error}")

def extract_lua_table(content, var_name):
    match = re.search(rf'{var_name}\s*=\s*({{.*?}})', content, re.DOTALL)
    if not match:
        return {}
    
    lua_table = match.group(1)
    
    if var_name == "DeathLoggerDB":
        # For DeathLoggerDB (numeric keys with string values)
        # Replace boolean and nil values to Python equivalents
        py_compatible = lua_table.replace('true', 'True').replace('false', 'False').replace('nil', 'None')
        # Convert Lua numeric keys [1] = ... into Python's 1: ... format.
        py_compatible = re.sub(r'\[(\d+)\]\s*=', r'\1:', py_compatible)
        # Remove any trailing comma before the closing brace which is invalid in Python dictionaries.
        py_compatible = re.sub(r',\s*}', '}', py_compatible)
        try:
            return ast.literal_eval(py_compatible)
        except Exception as e:
            print(f"[WARNING] Failed to parse {var_name} table:", e)
            return {}
    
    elif var_name == "LastLogonDB":
        # For LastLogonDB (string keys with date string values)
        result = {}
        # Find all entries like: ["CharacterName"] = "25-04-15 04:26:43",
        entries = re.findall(r'\["([^"]+)"\]\s*=\s*"([^"]+)"', lua_table)
        for char_name, timestamp_str in entries:
            result[char_name] = timestamp_str
        return result
    
    return {}



# Looks for a line in the Lua file like "ShouldRefresh = true" or "false"
# and returns the corresponding Python boolean.
def extract_bool_var(content, var_name):
    match = re.search(rf'{var_name}\s*=\s*(true|false)', content, re.IGNORECASE)
    return match.group(1).lower() == 'true' if match else False

# Replaces the Lua table assigned to `var_name` with new_table_str.
# Matches:
#   DeathLoggerDB = { ... }
# And replaces the contents with the new table string.
def replace_table_in_lua(content, var_name, new_table_str):
    pattern = rf'({var_name}\s*=\s*){{.*?}}'
    patternSub = re.sub(pattern, rf'\1{new_table_str}', content, flags=re.DOTALL) 
    return patternSub

# Formats a Python dictionary {index: string} into Lua-style table.
# Example output:
# {
#     [1] = "some log string",
#     [2] = "another entry"
# }
def format_python_table_as_lua(py_table):
    lines = []
    for index, value in py_table.items():
        if isinstance(index, int):
            # For numeric indices (DeathLoggerDB)
            escaped = value.replace('"', '\\"')  # Escape quotes
            lines.append(f'\t[{index}] = "{escaped}"')
        else:
            # For string indices (LastLogonDB)
            lines.append(f'\t["{index}"] = {value}')
    return "{\n" + ",\n".join(lines) + "\n}"

# Formats a Python dictionary for LastLogonDB into Lua-style table
def format_lastlogon_table_as_lua(py_table):
    lines = []
    for char_name, timestamp in py_table.items():
        # Format the timestamp without quotes (as it appears in the file)
        lines.append(f'\t["{char_name}"] = {timestamp}')
    return "{\n" + ",\n".join(lines) + "\n}"

# Extracts the timestamp (as float) from a log entry.
# Format: "[25-04-08 21:31:26]..."
def extract_timestamp(log_str):
    match = re.match(r'\[(\d{2}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\]', log_str)
    if not match:
        return None
    try:
        return time.mktime(time.strptime(match.group(1), "%y-%m-%d %H:%M:%S"))
    except:
        return None

# Checks if a new log string is a duplicate of any in the existing dict (based on timestamp within 30s)
def is_duplicate(new_log_str, existing_log_strs):
    new_ts = extract_timestamp(new_log_str)
    if new_ts is None:
        return False

    for log in existing_log_strs.values():
        existing_ts = extract_timestamp(log)
        if existing_ts is None:
            continue
        if abs(existing_ts - new_ts) <= 30:
            return True
    return False

# Merges both local and remote entries into a unified table.
# Detects if any entries need to be uploaded
def merge_entries(local_entries, remote_entries):
    print("[LOG] Merging entries.")

    merged = dict(remote_entries)
    needsUpload = False
    needsUpdate = False
    next_index = max(merged.keys(), default=0) + 1

    # Merge local [LOG] remote
    for log in local_entries.values():
        if not is_duplicate(log, remote_entries):
            merged[next_index] = log
            next_index += 1
            needsUpdate = True
            needsUpload = True
        # else:
        #     print("[LOG] local found duplicate in remote, not addint it!")
            
    # Merge remote [LOG] local
    next_index = len(local_entries) + 1
    for log in remote_entries.values():
        if not is_duplicate(log, local_entries):
            merged[next_index] = log
            next_index += 1
            needsUpdate = True
        # else:
        #     print("[LOG] remote found duplicate in local, not adding it!")

    # Sort merged entries by timestamp
    sorted_items = sorted(
        merged.items(),
        key=lambda item: extract_timestamp(item[1]) or 0
    )
    merged_sorted = {i + 1: log for i, (_, log) in enumerate(sorted_items)}

    return merged_sorted, needsUpload, needsUpdate



# Clears the remote Lua file, resetting the DeathLoggerDB to an empty table.
def clear_remote_data(service, file_id):
    
    print("[LOG] Clearing Remote Data")
    global shouldReset
    shouldReset = False

    empty_content = "DeathLoggerDB = { }"

    try:
        from googleapiclient.http import MediaInMemoryUpload
        media = MediaInMemoryUpload(empty_content.encode('utf-8'), mimetype='text/plain')
        response = service.files().update(fileId=file_id, media_body=media).execute()
        if response and 'id' in response:
            print("[LOG] Remote database has been cleared successfully.")
        else:
            print("[WARNING] Clearing remote file completed, but no confirmation ID returned.")
    except Exception as e:
        print(f"[ERROR] Failed to clear remote data: {e}")

def sync_ready_start_wow():

    # Creating a sync_ready flag for the .bat file to know it´s ready to close.
    with open("sync_ready.flag", "w") as f:
        f.write("ready")

    global shouldStartGame
    shouldStartGame = False
    print("[LOG] Sync done.")
    
    # Get the full path to wow.exe/vanilla.exe
    exe_path = "../../../VanillaFixes.exe"
    print("[DEBUG] Attempting to launch WoW from:", exe_path)

    # Then launch it
    try:
        global wow_process
        wow_process = subprocess.Popen([exe_path])
        global isGameRunning
        isGameRunning = True
        
    except FileNotFoundError:
        print("[ERROR] WoW executable not found at:", exe_path)
        exit(1)

    print("[LOG] Launching Turtle WoW... Please dont close this window while playing!")

# Call this method to create permissions (not called anywhere at the moment)
def create_permissions(service, file_id):
    service.permissions().create(
        fileId=file_id,
        body=permission,
        fields='id').execute()
    

# A check to see if wow process is running
def is_wow_running():
    for proc in psutil.process_iter(['name']):
        if proc.info['name'] and "wow" in proc.info['name'].lower():
            return True
    return False


# SYNC LOOP UPDATE
# SYNC LOOP UPDATE
def sync_loop():
    service = get_drive_service()
    file_id = find_or_create_file(service, FILE_NAME)
    last_modified = None

    # Check if SavedVariables file exists or we create one
    if not os.path.exists(LOCAL_FILE_PATH):
        print(f"[LOG] File '{LOCAL_FILE_PATH}' does not exist. Creating it...")
        with open(LOCAL_FILE_PATH, 'w', encoding='cp1252') as f:
            f.write("DeathLoggerDB = { }\nLastLogonDB = { }\n")

    print(f"[LOG] Syncing with online database...")

    while True:
        try:
            # Check if WoW is still running or we exit
            if isGameRunning and not is_wow_running():
                print("[LOG] WoW has exited. Shutting down sync.")
                break
                # Exit the sync loop

            #Get stats and see if local file has been modified
            stat = os.stat(LOCAL_FILE_PATH)
            mod_time = stat.st_mtime

            if shouldReset:
                clear_remote_data(service, file_id)

            elif last_modified is None or mod_time != last_modified:
                last_modified = mod_time
                print("[LOG] Local file change detected.")

                with open(LOCAL_FILE_PATH, 'r') as f:
                    local_content = f.read()

                should_refresh = extract_bool_var(local_content, "ShouldRefresh")
                if should_refresh:
                    print("[LOG] Refreshing local file from database (ShouldRefresh = true)")
                    download_file(service, file_id, FILE_NAME)
                    continue

                if 'DeathLoggerDB' in local_content:
                    print("[LOG] Syncing changes...")

                    # Step 1: Download remote copy
                    download_file(service, file_id, TEMP_REMOTE_COPY)
                    with open(TEMP_REMOTE_COPY, 'r') as f:
                        remote_content = f.read()

                    # Step 2: Extract and merge DeathLoggerDB
                    local_deathlog = extract_lua_table(local_content, "DeathLoggerDB")
                    remote_deathlog = extract_lua_table(remote_content, "DeathLoggerDB")

                    merged_deathlog, needsUpload_deathlog, needsUpdate_deathlog = merge_entries(local_deathlog, remote_deathlog)
                    
                    # Step 3: Extract LastLogonDB from both local and remote
                    local_lastlogon = extract_lua_table(local_content, "LastLogonDB")
                    remote_lastlogon = extract_lua_table(remote_content, "LastLogonDB")
                    
                    # Merge LastLogonDB (one-way from client to server)
                    merged_lastlogon = dict(remote_lastlogon)
                    needsUpload_lastlogon = False
                    
                    # Update any character entries from local to remote
                    for char, timestamp in local_lastlogon.items():
                        if char not in merged_lastlogon or timestamp != merged_lastlogon.get(char, ""):
                            merged_lastlogon[char] = timestamp
                            needsUpload_lastlogon = True
                            print(f"[LOG] Updating timestamp for character: {char}")
                    
                                            # Step 4: Generate updated content
                    deathlog_table_str = format_python_table_as_lua(merged_deathlog)
                    lastlogon_table_str = format_lastlogon_table_as_lua(merged_lastlogon)
                    
                    # First update local file with only merged DeathLoggerDB (not LastLogonDB)
                    local_updated_content = replace_table_in_lua(local_content, "DeathLoggerDB", deathlog_table_str)
                    
                    # Update remote content with both tables for upload purposes
                    remote_updated_content = replace_table_in_lua(remote_content, "DeathLoggerDB", deathlog_table_str)
                    remote_updated_content = replace_table_in_lua(remote_updated_content, "LastLogonDB", lastlogon_table_str)
                    
                    needsUpload = needsUpload_deathlog or needsUpload_lastlogon
                    needsUpdate = needsUpdate_deathlog

                    if needsUpdate:
                        print("[LOG] New DeathLoggerDB entries detected - updating local file!")
                        # Only write DeathLoggerDB changes to local file
                        with open(LOCAL_FILE_PATH, 'w') as f:
                            f.write(local_updated_content)
                    
                    # Upload if either DeathLoggerDB or LastLogonDB needs updates
                    if needsUpload:
                        global shouldNotUpload
                        if shouldNotUpload:
                            print("[LOG] Skipped upload.")
                            if shouldStartGame:
                                sync_ready_start_wow()
                            continue

                        print("[LOG] Uploading to remote database...")
                        
                        # Write the full updated content to temp file for upload
                        with open(TEMP_REMOTE_COPY, 'w') as f:
                            f.write(remote_updated_content)
                            
                        upload_file(service, file_id, TEMP_REMOTE_COPY)
                        print("[LOG] Uploaded merged file to database.")
                    else:
                        print("[LOG] No new entries to merge.")

                    if shouldStartGame:
                        sync_ready_start_wow()
        except Exception as e:
            print(f"[WARNING] Error: {e}")

        time.sleep(2)
if __name__ == "__main__":
    sync_loop()