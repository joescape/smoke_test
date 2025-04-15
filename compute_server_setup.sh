#!/bin/tcsh

# Set up logging for all terminal output
set TIMESTAMP=`date +%Y%m%d_%H%M%S`
set SCRIPT_DIR=`dirname "$0"`
set SCRIPT_DIR=`cd "$SCRIPT_DIR" && pwd`
set LOG_DIR="${SCRIPT_DIR}/logs"
mkdir -p "$LOG_DIR"
set LOG_FILE="$LOG_DIR/setup_${TIMESTAMP}.log"

# Redirect all output to both terminal and log file
# Note: tcsh doesn't support bash-style redirections, so we'll use tee differently
(echo "=== Smoke Test Setup Started at `date` ===" \
&& echo "Current directory: $SCRIPT_DIR" \
&& echo "Logging all output to: $LOG_FILE" \
&& echo "============================================") |& tee -a "$LOG_FILE"

# Function to check build dependencies
check_build_dependencies:
    echo "=== Checking Build Dependencies ===" |& tee -a "$LOG_FILE"
    
    # Check for basic tools in PATH
    foreach tool (git curl gcc make)
        echo -n "Checking $tool... " |& tee -a "$LOG_FILE"
        which $tool >& /dev/null
        if ($status == 0) then
            echo "✅ Found" |& tee -a "$LOG_FILE"
        else
            echo "❌ Not found" |& tee -a "$LOG_FILE"
            echo "❌ Missing required tool: $tool" |& tee -a "$LOG_FILE"
            exit 1
        endif
    end
    
    # Check for write permissions in home directory
    echo -n "Checking home directory permissions... " |& tee -a "$LOG_FILE"
    if (-w "$HOME") then
        echo "✅ Write permission available" |& tee -a "$LOG_FILE"
    else
        echo "❌ No write permission in home directory" |& tee -a "$LOG_FILE"
        exit 1
    endif
    
    echo "✅ All build requirements met" |& tee -a "$LOG_FILE"

# Install pyenv
install_pyenv:
    echo "=== Installing pyenv ===" |& tee -a "$LOG_FILE"
    set pyenv_dir="$HOME/.pyenv"
    
    # Check if pyenv is already installed
    if (-d "$pyenv_dir") then
        echo "✅ pyenv is already installed at $pyenv_dir" |& tee -a "$LOG_FILE"
    else
        echo "Installing pyenv..." |& tee -a "$LOG_FILE"
        curl -fsSL https://pyenv.run | bash >& "$LOG_FILE"
        
        # Configure pyenv for tcsh
        echo 'setenv PYENV_ROOT "$HOME/.pyenv"' >> ~/.tcshrc
        echo 'set path = ($PYENV_ROOT/bin $path)' >> ~/.tcshrc
        echo 'eval `pyenv init -`' >> ~/.tcshrc
        
        # Source the updated configuration
        source ~/.tcshrc
        
        if ($status == 0) then
            echo "✅ pyenv installed and configured successfully" |& tee -a "$LOG_FILE"
        else
            echo "❌ Failed to install pyenv" |& tee -a "$LOG_FILE"
            exit 1
        endif
    endif

# Install Python 3.11
install_python_311:
    echo "=== Installing Python 3.11 ===" |& tee -a "$LOG_FILE"
    set python_version="3.11.8"
    
    # Check if Python 3.11 is already installed
    pyenv versions | grep "3.11" >& /dev/null
    if ($status == 0) then
        echo "✅ Python 3.11 is already installed" |& tee -a "$LOG_FILE"
    else
        echo "Installing Python $python_version..." |& tee -a "$LOG_FILE"
        pyenv install "$python_version" |& tee -a "$LOG_FILE"
        
        if ($status == 0) then
            echo "✅ Python $python_version installed successfully" |& tee -a "$LOG_FILE"
        else
            echo "❌ Failed to install Python $python_version" |& tee -a "$LOG_FILE"
            exit 1
        endif
    endif
    
    # Set Python as the local version
    echo "Setting Python $python_version as the local version..." |& tee -a "$LOG_FILE"
    pyenv local "$python_version"
    
    if ($status == 0) then
        echo "✅ Set Python $python_version as the local version" |& tee -a "$LOG_FILE"
    else
        echo "❌ Failed to set Python $python_version as local version" |& tee -a "$LOG_FILE"
        exit 1
    endif

# Set up Python environment
setup_python_environment:
    echo "=== Setting up Python Environment ===" |& tee -a "$LOG_FILE"
    
    # Create and activate virtual environment
    echo "Creating virtual environment..." |& tee -a "$LOG_FILE"
    python -m venv venv
    source venv/bin/activate.csh
    
    # Upgrade pip
    echo "Upgrading pip..." |& tee -a "$LOG_FILE"
    python -m pip install --upgrade pip |& tee -a "$LOG_FILE"
    
    # Install build dependencies
    echo "Installing build dependencies..." |& tee -a "$LOG_FILE"
    pip install wheel setuptools |& tee -a "$LOG_FILE"
    
    # Install project dependencies
    echo "Installing project dependencies..." |& tee -a "$LOG_FILE"
    pip install -r requirements.txt -v |& tee -a "$LOG_FILE"
    
    if ($status == 0) then
        echo "✅ Python environment setup complete" |& tee -a "$LOG_FILE"
    else
        echo "❌ Failed to set up Python environment" |& tee -a "$LOG_FILE"
        exit 1
    endif

# Main script execution
echo "=== Setting up smoke test environment ===" |& tee -a "$LOG_FILE"

# Create a temporary directory for the test
set TEST_DIR="$HOME/smoke_test_`date +%Y%m%d_%H%M%S`"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "Test directory: $TEST_DIR" |& tee -a "$LOG_FILE"

# Run the setup steps
check_build_dependencies
install_pyenv
install_python_311
setup_python_environment

# Display final status
echo "" |& tee -a "$LOG_FILE"
echo "=== Setup Complete ===" |& tee -a "$LOG_FILE"
echo "All logs are in: $LOG_DIR/" |& tee -a "$LOG_FILE"
echo "Setup log: $LOG_FILE" |& tee -a "$LOG_FILE"
echo "" |& tee -a "$LOG_FILE"
echo "To view the logs:" |& tee -a "$LOG_FILE"
echo "ls -ltr $LOG_DIR/" |& tee -a "$LOG_FILE"
echo "" |& tee -a "$LOG_FILE"
echo "To view the setup log:" |& tee -a "$LOG_FILE"
echo "cat $LOG_FILE" |& tee -a "$LOG_FILE"
echo "" |& tee -a "$LOG_FILE"
echo "To clean up logs:" |& tee -a "$LOG_FILE"
echo "rm -rf $LOG_DIR  # This will remove all logs" |& tee -a "$LOG_FILE"
echo "" |& tee -a "$LOG_FILE"
echo "=== Smoke Test Setup Completed at `date` ===" |& tee -a "$LOG_FILE" 