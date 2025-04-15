#!/bin/bash

# Function to check build dependencies
check_build_dependencies() {
    echo "=== Checking Build Dependencies ==="
    
    # Check for basic tools in PATH
    local required_tools=(
        "git"
        "curl"
        "gcc"
        "make"
    )
    
    local missing_tools=()
    
    for tool in "${required_tools[@]}"; do
        echo -n "Checking $tool... "
        if ! command -v "$tool" >/dev/null 2>&1; then
            echo "❌ Not found"
            missing_tools+=("$tool")
        else
            echo "✅ Found"
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo "❌ Missing required tools: ${missing_tools[*]}"
        echo "⚠️  These tools need to be available in your PATH"
        return 1
    fi
    
    # Check for write permissions in home directory
    echo -n "Checking home directory permissions... "
    if [ ! -w "$HOME" ]; then
        echo "❌ No write permission in home directory"
        return 1
    else
        echo "✅ Write permission available"
    fi
    
    echo "✅ All build requirements met"
    return 0
}

# Function to detect shell type
detect_shell() {
    if [ -n "$BASH_VERSION" ]; then
        echo "bash"
    elif [ -n "$ZSH_VERSION" ]; then
        echo "zsh"
    elif [ -n "$tcsh" ]; then  # tcsh specific variable
        echo "tcsh"
    elif [ -n "$version" ]; then  # csh sets this variable
        echo "csh"
    else
        echo "unknown"
    fi
}

# Function to configure pyenv for the current shell
configure_pyenv() {
    local shell_type=$(detect_shell)
    local config_file
    
    case "$shell_type" in
        "bash")
            config_file="$HOME/.bashrc"
            echo 'export PYENV_ROOT="$HOME/.pyenv"' >> "$config_file"
            echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> "$config_file"
            echo 'eval "$(pyenv init -)"' >> "$config_file"
            ;;
        "zsh")
            config_file="$HOME/.zshrc"
            echo 'export PYENV_ROOT="$HOME/.pyenv"' >> "$config_file"
            echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> "$config_file"
            echo 'eval "$(pyenv init -)"' >> "$config_file"
            ;;
        "tcsh")
            config_file="$HOME/.tcshrc"
            echo 'setenv PYENV_ROOT "$HOME/.pyenv"' >> "$config_file"
            echo 'set path = ($HOME/.pyenv/bin $path)' >> "$config_file"
            echo 'eval `pyenv init -`' >> "$config_file"
            ;;
        "csh")
            config_file="$HOME/.cshrc"
            echo 'setenv PYENV_ROOT "$HOME/.pyenv"' >> "$config_file"
            echo 'set path = ($PYENV_ROOT/bin $path)' >> "$config_file"
            echo 'eval "`pyenv init -`"' >> "$config_file"
            ;;
        *)
            echo "❌ Unsupported shell type: $shell_type"
            return 1
            ;;
    esac
    
    echo "✅ pyenv configured for $shell_type in $config_file"
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
    
    # Configure pyenv for the current shell
    if ! configure_pyenv; then
        echo "❌ Failed to configure pyenv"
        return 1
    fi
    
    # Source the updated configuration
    echo "Sourcing updated configuration..."
    case "$(detect_shell)" in
        "bash"|"zsh")
            source ~/.bashrc 2>/dev/null || source ~/.zshrc 2>/dev/null
            ;;
        "tcsh")
            source ~/.tcshrc 2>/dev/null
            ;;
        "csh")
            source ~/.cshrc 2>/dev/null
            ;;
    esac
    
    echo "✅ pyenv installed and configured successfully"
    return 0
}

# Function to install Python 3.11 using pyenv
install_python_311() {
    echo "=== Installing Python 3.11 ==="
    local python_install_log="$TEST_DIR/python_install.log"
    local python_version="3.11.8"  # Latest stable 3.11.x version
    
    # Check if Python 3.11 is already installed
    if pyenv versions | grep -q "3.11"; then
        echo "✅ Python 3.11 is already installed"
    else
        echo "Installing Python $python_version..."
        echo "Logging installation to $python_install_log"
        
        # Install Python with detailed logging
        if ! pyenv install "$python_version" > "$python_install_log" 2>&1; then
            echo "❌ Failed to install Python $python_version"
            echo "Installation log:"
            cat "$python_install_log"
            return 1
        fi
        
        echo "✅ Python $python_version installed successfully"
    fi
    
    # Set Python as the local version
    echo "Setting Python $python_version as the local version..."
    if ! pyenv local "$python_version"; then
        echo "❌ Failed to set Python $python_version as local version"
        return 1
    fi
    
    echo "✅ Set Python $python_version as the local version"
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

# Function to set up Python environment
setup_python_environment() {
    echo "=== Setting up Python Environment ==="
    
    # Install pyenv
    if ! install_pyenv; then
        echo "❌ pyenv installation failed"
        return 1
    fi
    
    # Install Python 3.11
    if ! install_python_311; then
        echo "❌ Python 3.11 installation failed"
        return 1
    fi
    
    # Create and activate virtual environment
    echo "Creating virtual environment..."
    python -m venv venv
    source venv/bin/activate
    
    # Upgrade pip to latest version
    echo "Upgrading pip..."
    python -m pip install --upgrade pip
    
    # Install build dependencies first
    echo "Installing build dependencies..."
    pip install wheel setuptools
    
    # Install dependencies with retry logic
    echo "Installing project dependencies..."
    for attempt in {1..3}; do
        if pip install -r requirements.txt; then
            break
        fi
        echo "Attempt $attempt failed, retrying..."
        sleep 5
    done
    
    # Verify installations
    echo "Verifying installations..."
    if ! python -c "import dotenv, structlog, git" 2>/dev/null; then
        echo "❌ Failed to install required packages"
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

# Main script execution
echo "=== Setting up smoke test environment ==="

# Create a temporary directory for the test in user's home directory
TEST_DIR="$HOME/smoke_test_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

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

# Set up Python environment
if ! setup_python_environment; then
    echo "❌ Python environment setup failed"
    exit 1
fi

# Create logs directory with user permissions
echo "Creating logs directory..."
mkdir -p logs
chmod 700 logs  # User-only permissions

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

echo ""
echo "=== Setup Complete ==="
echo "Logs directory: $TEST_DIR/logs/"
echo ""
echo "To view the latest log file:"
echo "ls -ltr $TEST_DIR/logs/"
echo ""
echo "To clean up when done, run:"
echo "rm -rf $TEST_DIR" 