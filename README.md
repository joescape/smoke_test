# Smoke Test Application

This application tests the ability to develop and deploy applications in WSL and RHEL7 environments.

## Features

- Comprehensive system information logging
- WSL-specific checks
- Environment variable verification
- File system operation testing
- Git and GitHub integration testing
  - Git version and configuration checks
  - GitHub repository cloning test
- Structured JSON logging for easy parsing
- Timestamped log files

## Prerequisites

1. Ensure you have Python 3.6+ installed
2. Git is installed and configured
3. (Optional) tcsh shell for compute server setup scripts

## Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/joescape/smoke_test.git
   cd smoke_test
   ```

2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Ensure Git is installed and configured:
   ```bash
   git --version
   git config --global user.name "Your Name"
   git config --global user.email "your.email@example.com"
   ```

## Usage

Run the smoke test:
```bash
python smoke_test.py
```

Logs will be created in the `logs` directory with timestamps in the filename.

## Available Scripts

The repository contains several utility scripts:

- **smoke_test.py**: The main smoke test script that verifies your environment
- **logging_config.py**: Configures structured JSON logging for the smoke test
- **setup_git.sh**: Sets up a Git repository with proper .gitignore for this project
- **test_github_integration.sh**: Tests GitHub integration by cloning a repository
- **compute_server_setup.sh**: Sets up the environment on a compute server using Miniconda
- **compute_server_setup_v2.sh**: An improved version of compute_server_setup.sh using pyenv

### Using the Compute Server Setup Scripts

These scripts are designed to be run on a RHEL7 or similar environment with tcsh as the shell:

```bash
# For Miniconda-based setup
./compute_server_setup.sh

# For pyenv-based setup (recommended)
./compute_server_setup_v2.sh
```

## Log Files

Log files are created in the `logs` directory with the format:
```
smoke_test_YYYYMMDD_HHMMSS.log
```

Each log entry is in JSON format for easy parsing and analysis.

## Environment Compatibility

- Windows Subsystem for Linux (WSL)
- RHEL7-based systems
- Python 3.6+
- Git 2.0+ 