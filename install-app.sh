#!/bin/bash

# Installation script for JG-Rsync macOS Application
# This script installs the .app bundle to /Applications

set -e

echo "🚀 Installing JG-Rsync to /Applications..."

# Check if the .app bundle exists
if [ ! -d "JG-Rsync.app" ]; then
    echo "❌ Error: JG-Rsync.app not found in current directory"
    echo "Please run ./build-app.sh first to create the .app bundle"
    exit 1
fi

# Check if start.sh exists (required for the app to work)
if [ ! -f "start.sh" ]; then
    echo "❌ Error: start.sh not found in current directory"
    echo "The .app bundle requires start.sh to be in the same directory"
    exit 1
fi

# Create a temporary directory for installation
TEMP_DIR=$(mktemp -d)
echo "📁 Creating installation package..."

# Copy the .app bundle
cp -R JG-Rsync.app "$TEMP_DIR/"

# The .app bundle already contains all necessary files in Resources
# No need to copy additional files

# Install to /Applications
echo "📦 Installing to /Applications..."
sudo cp -R "$TEMP_DIR/JG-Rsync.app" /Applications/

# Set proper permissions
sudo chmod -R 755 /Applications/JG-Rsync.app

# Clean up
rm -rf "$TEMP_DIR"

echo "✅ JG-Rsync successfully installed to /Applications!"
echo ""
echo "🎉 You can now launch JG-Rsync from:"
echo "   • Launchpad"
echo "   • Applications folder in Finder"
echo "   • Spotlight search (Cmd+Space, then type 'JG-Rsync')"
echo ""
echo "📝 Note: The application will automatically install dependencies on first run"
echo "   if node_modules is not present."
