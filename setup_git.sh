#!/bin/bash

# Initialize Git repository
git init

# Create .gitignore file
cat > .gitignore << EOL
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
*.egg-info/
.installed.cfg
*.egg

# Logs
logs/
*.log

# Virtual Environment
venv/
ENV/

# IDE
.idea/
.vscode/
*.swp
*.swo
EOL

# Add and commit files
git add .
git commit -m "Initial commit: Smoke test application"

# Get the current branch name
CURRENT_BRANCH=$(git branch --show-current)

echo "Git repository initialized successfully!"
echo ""
echo "Next steps:"
echo "1. Create a new repository on GitHub (without README or .gitignore)"
echo "2. Run the following commands:"
echo "   git remote add origin <your-github-repo-url>"
echo "   git push -u origin $CURRENT_BRANCH"
echo ""
echo "After pushing to GitHub, you can test pulling on your compute server with:"
echo "git clone <your-github-repo-url>" 