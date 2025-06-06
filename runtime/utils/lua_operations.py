import re
from lupa import LuaRuntime
from utils.file_operations import read_lua_file, write_lua_file

def initialize_lua():
    """Initialize and return a Lua runtime."""
    lua = LuaRuntime(unpack_returned_tuples=True)

    # Add utility functions to Lua for table serialization
    lua.execute('''
    function table_to_string(tbl, indent)
        if not indent then indent = 0 end
        local result = "{"
        local indentStr = string.rep("  ", indent)
        local first = true
        
        for k, v in pairs(tbl) do
            if not first then result = result .. "," end
            first = false
            
            result = result .. "\\n" .. indentStr .. "  "
            
            -- Format the key
            if type(k) == "string" and k:match("^[_%a][_%w]*$") then
                result = result .. k
            else
                result = result .. "[" .. format_value(k, indent + 1) .. "]"
            end
            
            result = result .. " = " .. format_value(v, indent + 1)
        end
        
        if not first then result = result .. "\\n" .. indentStr end
        return result .. "}"
    end
    
    function format_value(val, indent)
        local val_type = type(val)
        
        if val_type == "table" then
            return table_to_string(val, indent)
        elseif val_type == "string" then
            return string.format("%q", val)
        elseif val_type == "nil" then
            return "nil"
        else
            return tostring(val)
        end
    end
    ''')
    
    return lua

def initialize_lua():
    """Initialize and return a Lua runtime."""
    lua = LuaRuntime(unpack_returned_tuples=True)

    # Add utility functions to Lua for table serialization
    lua.execute('''
    function table_to_string(tbl, indent)
        if not indent then indent = 0 end
        local result = "{"
        local indentStr = string.rep("  ", indent)
        local first = true
        
        for k, v in pairs(tbl) do
            if not first then result = result .. "," end
            first = false
            
            result = result .. "\\n" .. indentStr .. "  "
            
            -- Format the key
            if type(k) == "string" and k:match("^[_%a][_%w]*$") then
                result = result .. k
            else
                result = result .. "[" .. format_value(k, indent + 1) .. "]"
            end
            
            result = result .. " = " .. format_value(v, indent + 1)
        end
        
        if not first then result = result .. "\\n" .. indentStr end
        return result .. "}"
    end
    
    function format_value(val, indent)
        local val_type = type(val)
        
        if val_type == "table" then
            return table_to_string(val, indent)
        elseif val_type == "string" then
            return string.format("%q", val)
        elseif val_type == "nil" then
            return "nil"
        else
            return tostring(val)
        end
    end
    ''')
    
    return lua

def extract_lua_table(lua, content, var_name):
    """Extract a Lua table from content string using the Lua interpreter."""
    try:
        lua.execute(content)
        lua_table = lua.globals()[var_name]
        return lua_table_to_python(lua_table)
    except Exception as e:
        print(f"[ERROR] Error extracting Lua table {var_name}: {e}")
        return {}

def extract_lua_var(lua, content, var_name, default=None):
    """Extract a Lua variable from content string."""
    try:
        lua.execute(content)
        
        if var_name not in lua.globals():
            print(f"[WARNING] Variable '{var_name}' not found in Lua content")
            return default
            
        value = lua.globals()[var_name]
        
        return lua_value_to_python(value)
    except Exception as e:
        print(f"[ERROR] Error extracting '{var_name}': {e}")
        return default

def lua_table_to_python(lua_table):
    """Convert a Lua table to a Python dictionary or list."""
    if lua_table is None:
        return {}
    
    # Check if it's a sequence or a dictionary-like table
    is_sequence = True
    max_index = 0
    
    # First pass to determine if it's a sequence
    for k, v in lua_table.items():
        if isinstance(k, int) and k > 0:
            max_index = max(max_index, k)
        else:
            is_sequence = False
            break
    
    if is_sequence and max_index > 0:
        # Convert to a Python list
        result = [None] * max_index
        for i in range(1, max_index + 1):  # Lua tables are 1-indexed
            if i in lua_table:
                value = lua_table[i]
                result[i-1] = lua_value_to_python(value)
        return result
    else:
        # Convert to a Python dictionary
        result = {}
        for k, v in lua_table.items():
            python_key = lua_value_to_python(k)
            python_value = lua_value_to_python(v)
            result[python_key] = python_value
        return result

