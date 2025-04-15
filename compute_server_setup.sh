#!/bin/tcsh

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
echo "Logging all output to: $LOG_FILE" |& tee -a "$LOG_FILE"
echo "============================================" |& tee -a "$LOG_FILE"

# Initialize pyenv environment variables if pyenv exists
echo "Checking for existing pyenv installation..." |& tee -a "$LOG_FILE"
if (-d "$HOME/.pyenv") then
    echo "✅ pyenv directory found" |& tee -a "$LOG_FILE"
    setenv PYENV_ROOT "$HOME/.pyenv"
    set path = ($PYENV_ROOT/bin $path)
    
    # Initialize pyenv with a more explicit approach
    echo "Initializing pyenv..." |& tee -a "$LOG_FILE"
    
    # Manually add shims to path - this is what pyenv init --path does
    echo "Adding pyenv shims to path..." |& tee -a "$LOG_FILE"
    set path = ($PYENV_ROOT/shims $path)
    rehash
    
    # Manually set PYENV_VERSION if .python-version exists
    if (-f .python-version && -r .python-version) then
        setenv PYENV_VERSION `cat .python-version`
        echo "Set PYENV_VERSION=$PYENV_VERSION from .python-version file" |& tee -a "$LOG_FILE"
    endif
    
    echo "✅ pyenv initialized successfully" |& tee -a "$LOG_FILE"
else
    echo "❌ pyenv directory not found" |& tee -a "$LOG_FILE"
endif

# Verify pyenv initialization
echo "Verifying pyenv initialization..." |& tee -a "$LOG_FILE"
if ($?PYENV_ROOT) then
    echo "✅ PYENV_ROOT is set to $PYENV_ROOT" |& tee -a "$LOG_FILE"
else
    echo "❌ PYENV_ROOT is not set" |& tee -a "$LOG_FILE"
    exit 1
endif

# Check for pyenv in path directly rather than using which
echo -n "Checking if pyenv is in PATH... " |& tee -a "$LOG_FILE"
set is_pyenv_in_path = `echo $path | grep -c "$PYENV_ROOT/bin"`
if ($is_pyenv_in_path > 0) then
    echo "✅ pyenv is in PATH" |& tee -a "$LOG_FILE"
else
    echo "❌ pyenv is not in PATH" |& tee -a "$LOG_FILE"
    exit 1
endif

# Check for shims in path
echo -n "Checking if pyenv shims are in PATH... " |& tee -a "$LOG_FILE"
set is_shims_in_path = `echo $path | grep -c "$PYENV_ROOT/shims"`
if ($is_shims_in_path > 0) then
    echo "✅ pyenv shims are in PATH" |& tee -a "$LOG_FILE"
else
    echo "❌ pyenv shims are not in PATH" |& tee -a "$LOG_FILE"
    exit 1
endif

# Verify pyenv version command works directly
echo -n "Verifying pyenv command works... " |& tee -a "$LOG_FILE"
$PYENV_ROOT/bin/pyenv --version >& /dev/null
if ($status == 0) then
    echo "✅ pyenv command works" |& tee -a "$LOG_FILE"
else
    echo "❌ pyenv command failed" |& tee -a "$LOG_FILE"
    exit 1
endif

# Create a temporary directory for the test
echo "Creating temporary test directory..." |& tee -a "$LOG_FILE"
set TEST_DIR="$HOME/smoke_test_`date +%Y%m%d_%H%M%S`"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"
echo "Test directory: $TEST_DIR" |& tee -a "$LOG_FILE"

# Check build dependencies
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

# Check for Python build dependencies
echo "Checking Python build dependencies..." |& tee -a "$LOG_FILE"

# List of required packages for building Python
set required_libs = (bzip2-devel libffi-devel openssl-devel readline-devel sqlite-devel zlib-devel)

echo "Note: The following development libraries are required to build Python:" |& tee -a "$LOG_FILE"
foreach lib ($required_libs)
    echo "  - $lib" |& tee -a "$LOG_FILE"
end

echo "Warning: If you encounter Python build failures, you may need to ask your system administrator to install these packages." |& tee -a "$LOG_FILE"
echo "Alternatively, you can download a pre-compiled Python package instead of building from source." |& tee -a "$LOG_FILE"
echo "" |& tee -a "$LOG_FILE"

# Check for write permissions in home directory
echo -n "Checking home directory permissions... " |& tee -a "$LOG_FILE"
if (-w "$HOME") then
    echo "✅ Write permission available" |& tee -a "$LOG_FILE"
else
    echo "❌ No write permission in home directory" |& tee -a "$LOG_FILE"
    exit 1
endif

echo "✅ All build requirements met" |& tee -a "$LOG_FILE"

# Install pyenv if needed
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
    
    # Initialize pyenv in current shell
    setenv PYENV_ROOT "$HOME/.pyenv"
    set path = ($PYENV_ROOT/bin $path)
    eval `$PYENV_ROOT/bin/pyenv init -` >& /dev/null
    
    if ($status == 0) then
        echo "✅ pyenv installed and configured successfully" |& tee -a "$LOG_FILE"
    else
        echo "❌ Failed to install pyenv" |& tee -a "$LOG_FILE"
        exit 1
    endif
endif

# Install Python 3.11
echo "=== Installing Python 3.11 ===" |& tee -a "$LOG_FILE"
set python_version="3.11.8"

