import os
import platform
import sys
import subprocess
import shutil
from logging_config import logger

def check_python_environment():
    """Check Python environment details"""
    logger.info("Checking Python environment",
                python_executable=sys.executable,
                python_path=sys.path,
                virtual_env=os.environ.get('VIRTUAL_ENV', 'Not in virtual environment'),
                pyenv_version=os.environ.get('PYENV_VERSION', 'Not using pyenv'),
                pip_version=subprocess.check_output([sys.executable, '-m', 'pip', '--version'], text=True).strip())

def check_system_info():
    """Check and log system information"""
    logger.info("Checking system information", 
                system=platform.system(),
                release=platform.release(),
                version=platform.version(),
                machine=platform.machine(),
                processor=platform.processor(),
                python_version=sys.version,
                python_implementation=platform.python_implementation(),
                python_compiler=platform.python_compiler())

def check_wsl_specific():
    """Check WSL-specific information"""
    try:
        wsl_version = subprocess.check_output(['wsl', '--version'], text=True)
        logger.info("WSL version information", wsl_version=wsl_version)
    except Exception as e:
        logger.error("Failed to get WSL version", error=str(e))

def check_environment():
    """Check environment variables and paths"""
    # Get pyenv root if it exists
    pyenv_root = os.environ.get('PYENV_ROOT', 'Not set')
    if pyenv_root != 'Not set':
        pyenv_versions = os.listdir(os.path.join(pyenv_root, 'versions')) if os.path.exists(os.path.join(pyenv_root, 'versions')) else []
    
    logger.info("Environment check",
                current_directory=os.getcwd(),
                path=os.environ.get('PATH', ''),
                home=os.environ.get('HOME', ''),
                user=os.environ.get('USER', ''),
                pyenv_root=pyenv_root,
                pyenv_versions=pyenv_versions if 'pyenv_versions' in locals() else 'Not available',
                shell=os.environ.get('SHELL', ''))

def check_file_system():
    """Check file system operations"""
    test_file = "test_write.txt"
    test_dir = "test_dir"
    
    try:
        # Test file write
        with open(test_file, 'w') as f:
            f.write("Test write operation")
        logger.info("File write test successful")
        
        # Test directory operations
        os.makedirs(test_dir, exist_ok=True)
        logger.info("Directory creation test successful")
        
        # Test file permissions
        file_stat = os.stat(test_file)
        logger.info("File permissions check",
                   mode=file_stat.st_mode,
                   uid=file_stat.st_uid,
                   gid=file_stat.st_gid)
        
        # Clean up
        os.remove(test_file)
        shutil.rmtree(test_dir)
        logger.info("File system cleanup successful")
        
    except Exception as e:
        logger.error("File system check failed", error=str(e))
        # Clean up if possible
        if os.path.exists(test_file):
            os.remove(test_file)
        if os.path.exists(test_dir):
            shutil.rmtree(test_dir)

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
    try:
        import git
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
    except ImportError:
        logger.warning("GitPython not available, skipping GitHub clone test")

def main():
    logger.info("Starting smoke test")
    
    try:
        check_python_environment()
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