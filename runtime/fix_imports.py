import os
import sys

def ensure_directory_exists(dir_path):
    """Create directory if it doesn't exist."""
    if not os.path.exists(dir_path):
        os.makedirs(dir_path)
        print(f"Created directory: {dir_path}")

def create_init_file(dir_path):
    """Create __init__.py file in the directory if it doesn't exist."""
    init_file = os.path.join(dir_path, "__init__.py")
    if not os.path.exists(init_file):
        with open(init_file, 'w') as f:
            f.write("# Package initialization\n")
        print(f"Created file: {init_file}")

def main():
    """Ensure all required directories and __init__.py files exist."""
    current_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Ensure required directories exist
    dirs = [
        "utils",
        "google_sheets",
        "sync"
    ]
    
    for dir_name in dirs:
        dir_path = os.path.join(current_dir, dir_name)
        ensure_directory_exists(dir_path)
        create_init_file(dir_path)
    
    # Create root __init__.py
    create_init_file(current_dir)
    
    print("Fix complete. All directories and __init__.py files have been created.")

if __name__ == "__main__":
    main()