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
echo "=== Smoke Test Setup v2 (pyenv) Started at `date` ===" |& tee -a "$LOG_FILE"
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

# Check if we can use the system Python
echo "=== Checking for System Python ===" |& tee -a "$LOG_FILE"
set PYTHON_INSTALLED=0
foreach py_cmd (python3 python)
    which $py_cmd >& /dev/null
    if ($status == 0) then
        set PY_VERSION=`$py_cmd --version | awk '{print $2}' | cut -d. -f1-2`
        echo "Found $py_cmd version $PY_VERSION" |& tee -a "$LOG_FILE"
        
        # Check if Python version is 3.6+
        set IS_PY3=`echo $PY_VERSION | grep "^3\." | wc -l`
        set MINOR_VER=`echo $PY_VERSION | cut -d. -f2`
        
        if ($IS_PY3 > 0 && $MINOR_VER >= 6) then
            echo "✅ Using system Python $py_cmd (version $PY_VERSION)" |& tee -a "$LOG_FILE"
            set PYTHON_CMD=$py_cmd
            set PYTHON_INSTALLED=1
            break
        else
            echo "⚠️ System Python version $PY_VERSION is too old (need 3.6+)" |& tee -a "$LOG_FILE"
        endif
    endif
end

# If we can't use system Python, try to install with pyenv
if ($PYTHON_INSTALLED == 0) then
    # Install pyenv using pyenv-installer
    echo "=== Installing pyenv ===" |& tee -a "$LOG_FILE"
    set PYENV_DIR="$HOME/.pyenv"
    set python_version="3.11.8"

    # Check if pyenv is already installed
    if (-d "$PYENV_DIR") then
        echo "✅ pyenv is already installed at $PYENV_DIR" |& tee -a "$LOG_FILE"
    else
        echo "Installing pyenv using pyenv-installer..." |& tee -a "$LOG_FILE"
        # Download the installer script
        curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer -o pyenv-installer.sh |& tee -a "$LOG_FILE"
        if ($status == 0) then
            # Make it executable and run it
            chmod +x pyenv-installer.sh
            # Run with bash to avoid tcsh issues
            bash ./pyenv-installer.sh |& tee -a "$LOG_FILE"
            rm -f pyenv-installer.sh
            
            if ($status == 0) then
                echo "✅ pyenv installed successfully" |& tee -a "$LOG_FILE"
            else
                echo "❌ Failed to install pyenv" |& tee -a "$LOG_FILE"
                exit 1
            endif
        else
            echo "❌ Failed to download pyenv installer" |& tee -a "$LOG_FILE"
            exit 1
        endif
    endif

    # Set up pyenv paths
    set PYENV_ROOT="$HOME/.pyenv"
    setenv PATH "$PYENV_ROOT/bin:$PATH"

    # Install Python using pre-built version if available
    echo "=== Installing Python ===" |& tee -a "$LOG_FILE"

    # Define platforms to try for prebuilt binaries
    set PLATFORMS=("3.11.8:fedora-42" "3.11.8:fedora-39" "3.11.8:fedora" "3.11.7:fedora-42" "3.11.7:fedora-39" "3.11.7:fedora" "3.11.6:fedora-42" "3.11.6:fedora-39" "3.11.6:fedora")

    set PYTHON_INSTALLED=0
    
    # Check if any of these versions are already installed
    foreach version ($PLATFORMS)
        set py_version=`echo $version | cut -d: -f1`
        echo "Checking if Python $py_version is already installed..." |& tee -a "$LOG_FILE"
        bash -c "$PYENV_ROOT/bin/pyenv versions | grep -w '$py_version'" >& /dev/null
        if ($status == 0) then
            echo "✅ Python $py_version already installed" |& tee -a "$LOG_FILE"
            set python_version=$py_version
            set PYTHON_INSTALLED=1
            break
        endif
    end

    # If not installed, try to install a prebuilt version
    if ($PYTHON_INSTALLED == 0) then
        echo "=== Trying to install prebuilt Python ===" |& tee -a "$LOG_FILE"
        
        # Try each platform
        foreach platform ($PLATFORMS)
            set py_version=`echo $platform | cut -d: -f1`
            set plat=`echo $platform | cut -d: -f2`
            
            echo "Trying Python $py_version for $plat..." |& tee -a "$LOG_FILE"
            
            # Try to download and install prebuilt Python
            PYTHON_BUILD_SKIP_MIRROR=1 bash -c "PATH=\"$PYENV_ROOT/bin:\$PATH\" PYENV_ROOT=\"$PYENV_ROOT\" $PYENV_ROOT/bin/pyenv install $py_version -v" |& tee -a "$LOG_FILE"
            
            if ($status == 0) then
                echo "✅ Python $py_version installed successfully" |& tee -a "$LOG_FILE"
                set python_version=$py_version
                set PYTHON_INSTALLED=1
                break
            else
                echo "⚠️ Failed to install Python $py_version for $plat" |& tee -a "$LOG_FILE"
            endif
        end
    endif

    # If no prebuilt version could be installed, fallback to system Python
    if ($PYTHON_INSTALLED == 0) then
        echo "⚠️ Could not install Python with pyenv, checking for system Python again..." |& tee -a "$LOG_FILE"
        foreach py_cmd (python3 python)
            which $py_cmd >& /dev/null
            if ($status == 0) then
                set PY_VERSION=`$py_cmd --version | awk '{print $2}' | cut -d. -f1-2`
                echo "Using system $py_cmd version $PY_VERSION as fallback" |& tee -a "$LOG_FILE"
                set PYTHON_CMD=$py_cmd
                set PYTHON_INSTALLED=1
                break
            endif
        end
    else
        # Set global Python version and path
        echo "Setting Python $python_version as global version..." |& tee -a "$LOG_FILE"
        bash -c "$PYENV_ROOT/bin/pyenv global $python_version"
        set PYTHON_CMD="$PYENV_ROOT/shims/python"
    endif
    
    # Final check
    if ($PYTHON_INSTALLED == 0) then
        echo "❌ No suitable Python installation found or could be installed" |& tee -a "$LOG_FILE"
        exit 1
    endif
