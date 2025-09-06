#!/bin/bash

# JG-Rsync Production Startup Script
echo "🚀 Starting JG-Rsync..."

# Debug information
echo "Current directory: $(pwd)"
echo "Directory contents: $(ls -la)"

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    osascript -e 'display dialog "Node.js is required but not installed. Please install Node.js 18+ first." buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi

# Check if rsync is installed
if ! command -v rsync &> /dev/null; then
    osascript -e 'display dialog "rsync is required but not installed. Please install rsync first." buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi

# Check if dependencies are installed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install --production
    if [ $? -ne 0 ]; then
        osascript -e 'display dialog "Failed to install dependencies. Please check your internet connection and try again." buttons {"OK"} default button "OK" with icon stop'
        exit 1
    fi
fi

# Set environment variables
export NODE_ENV=production

# Start the application
echo "🎥 Starting JG-Rsync in production mode..."

# Try different methods to start the app with detailed error handling
if [ -f "electron/main.js" ]; then
    echo "Found electron/main.js, launching..."
    node electron/main.js
elif [ -f "dist/main/index.js" ]; then
    echo "Found dist/main/index.js, launching..."
    node dist/main/index.js
else
    # List available files to help diagnose the issue
    echo "Error: Could not find main entry point"
    echo "Files in current directory: $(ls -la)"
    echo "Files in electron directory (if exists): $(ls -la electron 2>/dev/null || echo 'electron directory not found')"
    echo "Files in dist directory (if exists): $(ls -la dist 2>/dev/null || echo 'dist directory not found')"
    
    osascript -e 'display dialog "Application entry point not found. Please reinstall the application." buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi
