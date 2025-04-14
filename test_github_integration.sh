#!/bin/bash

# Configuration
REPO_URL="$1"
TEST_DIR="github_test_$(date +%Y%m%d_%H%M%S)"

# Check if repository URL is provided
if [ -z "$REPO_URL" ]; then
    echo "Error: Please provide the GitHub repository URL"
    echo "Usage: ./test_github_integration.sh <repository-url>"
    exit 1
fi

echo "Starting GitHub integration test..."
echo "Repository URL: $REPO_URL"
echo "Test directory: $TEST_DIR"
echo ""

# Create test directory
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Test 1: Clone repository
echo "Test 1: Cloning repository..."
if git clone "$REPO_URL" .; then
    echo "✅ Repository cloned successfully"
else
    echo "❌ Failed to clone repository"
    exit 1
fi

# Test 2: Check Python environment
echo ""
echo "Test 2: Setting up Python environment..."
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Test 3: Run smoke test
echo ""
echo "Test 3: Running smoke test..."
if python smoke_test.py; then
    echo "✅ Smoke test completed successfully"
else
    echo "❌ Smoke test failed"
    exit 1
fi

# Cleanup
echo ""
echo "Cleaning up..."
cd ..
rm -rf "$TEST_DIR"
echo "Test completed successfully!" 