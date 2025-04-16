#!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root using:"
    echo "sudo ./change_wsl_shell.sh"
    exit 1
fi

# Check if tcsh is installed
if ! command -v tcsh &> /dev/null; then
    echo "Installing tcsh..."
    apt-get update
    apt-get install -y tcsh
    if [ $? -ne 0 ]; then
        echo "Failed to install tcsh"
        exit 1
    fi
    echo "✅ tcsh installed successfully"
else
    echo "✅ tcsh is already installed"
fi

# Get the current user
CURRENT_USER=$(whoami)

# Create .tcshrc if it doesn't exist
if [ ! -f "/home/$CURRENT_USER/.tcshrc" ]; then
    echo "Creating .tcshrc file..."
    cat > "/home/$CURRENT_USER/.tcshrc" << 'EOL'
# Set PATH
set path = (/usr/local/bin /usr/bin /bin /usr/local/games /usr/games)

# Set prompt
set prompt = "%n@%m:%~%# "

# Set history
set history = 1000
set savehist = 1000

# Set editor
setenv EDITOR vim

# Set language
setenv LANG en_US.UTF-8

# Set umask
umask 022

# Aliases
alias ls 'ls --color=auto'
alias ll 'ls -l'
alias la 'ls -A'
alias l 'ls -CF'
alias .. 'cd ..'
alias ... 'cd ../..'
alias .... 'cd ../../..'
EOL
    chown $CURRENT_USER:$CURRENT_USER "/home/$CURRENT_USER/.tcshrc"
    echo "✅ .tcshrc file created"
else
    echo "✅ .tcshrc file already exists"
fi

# Change the default shell
echo "Changing default shell to tcsh..."
usermod -s /bin/tcsh $CURRENT_USER
if [ $? -ne 0 ]; then
    echo "Failed to change default shell"
    exit 1
fi

echo ""
echo "✅ Default shell changed to tcsh successfully!"
echo ""
echo "To apply the changes:"
echo "1. Close your current WSL terminal"
echo "2. Open a new WSL terminal"
echo ""
echo "Your new shell will be tcsh with the following features:"
echo "- Colorized ls output"
echo "- Common aliases (ll, la, l, .., etc.)"
echo "- UTF-8 language settings"
echo "- 1000 command history"
echo ""
echo "To verify the change, run:"
echo "echo $SHELL"
echo ""
echo "If you want to switch back to bash, run:"
echo "sudo usermod -s /bin/bash $CURRENT_USER" 