import os
from pathlib import Path
import git  # GitPython library

# Get the directory containing the script
script_dir = Path(__file__).parent.absolute()

# Path to the private key (in the same directory as the script)
private_key_path = script_dir / "saellskapsresan-read-only"

# Ensure the SSH directory exists
ssh_dir = Path.home() / ".ssh"
ssh_dir.mkdir(mode=0o700, exist_ok=True)

# Create a copy of the key in the SSH directory with proper permissions
deploy_key_ssh_path = ssh_dir / "saellskapsresan-read-only"
with open(private_key_path, "r") as src_file:
    with open(deploy_key_ssh_path, "w") as dest_file:
        dest_file.write(src_file.read())
os.chmod(deploy_key_ssh_path, 0o600)  # Set proper permissions

# Configure SSH to use this key for the specific repository
config_path = ssh_dir / "config"
config_entry = f"""
Host github.com-deploy
    HostName github.com
    User git
    IdentityFile {deploy_key_ssh_path}
    IdentitiesOnly yes
"""

# Only append the config if it doesn't already exist
with open(config_path, "r+") as f:
    content = f.read()
    if config_entry.strip() not in content:
        f.seek(0, 2)  # Move to the end of the file
        f.write(config_entry)

# Path to the existing repository
repo_path = script_dir

try:
    # Open the existing repository
    repo = git.Repo(repo_path)
    
    # Fetch changes from the remote
    print(f"Fetching changes from remote...")
    repo.git.fetch('origin')
    
    # Reset to match the remote branch (but keep untracked files)
    print(f"Updating local files to match remote...")
    repo.git.reset('--hard', 'origin/master')
    
    # Clean up by removing untracked directories (adjust as needed)
    # repo.git.clean('-fd')  # Uncomment if you want to remove untracked directories and files
    
    # Read version number from version.txt
    version_path = script_dir / "version.txt"
    if version_path.exists():
        with open(version_path, "r") as version_file:
            version = version_file.read().strip()
        print(f"Repository successfully updated to version {version} at {repo_path}")
    else:
        print(f"Repository successfully updated at {repo_path} (version.txt not found)")
except git.GitCommandError as e:
    print(f"Error updating repository: {e}")