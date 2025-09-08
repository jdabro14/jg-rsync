#!/bin/bash

# Simple launcher for JG-Rsync
# This script launches the app in development mode

echo "Starting JG-Rsync..."

# Check if npm is available
if ! command -v npm &> /dev/null; then
    echo "Error: npm is not installed"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "Error: package.json not found. Please run this script from the project root."
    exit 1
fi

# Start the development server
echo "Launching JG-Rsync in development mode..."
npm run dev
