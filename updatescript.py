import os
import shutil
from pathlib import Path
import git  # GitPython library
import subprocess
import sys
import time

# Get the directory containing the script
script_dir = Path(__file__).parent.absolute()

# Path to the repository
repo_path = script_dir

# Define repository URL - let's use HTTPS since it's more reliable for this case
repo_url = "https://github.com/tzaarela/saellskapsresan.git"
print(f"Repository URL: {repo_url}")

# Improved directory removal function with retries
def safe_remove_dir(path, max_retries=3, retry_delay=1):
    """Safely remove a directory with retries for Windows permission issues"""
    path = Path(path)
    if not path.exists():
        return True
    
    for attempt in range(max_retries):
        try:
            if attempt > 0:
                print(f"Retry {attempt} removing directory: {path}")
            
            # On Windows, sometimes we need to force close open handles
            if os.name == 'nt' and attempt > 0:
                # Try running Windows specific command to close open handles
                try:
                    subprocess.run(["taskkill", "/F", "/IM", "git.exe"], 
                                  stdout=subprocess.DEVNULL, 
                                  stderr=subprocess.DEVNULL)
                    time.sleep(0.5)  # Give Windows time to release the handles
                except:
                    pass
            
            shutil.rmtree(path)
            return True
        except Exception as e:
            print(f"Failed to remove directory: {e}")
            if attempt < max_retries - 1:
                time.sleep(retry_delay)
            else:
                print(f"Warning: Could not fully remove {path}. Continuing anyway...")
                return False

try:
    # Check if it's a git repository, if not clone it
    if not os.path.exists(os.path.join(repo_path, ".git")):
        print(f"No git repository found in {repo_path}")
        print(f"Cloning from {repo_url}...")
        
        # Create a temporary directory for cloning
        temp_dir = Path(os.path.join(script_dir, "temp_clone"))
        safe_remove_dir(temp_dir)  # Clean up any existing temporary directory
        
        # Create the temp directory
        temp_dir.mkdir(exist_ok=True)
        
        # Clone the repository using subprocess for more control
        try:
            subprocess.run(
                ["git", "clone", repo_url, str(temp_dir)],
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
        except subprocess.CalledProcessError as e:
            print(f"Error cloning repository: {e}")
            print(f"Error output: {e.stderr}")
            sys.exit(1)
        
        # Move all files (except .git) from temp directory to current directory
        print("Copying files from temporary directory...")
        for item in temp_dir.iterdir():
            if item.name != ".git":
                if item.is_file():
                    shutil.copy2(item, repo_path)
                    print(f"Copied file: {item.name}")
                elif item.is_dir():
                    print(f"Copying directory: {item.name}")
                    shutil.copytree(item, repo_path / item.name, dirs_exist_ok=True)
        
        # Move .git directory
        git_dir = temp_dir / ".git"
        dest_git_dir = repo_path / ".git"
        print("Copying .git directory...")
        
        # If destination .git directory already exists, remove it first
        if dest_git_dir.exists():
            safe_remove_dir(dest_git_dir)
            
        shutil.copytree(git_dir, dest_git_dir)
        
        # Clean up temp directory - but don't fail if unsuccessful
        print("Cleaning up temporary directory...")
        safe_remove_dir(temp_dir)
        
        print("Repository has been cloned successfully.")
        
        # Even if there was an error, try to continue if .git directory exists
        if not os.path.exists(os.path.join(repo_path, ".git")):
            print("Fatal error: Repository was not properly cloned.")
            sys.exit(1)
    
    # Continue with repository operations
    print("Opening git repository...")
    repo = git.Repo(repo_path)
    
    # Ensure remote origin is set correctly
    try:
        origin = repo.remote('origin')
        current_url = origin.url
        # Update the URL to HTTPS if different
        if current_url != repo_url:
            print(f"Updating remote URL from {current_url} to {repo_url}")
            origin.set_url(repo_url)
    except ValueError:
        # Remote doesn't exist, create it
        print(f"Creating remote 'origin' with URL: {repo_url}")
        origin = repo.create_remote('origin', repo_url)
    
    # Fetch changes from the remote
    print(f"Fetching changes from remote...")
    repo.git.fetch('origin')
    
    # Reset to match the remote branch (but keep untracked files)
    print(f"Updating local files to match remote...")
    try:
        repo.git.reset('--hard', 'origin/master')
        print("Successfully reset to origin/master")
    except git.GitCommandError as e:
        # Try main branch if master doesn't exist
        try:
            print("Master branch not found, trying main branch...")
            repo.git.reset('--hard', 'origin/main')
            print("Successfully reset to origin/main")
        except git.GitCommandError as e2:
            print(f"Could not reset to origin/main either: {e2}")
            print("Trying to fetch and checkout the default branch...")
            
            # Get the default branch name
            branch_info = subprocess.run(
                ["git", "remote", "show", "origin"],
                cwd=repo_path,
                check=True,
                stdout=subprocess.PIPE,
                text=True
            ).stdout
            
            default_branch = None
            for line in branch_info.splitlines():
                if "HEAD branch:" in line:
                    default_branch = line.split(":")[-1].strip()
                    break
            
            if default_branch:
                print(f"Default branch is: {default_branch}")
                repo.git.fetch('origin', default_branch)
                
                # Check if branch exists locally
                if default_branch in repo.heads:
                    repo.git.checkout(default_branch)
                else:
                    repo.git.checkout('-b', default_branch, f'origin/{default_branch}')
                
                repo.git.reset('--hard', f'origin/{default_branch}')
                print(f"Successfully reset to origin/{default_branch}")
            else:
                print("Could not determine default branch")

    # Read version number from version.txt
    version_path = script_dir / "version.txt"
    if version_path.exists():
        with open(version_path, "r") as version_file:
            version = version_file.read().strip()
        print(f"Repository successfully updated to version {version} at {repo_path}")
    else:
        print(f"Repository successfully updated at {repo_path} (version.txt not found)")
        
except Exception as e:
    print(f"Error: {e}")
    import traceback
    traceback.print_exc()

print("\nScript completed. If you see any errors above, they may be ignorable")
print("if the repository files were successfully copied.")