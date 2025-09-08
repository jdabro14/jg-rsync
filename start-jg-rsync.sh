#!/bin/bash

# JG-Rsync Launcher
# This script launches the JG-Rsync application in development mode

echo "🚀 Starting JG-Rsync..."

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change to the project directory
cd "$SCRIPT_DIR"

# Check if npm is available
if ! command -v npm &> /dev/null; then
    echo "❌ Error: npm is not installed"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "❌ Error: package.json not found. Please run this script from the project root."
    exit 1
fi

# Check if dist directory exists, if not build it
if [ ! -d "dist/main" ]; then
    echo "🔨 Building TypeScript files..."
    npx tsc
    if [ $? -ne 0 ]; then
        echo "❌ Error: TypeScript compilation failed"
        exit 1
    fi
fi

# Start the development server
echo "✅ Launching JG-Rsync in development mode..."
echo "📱 The app will open in a new window"
echo "🛑 Press Ctrl+C to stop the application"
echo ""

npm run dev
