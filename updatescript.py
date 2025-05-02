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
with open(config_path, "a") as f:
    f.write(f"""
Host github.com-deploy
    HostName github.com
    User git
    IdentityFile {deploy_key_ssh_path}
    IdentitiesOnly yes
""")

# Clone using the SSH configuration
repo_url = "git@github.com-deploy:tzaarela/saellskapsresan.git"
clone_path = script_dir  # Clone into a subdirectory of the script

# Perform the clone using GitPython
try:
    git.Repo.clone_from(repo_url, str(clone_path))
    print(f"Repository successfully cloned to {clone_path}")
except git.GitCommandError as e:
    print(f"Error cloning repository: {e}")