else
    echo "Using system Python $PYTHON_CMD" |& tee -a "$LOG_FILE"
endif

# Clone the GitHub repository
echo "=== Cloning GitHub Repository ===" |& tee -a "$LOG_FILE"
# Use the parent directory of the script directory to handle in-place runs
set REPO_PARENT=`dirname "$SCRIPT_DIR"`
set REPO_DIR="$REPO_PARENT/smoke_test"
echo "Using repository directory: $REPO_DIR" |& tee -a "$LOG_FILE"

# Check if repository already exists
if (-d "$REPO_DIR") then
    echo "Repository already exists at $REPO_DIR" |& tee -a "$LOG_FILE"
    cd "$REPO_DIR"
    # Check if it's a git repository
    if (-d .git) then
        echo "Pulling latest changes..." |& tee -a "$LOG_FILE"
        git pull |& tee -a "$LOG_FILE"
        if ($status != 0) then
            echo "❌ Failed to pull latest changes" |& tee -a "$LOG_FILE"
            exit 1
        endif
    else
        echo "Directory exists but is not a git repository. Re-cloning..." |& tee -a "$LOG_FILE"
        cd ..
        rm -rf "$REPO_DIR"
        git clone "$REPO_URL" "$REPO_DIR" |& tee -a "$LOG_FILE"
        if ($status != 0) then
            echo "❌ Failed to clone repository" |& tee -a "$LOG_FILE"
            exit 1
        endif
        cd "$REPO_DIR"
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

# Create and set up virtual environment
echo "=== Creating Virtual Environment ===" |& tee -a "$LOG_FILE"
set VENV_DIR="$REPO_DIR/.venv"

# Check if virtual environment already exists
if (-d "$VENV_DIR") then
    echo "Virtual environment already exists at $VENV_DIR" |& tee -a "$LOG_FILE"
else
    echo "Creating new virtual environment..." |& tee -a "$LOG_FILE"
    # Install virtualenv if it doesn't exist
    $PYTHON_CMD -m pip install virtualenv >& /dev/null
    if ($status != 0) then
        echo "Installing virtualenv..." |& tee -a "$LOG_FILE"
        $PYTHON_CMD -m pip install virtualenv |& tee -a "$LOG_FILE"
        if ($status != 0) then
            echo "❌ Failed to install virtualenv" |& tee -a "$LOG_FILE"
            exit 1
        endif
    endif
    
    # Create the virtual environment
    $PYTHON_CMD -m virtualenv "$VENV_DIR" |& tee -a "$LOG_FILE"
    if ($status != 0) then
        echo "❌ Failed to create virtual environment" |& tee -a "$LOG_FILE"
        exit 1
    endif
