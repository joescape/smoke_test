#!/bin/bash

# Purpose: Tests GitHub integration by cloning a repository and running the smoke test
# Usage: ./test_github_integration.sh <repository-url>

# Configuration
REPO_URL="$1"
TEST_DIR="github_test_$(date +%Y%m%d_%H%M%S)"
LOG_FILE="github_integration_test_$(date +%Y%m%d_%H%M%S).log"

# Display help if --help or -h is passed
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Usage: ./test_github_integration.sh <repository-url>"
    echo ""
    echo "This script tests GitHub integration by:"
    echo "  1. Cloning the specified repository"
    echo "  2. Setting up a Python virtual environment"
    echo "  3. Installing requirements"
    echo "  4. Running the smoke test"
    echo ""
    echo "The test is performed in a temporary directory that is deleted after completion."
    exit 0
fi

# Check if repository URL is provided
if [ -z "$REPO_URL" ]; then
    echo "Error: Please provide the GitHub repository URL"
    echo "Usage: ./test_github_integration.sh <repository-url>"
    echo "For help, use: ./test_github_integration.sh --help"
    exit 1
fi

# Create log directory if it doesn't exist
mkdir -p logs

echo "Starting GitHub integration test..." | tee -a "logs/$LOG_FILE"
echo "Repository URL: $REPO_URL" | tee -a "logs/$LOG_FILE"
echo "Test directory: $TEST_DIR" | tee -a "logs/$LOG_FILE" 
echo "Log file: logs/$LOG_FILE" | tee -a "logs/$LOG_FILE"
echo "" | tee -a "logs/$LOG_FILE"

# Create test directory
mkdir -p "$TEST_DIR" || { echo "❌ Failed to create test directory" | tee -a "logs/$LOG_FILE"; exit 1; }
cd "$TEST_DIR" || { echo "❌ Failed to change to test directory" | tee -a "logs/$LOG_FILE"; exit 1; }

# Test 1: Clone repository
echo "Test 1: Cloning repository..." | tee -a "../logs/$LOG_FILE"
if git clone "$REPO_URL" .; then
    echo "✅ Repository cloned successfully" | tee -a "../logs/$LOG_FILE"
else
    echo "❌ Failed to clone repository" | tee -a "../logs/$LOG_FILE"
    cd .. && rm -rf "$TEST_DIR"
    exit 1
fi

# Test 2: Check Python environment
echo "" | tee -a "../logs/$LOG_FILE"
echo "Test 2: Setting up Python environment..." | tee -a "../logs/$LOG_FILE"

# Check if requirements.txt exists
if [ ! -f "requirements.txt" ]; then
    echo "⚠️ No requirements.txt found in repository" | tee -a "../logs/$LOG_FILE"
    echo "Creating minimal requirements.txt file for testing" | tee -a "../logs/$LOG_FILE"
    echo "structlog>=20.1.0,<21.0.0" > requirements.txt
fi

# Create virtual environment
python3 -m venv venv || { echo "❌ Failed to create virtual environment" | tee -a "../logs/$LOG_FILE"; exit 1; }
source venv/bin/activate || { echo "❌ Failed to activate virtual environment" | tee -a "../logs/$LOG_FILE"; exit 1; }

# Install requirements
if pip install -r requirements.txt; then
    echo "✅ Requirements installed successfully" | tee -a "../logs/$LOG_FILE"
else
    echo "❌ Failed to install requirements" | tee -a "../logs/$LOG_FILE"
    cd .. && rm -rf "$TEST_DIR"
    exit 1
fi

# Test 3: Run smoke test
echo "" | tee -a "../logs/$LOG_FILE"
echo "Test 3: Running smoke test..." | tee -a "../logs/$LOG_FILE"

# Check if smoke_test.py exists
if [ ! -f "smoke_test.py" ]; then
    echo "❌ smoke_test.py file not found in repository" | tee -a "../logs/$LOG_FILE"
    cd .. && rm -rf "$TEST_DIR"
    exit 1
fi

if python smoke_test.py; then
    echo "✅ Smoke test completed successfully" | tee -a "../logs/$LOG_FILE"
else
    echo "❌ Smoke test failed" | tee -a "../logs/$LOG_FILE"
    cd .. && rm -rf "$TEST_DIR"
    exit 1
fi

# Cleanup
echo "" | tee -a "../logs/$LOG_FILE"
echo "Cleaning up..." | tee -a "../logs/$LOG_FILE"
cd .. || { echo "❌ Failed to navigate up to parent directory" | tee -a "logs/$LOG_FILE"; exit 1; }
rm -rf "$TEST_DIR"
echo "✅ Test directory removed" | tee -a "logs/$LOG_FILE"
echo "✅ Test completed successfully!" | tee -a "logs/$LOG_FILE"
echo "Log file saved at: logs/$LOG_FILE" | tee -a "logs/$LOG_FILE" 