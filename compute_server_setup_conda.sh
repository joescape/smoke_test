#!/bin/tcsh

# Check if repository URL is provided as an argument
if ($#argv >= 1) then
    set REPO_URL="$argv[1]"
else
    # Default repository URL if not provided
    set REPO_URL="https://github.com/joescape/smoke_test.git"
endif

# Set up logging for all terminal output
set TIMESTAMP=`date +%Y%m%d_%H%M%S`
set SCRIPT_DIR=`dirname "$0"`
set SCRIPT_DIR=`cd "$SCRIPT_DIR" && pwd`
set LOG_DIR="${SCRIPT_DIR}/logs"
mkdir -p "$LOG_DIR"
set LOG_FILE="$LOG_DIR/setup_${TIMESTAMP}.log"

# Redirect all output to both terminal and log file
echo "=== Smoke Test Setup Started at `date` ===" |& tee -a "$LOG_FILE"
echo "Current directory: $SCRIPT_DIR" |& tee -a "$LOG_FILE"
echo "Using repository URL: $REPO_URL" |& tee -a "$LOG_FILE"
echo "Logging all output to: $LOG_FILE" |& tee -a "$LOG_FILE"
echo "============================================" |& tee -a "$LOG_FILE"

# Check build dependencies
echo "=== Checking Build Dependencies ===" |& tee -a "$LOG_FILE"

# Check for basic tools in PATH
foreach tool (git curl)
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

# Install Miniconda
echo "=== Installing Miniconda ===" |& tee -a "$LOG_FILE"
set MINICONDA_DIR="$HOME/miniconda3"
set python_version="3.11"

# Check if Miniconda is already installed
if (-d "$MINICONDA_DIR") then
    echo "✅ Miniconda is already installed at $MINICONDA_DIR" |& tee -a "$LOG_FILE"
else
    echo "Installing Miniconda..." |& tee -a "$LOG_FILE"
    set miniconda_url="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
    curl -o miniconda.sh "$miniconda_url" |& tee -a "$LOG_FILE"
    
    if ($status == 0) then
        echo "Installing Miniconda..." |& tee -a "$LOG_FILE"
        bash miniconda.sh -b -p "$MINICONDA_DIR" |& tee -a "$LOG_FILE"
        
        if ($status == 0) then
            echo "✅ Miniconda installed successfully" |& tee -a "$LOG_FILE"
            # Add Miniconda to PATH
            setenv PATH "$MINICONDA_DIR/bin:$PATH"
            # Add to .tcshrc for future sessions
            echo 'setenv PATH "'$MINICONDA_DIR'/bin:$PATH"' >> ~/.tcshrc
        else
            echo "❌ Failed to install Miniconda" |& tee -a "$LOG_FILE"
            exit 1
        endif
    else
        echo "❌ Failed to download Miniconda" |& tee -a "$LOG_FILE"
        exit 1
    endif
endif

# Create Python environment
echo "=== Creating Python Environment ===" |& tee -a "$LOG_FILE"
echo "Creating Python $python_version environment..." |& tee -a "$LOG_FILE"
$MINICONDA_DIR/bin/conda create -y -n smoke_test python=$python_version |& tee -a "$LOG_FILE"

if ($status == 0) then
    echo "✅ Python environment created successfully" |& tee -a "$LOG_FILE"
    # Activate the environment
    source $MINICONDA_DIR/bin/activate smoke_test
    setenv PYTHON_CMD "$MINICONDA_DIR/envs/smoke_test/bin/python"
    
    # Check versions of installed tools
    echo "=== Checking Tool Versions ===" |& tee -a "$LOG_FILE"
    echo "Python version:" |& tee -a "$LOG_FILE"
    $PYTHON_CMD --version |& tee -a "$LOG_FILE"
    
    echo "pip version:" |& tee -a "$LOG_FILE"
    $PYTHON_CMD -m pip --version |& tee -a "$LOG_FILE"
    
    echo "conda version:" |& tee -a "$LOG_FILE"
    $MINICONDA_DIR/bin/conda --version |& tee -a "$LOG_FILE"
    
    echo "git version:" |& tee -a "$LOG_FILE"
    git --version |& tee -a "$LOG_FILE"
    
    echo "curl version:" |& tee -a "$LOG_FILE"
    curl --version | head -n 1 |& tee -a "$LOG_FILE"
    
    echo "✅ Version checks complete" |& tee -a "$LOG_FILE"
else
    echo "❌ Failed to create Python environment" |& tee -a "$LOG_FILE"
    exit 1
endif

# Clone the GitHub repository
echo "=== Cloning GitHub Repository ===" |& tee -a "$LOG_FILE"
set REPO_DIR="$HOME/smoke_test"

# Check if repository already exists
if (-d "$REPO_DIR") then
    echo "Repository already exists at $REPO_DIR" |& tee -a "$LOG_FILE"
    echo "Pulling latest changes..." |& tee -a "$LOG_FILE"
    cd "$REPO_DIR"
    git pull |& tee -a "$LOG_FILE"
    if ($status != 0) then
        echo "❌ Failed to pull latest changes" |& tee -a "$LOG_FILE"
        exit 1
    endif
else
    echo "Cloning repository from $REPO_URL..." |& tee -a "$LOG_FILE"
    git clone "$REPO_URL" "$REPO_DIR" |& tee -a "$LOG_FILE"
    if ($status != 0) then
        echo "❌ Failed to clone repository" |& tee -a "$LOG_FILE"
        exit 1
    endif
    cd "$REPO_DIR"
endif

echo "✅ Repository setup complete" |& tee -a "$LOG_FILE"

# Set up Python environment
echo "=== Setting up Python Environment ===" |& tee -a "$LOG_FILE"

# Check pip version and upgrade if needed
echo "Checking pip version..." |& tee -a "$LOG_FILE"
set PIP_VERSION=`$PYTHON_CMD -m pip --version | awk '{print $2}' | cut -d. -f1-2`
set MIN_PIP_VERSION="23.0"  # Minimum acceptable pip version

if (`echo "$PIP_VERSION < $MIN_PIP_VERSION" | bc -l`) then
    echo "Upgrading pip (current version: $PIP_VERSION)..." |& tee -a "$LOG_FILE"
    $PYTHON_CMD -m pip install --upgrade pip |& tee -a "$LOG_FILE"
else
    echo "✅ pip version $PIP_VERSION is recent enough, skipping upgrade" |& tee -a "$LOG_FILE"
endif

# Install build dependencies
echo "Installing build dependencies..." |& tee -a "$LOG_FILE"
$PYTHON_CMD -m pip install wheel setuptools |& tee -a "$LOG_FILE"

# Install project dependencies
echo "Installing project dependencies..." |& tee -a "$LOG_FILE"
if (-f requirements.txt) then
    $PYTHON_CMD -m pip install -r requirements.txt -v |& tee -a "$LOG_FILE"
    if ($status != 0) then
        echo "❌ Failed to install requirements" |& tee -a "$LOG_FILE"
        exit 1
    endif
else
    echo "⚠️ No requirements.txt file found, skipping dependencies installation" |& tee -a "$LOG_FILE"
    echo "Creating an empty requirements.txt file for future use" |& tee -a "$LOG_FILE"
    touch requirements.txt
endif

if ($status == 0) then
    echo "✅ Python environment setup complete" |& tee -a "$LOG_FILE"
else
    echo "❌ Failed to set up Python environment" |& tee -a "$LOG_FILE"
    exit 1
endif

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
echo "=== Usage Instructions ===" |& tee -a "$LOG_FILE"
echo "The setup script can be run with a custom repository URL:" |& tee -a "$LOG_FILE"
echo "./compute_server_setup.sh https://github.com/username/repo.git" |& tee -a "$LOG_FILE"
echo "" |& tee -a "$LOG_FILE"
echo "=== Smoke Test Setup Completed at `date` ===" |& tee -a "$LOG_FILE" 