def lua_value_to_python(value):
    """Convert a Lua value to its Python equivalent."""
    if value is None:
        return None
    
    value_type = type(value)
    
    # Handle bytes conversion to string
    if isinstance(value, bytes):
        return value.decode('utf-8')
    
    # If it's a basic type, return as is
    if value_type in (int, float, bool, str):
        return value
    
    # If it's a Lua table, convert recursively
    if hasattr(value, 'items'):
        return lua_table_to_python(value)
    
    # Default case
    return str(value)

def python_to_lua_table(lua, data, var_name=None):
    """Convert a Python dictionary or list to a Lua table string."""
    if isinstance(data, dict):
        lua_table = lua.table()
        for k, v in data.items():
            lua_table[k] = python_to_lua_value(lua, v)
    elif isinstance(data, list):
        lua_table = lua.table()
        for i, v in enumerate(data, 1):  # Lua tables are 1-indexed
            lua_table[i] = python_to_lua_value(lua, v)
    else:
        return str(data)
    
    # Get the table as a string
    table_to_string = lua.globals().table_to_string
    lua_str = table_to_string(lua_table)
    
    # Convert from bytes to string if needed
    if isinstance(lua_str, bytes):
        table_str = lua_str.decode('utf-8')
    else:
        table_str = str(lua_str)
    
    # Return as an assignment if var_name is provided
    if var_name:
        return f"{var_name} = {table_str}"
    else:
        return table_str

def python_to_lua_value(lua, value):
    """Convert a Python value to its Lua equivalent."""
    if value is None:
        return None
    elif isinstance(value, (int, float, bool, str)):
        return value
    elif isinstance(value, dict):
        lua_table = lua.table()
        for k, v in value.items():
            lua_table[k] = python_to_lua_value(lua, v)
        return lua_table
    elif isinstance(value, list):
        lua_table = lua.table()
        for i, v in enumerate(value, 1):  # Lua tables are 1-indexed
            lua_table[i] = python_to_lua_value(lua, v)
        return lua_table
    else:
        return str(value)

