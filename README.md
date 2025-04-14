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

## Setup

1. Ensure you have Python 3.6+ installed
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