#!/usr/bin/env python3
import os
import sys
import platform
import subprocess
import tempfile
from pathlib import Path
from logging_config import logger

def check_python_environment():
    """Check and log Python environment information"""
    logger.info("Python environment",
                python_version=platform.python_version(),
                python_path=sys.path,
                virtual_env=os.environ.get('VIRTUAL_ENV', 'Not in virtual environment'),
                pyenv_version=os.environ.get('PYENV_VERSION', 'Not using pyenv'),
                pip_version=subprocess.check_output([sys.executable, '-m', 'pip', '--version']).decode().strip())

def check_system_info():
    """Check and log system information"""
    logger.info("System information",
                platform=platform.platform(),
                system=platform.system(),
                release=platform.release(),
                version=platform.version(),
                machine=platform.machine(),
                processor=platform.processor())

def check_wsl_specific():
    """Check WSL-specific information"""
    try:
        wsl_version = subprocess.check_output(['wsl', '--version']).decode()
        logger.info("WSL version information", wsl_version=wsl_version)
    except Exception as e:
        logger.error("Failed to get WSL version", error=str(e))

def check_environment_variables():
    """Check and log important environment variables"""
    logger.info("Environment variables",
                path=os.environ.get('PATH', 'Not set'),
                home=os.environ.get('HOME', 'Not set'),
                user=os.environ.get('USER', 'Not set'),
                shell=os.environ.get('SHELL', 'Not set'),
                term=os.environ.get('TERM', 'Not set'))

def check_file_system():
    """Test file system operations"""
    try:
        # Create temp directory
        with tempfile.TemporaryDirectory() as temp_dir:
            logger.info("Created temporary directory", dir=temp_dir)
            
            # Test file creation
            test_file = Path(temp_dir) / "test_file.txt"
            test_file.write_text("Test file content")
            logger.info("Created test file", file=str(test_file))
            
            # Test file reading
            content = test_file.read_text()
            logger.info("Read test file", content=content)
            
            # Test file deletion
            test_file.unlink()
            logger.info("Deleted test file")
            
        logger.info("File system tests passed")
    except Exception as e:
        logger.error("File system test failed", error=str(e))

def check_git_config():
    """Check Git configuration"""
    try:
        # Check Git version
        git_version = subprocess.check_output(['git', '--version']).decode().strip()
        logger.info("Git version check", version=git_version)
        
        # Check Git configuration
        git_config = {}
        try:
            git_config['user.name'] = subprocess.check_output(['git', 'config', '--get', 'user.name']).decode().strip()
        except subprocess.CalledProcessError:
            git_config['user.name'] = 'Not configured'
            
        try:
            git_config['user.email'] = subprocess.check_output(['git', 'config', '--get', 'user.email']).decode().strip()
        except subprocess.CalledProcessError:
            git_config['user.email'] = 'Not configured'
            
        logger.info("Git configuration", config=git_config)
    except Exception as e:
        logger.error("Git check failed", error=str(e))

def run_smoke_test():
    """Run all smoke tests"""
    logger.info("Starting smoke test")
    
    check_system_info()
    check_python_environment()
    check_environment_variables()
    check_file_system()
    check_git_config()
    
    # Only run WSL checks if we're on Windows
    if platform.system() == "Windows" or os.path.exists('/proc/sys/fs/binfmt_misc/WSLInterop'):
        check_wsl_specific()
    
    logger.info("Smoke test completed successfully")

if __name__ == "__main__":
    run_smoke_test()