def update_lua_table_in_file(lua, file_path, var_name, new_data):
    """Update a specific Lua table in a file without affecting other content."""
    try:
        # Read the current file content
        content = read_lua_file(file_path)
        
        # Load all existing variables from the file
        lua.execute(content)
        
        # Update the specified table with new data
        if var_name in lua.globals():
            # Convert new_data to Lua
            lua_table = lua.table()
            if isinstance(new_data, dict):
                for k, v in new_data.items():
                    lua_table[k] = python_to_lua_value(lua, v)
            elif isinstance(new_data, list):
                for i, v in enumerate(new_data, 1):
                    lua_table[i] = python_to_lua_value(lua, v)
            
            # Assign to the global variable
            lua.globals()[var_name] = lua_table
        else:
            # If variable doesn't exist, create it
            lua.execute(f"{var_name} = {{}}")
            # Then update it
            lua_table = lua.table()
            if isinstance(new_data, dict):
                for k, v in new_data.items():
                    lua_table[k] = python_to_lua_value(lua, v)
            elif isinstance(new_data, list):
                for i, v in enumerate(new_data, 1):
                    lua_table[i] = python_to_lua_value(lua, v)
            
            # Assign to the global variable
            lua.globals()[var_name] = lua_table
        
        # Now generate the updated file content
        variables = []
        
        # Get all known table variables
        table_names = ["DeathLoggerDB", "LastLogonDB", "CharacterProfessionsDB", "CharacterStatsDB", "LeaderboardsDB"]
        # print("Get all previous tables")
        for name in table_names:
            if name in lua.globals():
                table_data = lua_table_to_python(lua.globals()[name])
                table_str = python_to_lua_table(lua, table_data, name)
                variables.append(table_str)
        
        # Get boolean variables
        bool_names = ["SyncLoaded"]
        for name in bool_names:
            if name in lua.globals():
                value = bool(lua.globals()[name])
                variables.append(f"{name} = {str(value).lower()}")
        
        # Get string variables
        string_names = ["CurrentCharacter"]
        for name in string_names:
            if name in lua.globals():
                value = lua.globals()[name]
                if isinstance(value, str):
                    # Properly escape the string and wrap in quotes
                    escaped_value = value.replace("\\", "\\\\").replace('"', '\\"')
                    variables.append(f'{name} = "{escaped_value}"')
        
        # Check for any other variables that might be in the globals but not in our predefined lists
        all_globals = [name for name in lua.globals() 
                      if not name.startswith('_') and name not in table_names 
                      and name not in bool_names and name not in string_names
                      and not callable(lua.globals()[name])]  # Filter out functions
        
        for name in all_globals:
            value = lua.globals()[name]
            if isinstance(value, str):
                # Handle strings
                escaped_value = value.replace("\\", "\\\\").replace('"', '\\"')
                variables.append(f'{name} = "{escaped_value}"')
            elif isinstance(value, (int, float)):
                # Handle numbers
                variables.append(f"{name} = {value}")
            elif isinstance(value, bool):
                # Handle booleans
                variables.append(f"{name} = {str(value).lower()}")
        
        # Combine everything into a new file
        new_content = "\n\n".join(variables)
        
        # Write back to the file
        write_lua_file(file_path, new_content)
        print(f"[LOG] Updated {var_name} in {file_path}")
        return True
    except Exception as e:
        print(f"[ERROR] Error updating Lua table: {e}")
        return False

def set_lua_var_in_file(lua, file_path, var_name, value):
    """
    Set a variable in a Lua file.
    Works with various data types (boolean, string, number, table).
    Preserves ALL existing content in the file and only updates the specific variable.
    
    Args:
        lua: The LuaRuntime instance
        file_path: Path to the Lua file
        var_name: Name of the variable to set
        value: Value to assign (can be bool, str, int, float, dict, list)
    
    Returns:
        bool: True if successful, False otherwise
    """
    try:
        # Read the current file content
        content = read_lua_file(file_path)
        
        # Prepare the new value as a string
        if isinstance(value, bool):
            value_str = str(value).lower()
        elif isinstance(value, (int, float)):
            value_str = str(value)
        elif isinstance(value, str):
            value_str = f'"{value}"'
        elif isinstance(value, (dict, list)):
            # For complex types, use the table conversion
            value_str = python_to_lua_table(lua, value).replace(f"{var_name} = ", "")
        else:
            value_str = f'"{str(value)}"'
            
        # Check if variable already exists in the file
        pattern = re.compile(rf'{var_name}\s*=\s*[^,\r\n]*')
        match = pattern.search(content)
        
        if match:
            # Variable exists, update it in place
            old_assignment = match.group(0)
            new_assignment = f"{var_name} = {value_str}"
            modified_content = content.replace(old_assignment, new_assignment)
            
            print(f"[LOG] Updated existing variable {var_name} in {file_path}")
        else:
            # Variable doesn't exist, append it to the end of the file
            if content and not content.endswith('\n'):
                modified_content = content + f"\n\n{var_name} = {value_str}"
            else:
                modified_content = content + f"{var_name} = {value_str}"
                
            print(f"[LOG] Added new variable {var_name} to {file_path}")
        
        # Write back to file
        write_lua_file(file_path, modified_content)
        return True
        
    except Exception as e:
        print(f"[ERROR] Error setting variable in Lua file: {e}")
        return False