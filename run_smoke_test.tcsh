#!/bin/tcsh

# Set up logging
set TIMESTAMP=`date +%Y%m%d_%H%M%S`
set LOG_DIR="logs"
mkdir -p "$LOG_DIR"
set LOG_FILE="$LOG_DIR/run_smoke_test_${TIMESTAMP}.log"

# Function to log messages
alias log 'echo \!* |& tee -a $LOG_FILE'

# Run the setup script
log "Running setup script..."
./compute_server_setup_pyenv.sh |& tee -a "$LOG_FILE"

if ($status != 0) then
    log "❌ Error: Setup failed"
    exit 1
endif

# Find the repository directory
set REPO_DIR=`find "$HOME" -name "smoke_test" -type d | head -n 1`
if ("$REPO_DIR" == "") then
    set REPO_DIR="$PWD/smoke_test"
endif

log "Found repository at: $REPO_DIR"

# Change to repository directory
cd "$REPO_DIR"
if ($status != 0) then
    log "❌ Error: Could not change to repository directory"
    exit 1
endif

# Activate virtual environment and run smoke test
log "Activating virtual environment and running smoke test..."
source .venv/bin/activate.csh
if ($status != 0) then
    log "❌ Error: Failed to activate virtual environment"
    exit 1
endif

# Run the smoke test
log "Running smoke test..."
python smoke_test.py |& tee -a "$LOG_FILE"

if ($status != 0) then
    log "❌ Error: Smoke test failed"
    exit 1
endif

log "✅ Smoke test completed successfully"
log "Log file: $LOG_FILE" 