#!/bin/bash

# Function to check build dependencies
check_build_dependencies() {
    echo "=== Checking Build Dependencies ==="
    local required_packages=(
        "gcc"
        "make"
        "build-essential"
        "libssl-dev"
        "zlib1g-dev"
        "libbz2-dev"
        "libreadline-dev"
        "libsqlite3-dev"
        "wget"
        "curl"
        "llvm"
        "libncurses5-dev"
        "libncursesw5-dev"
        "xz-utils"
        "tk-dev"
        "libffi-dev"
        "liblzma-dev"
        "python3-openssl"
    )
    
    local missing_packages=()
    
    for package in "${required_packages[@]}"; do
        echo -n "Checking $package... "
        if ! dpkg -l | grep -q "^ii  $package "; then
            echo "❌ Not found"
            missing_packages+=("$package")
        else
            echo "✅ Found"
        fi
    done
    
    if [ ${#missing_packages[@]} -ne 0 ]; then
        echo "❌ Missing build dependencies: ${missing_packages[*]}"
        echo "⚠️  Note: Some dependencies might be available under different names on RHEL7"
        echo "⚠️  You may need to install these dependencies using yum"
        return 1
    fi
    
    echo "✅ All build dependencies are installed"
    return 0
}

# Function to install pyenv
install_pyenv() {
    echo "=== Installing pyenv ==="
    local pyenv_dir="$HOME/.pyenv"
    local pyenv_install_log="$TEST_DIR/pyenv_install.log"
    
    # Check if pyenv is already installed
    if [ -d "$pyenv_dir" ]; then
        echo "✅ pyenv is already installed at $pyenv_dir"
        return 0
    fi
    
    echo "Installing pyenv..."
    echo "Logging installation to $pyenv_install_log"
    
    # Install pyenv with detailed logging
    if ! curl -fsSL https://pyenv.run | bash > "$pyenv_install_log" 2>&1; then
        echo "❌ Failed to install pyenv"
        echo "Installation log:"
        cat "$pyenv_install_log"
        return 1
    fi
    
    # Add pyenv to PATH
    echo "Configuring pyenv in .bashrc..."
    {
        echo 'export PYENV_ROOT="$HOME/.pyenv"'
        echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"'
        echo 'eval "$(pyenv init -)"'
    } >> ~/.bashrc
    
    # Source the updated .bashrc
    echo "Sourcing updated .bashrc..."
    if ! source ~/.bashrc; then
        echo "❌ Failed to source .bashrc"
        return 1
    fi
    
    echo "✅ pyenv installed successfully"
    return 0
}

# Function to install Python 3.11 using pyenv
install_python_311() {
    echo "=== Installing Python 3.11 ==="
    local python_install_log="$TEST_DIR/python_install.log"
    
    # Check if Python 3.11 is already installed
    if pyenv versions | grep -q "3.11"; then
        echo "✅ Python 3.11 is already installed"
    else
        echo "Installing Python 3.11..."
        echo "Logging installation to $python_install_log"
        
        # Install Python 3.11 with detailed logging
        if ! pyenv install 3.11.0 > "$python_install_log" 2>&1; then
            echo "❌ Failed to install Python 3.11"
            echo "Installation log:"
            cat "$python_install_log"
            return 1
        fi
        
        echo "✅ Python 3.11 installed successfully"
    fi
    
    # Set Python 3.11 as the local version
    echo "Setting Python 3.11 as the local version..."
    if ! pyenv local 3.11.0; then
        echo "❌ Failed to set Python 3.11 as local version"
        return 1
    fi
    
    echo "✅ Set Python 3.11 as the local version"
    return 0
}

# Function to clean up failed installations
cleanup_failed_install() {
    echo "=== Cleaning up failed installation ==="
    local pyenv_dir="$HOME/.pyenv"
    
    if [ -d "$pyenv_dir" ]; then
        echo "Removing pyenv installation..."
        rm -rf "$pyenv_dir"
    fi
    
    # Remove Python version if installation failed
    if pyenv versions | grep -q "3.11"; then
        echo "Removing Python 3.11 installation..."
        pyenv uninstall -f 3.11.0
    fi
    
    # Remove .bashrc modifications
    echo "Cleaning up .bashrc..."
    sed -i '/export PYENV_ROOT=/d' ~/.bashrc
    sed -i '/command -v pyenv >\/dev\/null || export PATH=/d' ~/.bashrc
    sed -i '/eval "$(pyenv init -)"/d' ~/.bashrc
    
    echo "✅ Cleanup complete"
}

# Main setup function
setup_python_environment() {
    echo "=== Starting Python Environment Setup ==="
    
    # Check build dependencies
    if ! check_build_dependencies; then
        echo "❌ Missing build dependencies. Setup cannot continue."
        return 1
    fi
    
    # Install pyenv
    if ! install_pyenv; then
        echo "❌ pyenv installation failed"
        cleanup_failed_install
        return 1
    fi
    
    # Install Python 3.11
    if ! install_python_311; then
        echo "❌ Python 3.11 installation failed"
        cleanup_failed_install
        return 1
    fi
    
    echo "✅ Python environment setup completed successfully"
    return 0
}

# Function to check Python versions
check_python_versions() {
    echo "=== Available Python Versions ==="
    # Check for python3.x versions
    for version in {3,4,5,6,7,8,9,10,11,12}; do
        if command -v "python3.${version}" >/dev/null 2>&1; then
            echo "✅ Found Python 3.${version}: $(python3.${version} --version 2>&1)"
        fi
    done
    
    # Check for python2.x versions
    for version in {6,7}; do
        if command -v "python2.${version}" >/dev/null 2>&1; then
            echo "✅ Found Python 2.${version}: $(python2.${version} --version 2>&1)"
        fi
    done
}

# Function to check if a command exists and get its version
check_tool() {
    local tool=$1
    local version_flag=$2
    echo -n "Checking $tool... "
    if command -v $tool >/dev/null 2>&1; then
        version=$($tool $version_flag 2>&1 | head -n 1)
        echo "✅ Found: $version"
        return 0
    else
        echo "❌ Not found"
        return 1
    fi
}

# Function to check Python version and virtualenv
check_python() {
    echo -n "Checking default Python... "
    if command -v python3 >/dev/null 2>&1; then
        version=$(python3 --version 2>&1)
        echo "✅ Found: $version"
        
        # Check if venv module is available
        if python3 -c "import venv" 2>/dev/null; then
            echo "✅ Python venv module is available"
        else
            echo "❌ Python venv module is not available"
            return 1
        fi
        return 0
    else
        echo "❌ Python3 not found"
        return 1
    fi
}

# Function to check pip and its version
check_pip() {
    echo -n "Checking pip... "
    if command -v pip3 >/dev/null 2>&1; then
        version=$(pip3 --version 2>&1)
        echo "✅ Found: $version"
        return 0
    else
        echo "❌ pip3 not found"
        return 1
    fi
}

echo "=== Setting up Python Environment ==="
if ! setup_python_environment; then
    echo "❌ Python environment setup failed"
    exit 1
fi

echo "=== Checking Required Tools ==="
check_python_versions
check_tool "git" "--version"
check_python
check_pip

echo ""
echo "=== System Information ==="
echo "Operating System: $(uname -a)"
echo "Available Memory: $(free -h | awk '/^Mem:/ {print $2}')"
echo "Disk Space: $(df -h . | awk 'NR==2 {print $4}') available"

# Create a temporary directory for the test in user's home directory
TEST_DIR="$HOME/smoke_test_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo ""
echo "=== Setting up smoke test environment ==="
echo "Test directory: $TEST_DIR"

# Clone the repository from GitHub
echo "Cloning repository from GitHub..."
GITHUB_REPO="https://github.com/joescape/smoke_test.git"
if ! git clone "$GITHUB_REPO" .; then
    echo "❌ Failed to clone repository from GitHub"
    exit 1
fi
echo "✅ Repository cloned successfully"

# Verify the repository
echo "Verifying repository..."
if [ ! -f "smoke_test.py" ] || [ ! -f "logging_config.py" ]; then
    echo "❌ Required files not found in repository"
    exit 1
fi
echo "✅ Repository verification successful"

# Make scripts executable
echo "Setting up scripts..."
chmod +x setup_git.sh test_github_integration.sh
echo "✅ Scripts made executable"

# Set up Python environment in user space
echo "Setting up Python environment..."
# Try to use the highest available Python 3 version
PYTHON_CMD="python3"
for version in {12,11,10,9,8,7,6,5,4,3}; do
    if command -v "python3.${version}" >/dev/null 2>&1; then
        PYTHON_CMD="python3.${version}"
        echo "Using $PYTHON_CMD for virtual environment"
        break
    fi
done

$PYTHON_CMD -m venv venv --without-pip
source venv/bin/activate

# Install pip in user space
echo "Installing pip in user space..."
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python get-pip.py --user
export PATH=$HOME/.local/bin:$PATH

# Upgrade pip and install dependencies in user space
echo "Upgrading pip and installing dependencies..."
pip install --user --upgrade pip
pip install --user "python-dotenv>=0.19.0,<1.0.0" "structlog>=20.1.0,<21.0.0"

# Create logs directory with user permissions
echo "Creating logs directory..."
mkdir -p logs
chmod 700 logs  # User-only permissions

# Test logging functionality
echo "Testing logging functionality..."
cat > test_logging.py << EOL
import logging
import os
import sys
from datetime import datetime

# Create logs directory if it doesn't exist
os.makedirs('logs', exist_ok=True)

# Configure logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('logs/test_log.log'),
        logging.StreamHandler()
    ]
)

