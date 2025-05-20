import os
from config import REQUIRED_SAVEDVARS, DEFAULT_SAVEDVARS_CONTENT, GLOBAL_ACCOUNT_PATH

def read_lua_file(file_path):
    """Read a Lua file and return its content."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return f.read()
    except UnicodeDecodeError:
        # Try with different encoding if UTF-8 fails
        with open(file_path, 'r', encoding='cp1252') as f:
            return f.read()

def write_lua_file(file_path, content):
    """Write content to a Lua file."""
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

def clear_lua_table_in_file(file_path, table_name):
    """
    Clears a Lua table in a file by replacing its contents with an empty table
    while preserving all other content in the file.
    
    Args:
        file_path (str): Path to the Lua file
        table_name (str): Name of the Lua table to clear
    
    Returns:
        bool: True if successful, False otherwise
    """
    try:
        # Read the file content
        with open(file_path, 'r', encoding='utf-8') as file:
            lines = file.readlines()
        
        # Find the table in the file
        table_start_line = -1
        table_end_line = -1
        inside_table = False
        brace_count = 0
        
        for i, line in enumerate(lines):
            # Look for the table declaration
            if table_start_line == -1 and f"{table_name} = " in line and "{" in line:
                table_start_line = i
                inside_table = True
                brace_count = line.count("{") - line.count("}")
                
                # If the table opens and closes on the same line
                if brace_count == 0:
                    table_end_line = i
                    break
            
            # If we're inside the table, track braces to find the end
            elif inside_table:
                brace_count += line.count("{") - line.count("}")
                
                if brace_count == 0:
                    table_end_line = i
                    break
        
        # If we found the table
        if table_start_line != -1 and table_end_line != -1:
            # Create a new list of lines with the table cleared
            new_lines = lines[:table_start_line]  # Lines before table
            new_lines.append(f"{table_name} = {{}}\n")  # Empty table
            new_lines.extend(lines[table_end_line + 1:])  # Lines after table
            
            # Write the modified content back to the file
            with open(file_path, 'w', encoding='utf-8') as file:
                file.writelines(new_lines)
            
            return True
        else:
            print(f"Table '{table_name}' not found in the file.")
            return False
            
    except Exception as e:
        print(f"Error clearing Lua table: {e}")
        return False

def file_exists(file_path):
    """
    Safely check if a file exists at the specified location.
    
    Args:
        file_path (str): Path to the file to check
        
    Returns:
        bool: True if the file exists, False otherwise
    """
    return os.path.isfile(file_path) and os.access(file_path, os.R_OK)

def validate_saved_variables():
    """
    Validate and ensure the SavedVariables file exists with required variables.
    
    Returns:
        bool: True if validation is successful, False otherwise
    """
    if "REPLACEWITHACCOUNTNAME" in GLOBAL_ACCOUNT_PATH:
        print("[ERROR] You have not changed to your accountname in the accountName.txt file in the Saellskapsresan addon folder. Please do this and run again!")
        return False

    # Check if SavedVariables file exists
    if os.path.exists(GLOBAL_ACCOUNT_PATH):
        print(f"[LOG] File '{GLOBAL_ACCOUNT_PATH}' exists. Validating content...")
        
        # Read file content
        with open(GLOBAL_ACCOUNT_PATH, 'r', encoding='cp1252') as f:
            content = f.read()
        
        # Check if all required variables are present
        all_vars_present = all(var in content for var in REQUIRED_SAVEDVARS)
        
        if not all_vars_present:
            print(f"[LOG] File '{GLOBAL_ACCOUNT_PATH}' is missing required variables. Recreating it...")
            with open(GLOBAL_ACCOUNT_PATH, 'w', encoding='cp1252') as f:
                f.write(DEFAULT_SAVEDVARS_CONTENT)
        else:
            print(f"[LOG] File '{GLOBAL_ACCOUNT_PATH}' is valid.")
    else:
        # File doesn't exist, create it
        print(f"[LOG] File '{GLOBAL_ACCOUNT_PATH}' does not exist. Creating it...")
        os.makedirs(os.path.dirname(GLOBAL_ACCOUNT_PATH), exist_ok=True)
        with open(GLOBAL_ACCOUNT_PATH, 'w', encoding='cp1252') as f:
            f.write(DEFAULT_SAVEDVARS_CONTENT)

    return True