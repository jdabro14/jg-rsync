#!/bin/bash

# JG-Rsync Production Launcher
# This script launches the JG-Rsync application directly from the project directory

# Set the project directory path
PROJECT_DIR="/Users/jgingold/Library/CloudStorage/GoogleDrive-jdabro@gmail.com/My Drive/Personal/Personal/ABXTA/RSYNC"

# Change to the project directory
cd "$PROJECT_DIR"

# Check if we have the required files
if [ ! -f "package.json" ]; then
    echo "Error: package.json not found in $PROJECT_DIR"
    osascript -e 'display dialog "Error: JG-Rsync application files not found. Please check the project directory." buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "Error: Node.js is not installed"
    osascript -e 'display dialog "Error: Node.js is required but not installed. Please install Node.js first." buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi

# Set environment variables
export NODE_ENV=production

# Check if Electron is installed via npm
if [ -f "node_modules/.bin/electron" ]; then
    ELECTRON_BIN="node_modules/.bin/electron"
else
    # Check if electron is installed globally
    if command -v electron &> /dev/null; then
        ELECTRON_BIN="electron"
    else
        echo "Error: Electron is not installed"
        osascript -e 'display dialog "Error: Electron is required but not installed. Installing now..." buttons {"OK"} default button "OK"'
        
        # Install electron locally
        echo "Installing Electron locally..."
        npm install --save-dev electron
        
        if [ $? -ne 0 ]; then
            osascript -e 'display dialog "Error: Failed to install Electron. Please install it manually with: npm install --save-dev electron" buttons {"OK"} default button "OK" with icon stop'
            exit 1
        fi
        
        ELECTRON_BIN="node_modules/.bin/electron"
    fi
fi

# Launch the application with Electron
echo "Starting JG-Rsync in production mode..."
echo "Using Electron binary: $ELECTRON_BIN"

# Launch with the current directory as the app
"$ELECTRON_BIN" .