# Test logging
logging.info("This is a test log message")
logging.info(f"Python version: {sys.version}")
logging.info(f"Python executable: {sys.executable}")
print("Test log message written. Check logs/test_log.log")
EOL

# Run the test logging script
echo "Running logging test..."
python test_logging.py

# Verify log file was created
if [ -f "logs/test_log.log" ]; then
    echo "✅ Log file created successfully"
    echo "Log file contents:"
    cat logs/test_log.log
else
    echo "❌ Log file was not created"
    echo "Current directory contents:"
    ls -la
    echo "Logs directory contents:"
    ls -la logs/
fi

# Run the smoke test
echo "Running smoke test..."
python smoke_test.py

# Verify smoke test log was created
echo "Checking for smoke test logs..."
if [ -d "logs" ]; then
    echo "Logs directory exists. Contents:"
    ls -la logs/
    if [ -n "$(ls -A logs/)" ]; then
        echo "Log files found:"
        ls -ltr logs/
        echo "Latest log file contents:"
        cat "$(ls -tr logs/ | tail -n 1)"
    else
        echo "No log files found in logs directory"
    fi
else
    echo "Logs directory does not exist"
fi

# The script will stay in the test directory
# You can examine the logs in the logs/ directory
echo ""
echo "=== Setup Complete ==="
echo "Logs directory: $TEST_DIR/logs/"
echo ""
echo "To view the latest log file:"
echo "ls -ltr $TEST_DIR/logs/"
echo ""
echo "To clean up when done, run:"
echo "rm -rf $TEST_DIR" 