endif

# Activate the virtual environment (for tcsh)
echo "Activating virtual environment..." |& tee -a "$LOG_FILE"
if (-f "$VENV_DIR/bin/activate.csh") then
    source "$VENV_DIR/bin/activate.csh" |& tee -a "$LOG_FILE"
    # Update PYTHON_CMD to use the Python from the virtual environment
    set PYTHON_CMD="$VENV_DIR/bin/python"
    echo "✅ Virtual environment activated" |& tee -a "$LOG_FILE"
else
    echo "❌ Failed to find virtual environment activation script" |& tee -a "$LOG_FILE"
    exit 1
endif

# Set up Python environment
echo "=== Setting up Python Environment ===" |& tee -a "$LOG_FILE"

# Check pip version and upgrade if needed
echo "Checking pip version..." |& tee -a "$LOG_FILE"
$PYTHON_CMD -m pip --version >& /dev/null
if ($status != 0) then
    echo "Installing pip..." |& tee -a "$LOG_FILE"
    curl -L https://bootstrap.pypa.io/get-pip.py -o get-pip.py |& tee -a "$LOG_FILE"
    if ($status == 0) then
        $PYTHON_CMD get-pip.py |& tee -a "$LOG_FILE"
        rm -f get-pip.py
    else
        echo "⚠️ Failed to download pip installer, continuing anyway" |& tee -a "$LOG_FILE"
    endif
else
    # Upgrade pip
    echo "Upgrading pip..." |& tee -a "$LOG_FILE"
    $PYTHON_CMD -m pip install --upgrade pip |& tee -a "$LOG_FILE"
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

# Verify installed versions
echo "=== Verifying Installed Versions ===" |& tee -a "$LOG_FILE"

# Check Python version
echo -n "Checking Python version... " |& tee -a "$LOG_FILE"
$PYTHON_CMD --version |& tee -a "$LOG_FILE"
if ($status != 0) then
    echo "❌ Failed to get Python version" |& tee -a "$LOG_FILE"
    exit 1
endif

# Check pip version
echo -n "Checking pip version... " |& tee -a "$LOG_FILE"
$PYTHON_CMD -m pip --version |& tee -a "$LOG_FILE"
if ($status != 0) then
    echo "❌ Failed to get pip version" |& tee -a "$LOG_FILE"
    exit 1
endif

# Check git version
echo -n "Checking git version... " |& tee -a "$LOG_FILE"
git --version |& tee -a "$LOG_FILE"
if ($status != 0) then
    echo "❌ Failed to get git version" |& tee -a "$LOG_FILE"
    exit 1
endif

# Check curl version
echo -n "Checking curl version... " |& tee -a "$LOG_FILE"
curl --version |& tee -a "$LOG_FILE"
if ($status != 0) then
    echo "❌ Failed to get curl version" |& tee -a "$LOG_FILE"
    exit 1
endif

echo "✅ All version checks completed successfully" |& tee -a "$LOG_FILE"

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
echo "=== Virtual Environment ===" |& tee -a "$LOG_FILE"
echo "A virtual environment has been created at: $VENV_DIR" |& tee -a "$LOG_FILE"
echo "To activate the virtual environment in the future:" |& tee -a "$LOG_FILE"
echo "cd $REPO_DIR" |& tee -a "$LOG_FILE"
echo "source $VENV_DIR/bin/activate.csh  # For tcsh shell" |& tee -a "$LOG_FILE"
echo "# OR" |& tee -a "$LOG_FILE"
echo "source $VENV_DIR/bin/activate      # For bash shell" |& tee -a "$LOG_FILE"
echo "" |& tee -a "$LOG_FILE"
echo "=== Usage Instructions ===" |& tee -a "$LOG_FILE"
echo "The setup script can be run with a custom repository URL:" |& tee -a "$LOG_FILE"
echo "./compute_server_setup_v2.sh https://github.com/username/repo.git" |& tee -a "$LOG_FILE"
echo "" |& tee -a "$LOG_FILE"
echo "=== Smoke Test Setup Completed at `date` ===" |& tee -a "$LOG_FILE" 