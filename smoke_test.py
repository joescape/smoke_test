import os
import platform
import sys
import subprocess
import git
from logging_config import logger

def check_system_info():
    """Check and log system information"""
    logger.info("Checking system information", 
                system=platform.system(),
                release=platform.release(),
                version=platform.version(),
                machine=platform.machine(),
                processor=platform.processor(),
                python_version=sys.version)

def check_wsl_specific():
    """Check WSL-specific information"""
    try:
        wsl_version = subprocess.check_output(['wsl', '--version'], text=True)
        logger.info("WSL version information", wsl_version=wsl_version)
    except Exception as e:
        logger.error("Failed to get WSL version", error=str(e))

def check_environment():
    """Check environment variables and paths"""
    logger.info("Environment check",
                current_directory=os.getcwd(),
                path=os.environ.get('PATH', ''),
                home=os.environ.get('HOME', ''),
                user=os.environ.get('USER', ''))

def check_file_system():
    """Check file system operations"""
    test_file = "test_write.txt"
    try:
        with open(test_file, 'w') as f:
            f.write("Test write operation")
        os.remove(test_file)
        logger.info("File system check successful")
    except Exception as e:
        logger.error("File system check failed", error=str(e))

def check_git_config():
    """Check Git configuration"""
    try:
        # Check Git version
        git_version = subprocess.check_output(['git', '--version'], text=True).strip()
        logger.info("Git version check", version=git_version)
        
        # Check Git configuration
        git_config = {}
        try:
            git_config['user.name'] = subprocess.check_output(['git', 'config', '--get', 'user.name'], text=True).strip()
        except subprocess.CalledProcessError:
            git_config['user.name'] = 'Not configured'
            
        try:
            git_config['user.email'] = subprocess.check_output(['git', 'config', '--get', 'user.email'], text=True).strip()
        except subprocess.CalledProcessError:
            git_config['user.email'] = 'Not configured'
            
        logger.info("Git configuration check", config=git_config)
        
    except Exception as e:
        logger.error("Git configuration check failed", error=str(e))

def test_github_clone():
    """Test cloning a repository from GitHub"""
    test_repo = "https://github.com/github/gitignore.git"  # Using a small, public repo for testing
    clone_dir = "test_clone"
    
    try:
        # Remove test directory if it exists
        if os.path.exists(clone_dir):
            subprocess.run(['rm', '-rf', clone_dir], check=True)
            
        # Clone the repository
        logger.info("Attempting to clone test repository", repo=test_repo)
        git.Repo.clone_from(test_repo, clone_dir)
        
        # Verify the clone
        repo = git.Repo(clone_dir)
        logger.info("Repository clone successful",
                   branch=repo.active_branch.name,
                   commit_count=len(list(repo.iter_commits())))
        
        # Clean up
        subprocess.run(['rm', '-rf', clone_dir], check=True)
        logger.info("Test repository cleanup successful")
        
    except Exception as e:
        logger.error("GitHub clone test failed", error=str(e))
        # Clean up in case of partial clone
        if os.path.exists(clone_dir):
            subprocess.run(['rm', '-rf', clone_dir], check=True)

def main():
    logger.info("Starting smoke test")
    
    try:
        check_system_info()
        check_wsl_specific()
        check_environment()
        check_file_system()
        check_git_config()
        test_github_clone()
        
        logger.info("Smoke test completed successfully")
    except Exception as e:
        logger.error("Smoke test failed", error=str(e))
        sys.exit(1)

if __name__ == "__main__":
    main() 