# Verify pyenv is in path
echo -n "Verifying pyenv installation... " |& tee -a "$LOG_FILE"
$PYENV_ROOT/bin/pyenv --version >& /dev/null
if ($status == 0) then
    echo "✅ pyenv is properly initialized" |& tee -a "$LOG_FILE"
else
    echo "❌ pyenv is not properly initialized" |& tee -a "$LOG_FILE"
    exit 1
endif

# Check if Python 3.11 is already installed
$PYENV_ROOT/bin/pyenv versions | grep "3.11" >& /dev/null
if ($status == 0) then
    echo "✅ Python 3.11 is already installed" |& tee -a "$LOG_FILE"
else
    echo "Installing Python $python_version..." |& tee -a "$LOG_FILE"
    
    # First try to build from source
    $PYENV_ROOT/bin/pyenv install "$python_version" |& tee -a "$LOG_FILE"
    
    # Check if installation succeeded
    if ($status != 0) then
        echo "⚠️ Failed to build Python from source, trying to find a precompiled version..." |& tee -a "$LOG_FILE"
        
        # Create a Python installation directory manually
        set python_dir="$PYENV_ROOT/versions/$python_version"
        mkdir -p "$python_dir/bin"
        
        # Download and extract a precompiled Python package
        echo "Attempting to download a precompiled Python package..." |& tee -a "$LOG_FILE"
        set temp_dir="/tmp/python_install_$TIMESTAMP"
        mkdir -p "$temp_dir"
        cd "$temp_dir"
        
        # Try to find a precompiled Python version
        echo "Checking for Miniconda as an alternative..." |& tee -a "$LOG_FILE"
        set miniconda_url="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
        curl -o miniconda.sh "$miniconda_url" |& tee -a "$LOG_FILE"
        
        if ($status == 0) then
            echo "Installing Miniconda as an alternative to pyenv..." |& tee -a "$LOG_FILE"
            bash miniconda.sh -b -p "$HOME/miniconda3" |& tee -a "$LOG_FILE"
            
            if ($status == 0) then
                echo "✅ Miniconda installed successfully" |& tee -a "$LOG_FILE"
                setenv PATH "$HOME/miniconda3/bin:$PATH"
                
                # Create a Python 3.11 environment
                echo "Creating a Python 3.11 environment with Miniconda..." |& tee -a "$LOG_FILE"
                $HOME/miniconda3/bin/conda create -y -n py311 python=3.11 |& tee -a "$LOG_FILE"
                
                if ($status == 0) then
                    echo "✅ Python $python_version environment created with Miniconda" |& tee -a "$LOG_FILE"
                    setenv PYTHON_CMD "$HOME/miniconda3/envs/py311/bin/python"
                    
                    # Create a symlink in the pyenv directory
                    ln -sf "$HOME/miniconda3/envs/py311" "$python_dir"
                    echo "✅ Linked Miniconda Python to pyenv directory" |& tee -a "$LOG_FILE"
                else
                    echo "❌ Failed to create Python environment with Miniconda" |& tee -a "$LOG_FILE"
                    exit 1
                endif
            else
                echo "❌ Failed to install Miniconda" |& tee -a "$LOG_FILE"
                exit 1
            endif
        else
            echo "❌ Failed to download Miniconda" |& tee -a "$LOG_FILE"
            exit 1
        endif
    else
        echo "✅ Python $python_version installed successfully" |& tee -a "$LOG_FILE"
    endif
endif

# Set Python as the local version
echo "Setting Python $python_version as the local version..." |& tee -a "$LOG_FILE"
$PYENV_ROOT/bin/pyenv local "$python_version"

if ($status == 0) then
    echo "✅ Set Python $python_version as the local version" |& tee -a "$LOG_FILE"
else
    echo "❌ Failed to set Python $python_version as local version" |& tee -a "$LOG_FILE"
    exit 1
endif

# Set up Python environment
echo "=== Setting up Python Environment ===" |& tee -a "$LOG_FILE"

# Check if we're using Miniconda Python
if ($?PYTHON_CMD) then
    echo "Using Miniconda Python: $PYTHON_CMD" |& tee -a "$LOG_FILE"
    
    # Activate the conda environment
    echo "Activating conda environment..." |& tee -a "$LOG_FILE"
    source $HOME/miniconda3/bin/activate py311
    
    # Upgrade pip
    echo "Upgrading pip..." |& tee -a "$LOG_FILE"
    $PYTHON_CMD -m pip install --upgrade pip |& tee -a "$LOG_FILE"
    
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
else
    # We're using the pyenv Python
    
    # Ensure we're using the correct Python version
    echo "Using pyenv Python $python_version" |& tee -a "$LOG_FILE"
    $PYENV_ROOT/bin/pyenv local "$python_version"
    
    if ($status != 0) then
        echo "❌ Failed to set Python $python_version as local version" |& tee -a "$LOG_FILE"
        exit 1
    else
        echo "✅ Set Python $python_version as the local version" |& tee -a "$LOG_FILE"
    endif
    
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
    if (-f requirements.txt) then
        pip install -r requirements.txt -v |& tee -a "$LOG_FILE"
        if ($status != 0) then
            echo "❌ Failed to install requirements" |& tee -a "$LOG_FILE"
            exit 1
        endif
    else
        echo "⚠️ No requirements.txt file found, skipping dependencies installation" |& tee -a "$LOG_FILE"
        echo "Creating an empty requirements.txt file for future use" |& tee -a "$LOG_FILE"
        touch requirements.txt
    endif
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
echo "=== Smoke Test Setup Completed at `date` ===" |& tee -a "$LOG_FILE" 