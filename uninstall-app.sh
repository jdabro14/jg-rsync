mul#!/bin/bash

# Uninstallation script for JG-Rsync macOS Application
# This script removes the .app bundle from /Applications

set -e

echo "🗑️  Uninstalling JG-Rsync from /Applications..."

# Check if the app is installed
if [ ! -d "/Applications/JG-Rsync.app" ]; then
    echo "❌ JG-Rsync.app not found in /Applications"
    echo "The application may not be installed or may have been moved"
    exit 1
fi

# Remove the application
echo "📦 Removing JG-Rsync.app from /Applications..."
sudo rm -rf /Applications/JG-Rsync.app

# Check if removal was successful
if [ ! -d "/Applications/JG-Rsync.app" ]; then
    echo "✅ JG-Rsync successfully uninstalled from /Applications!"
    echo ""
    echo "🧹 Note: Application data and preferences may still exist in:"
    echo "   • ~/Library/Application Support/jg-rsync"
    echo "   • ~/.jg-rsync"
    echo ""
    echo "   You can manually delete these directories if you want to remove all traces."
else
    echo "❌ Failed to remove JG-Rsync.app from /Applications"
    echo "You may need to remove it manually or check permissions"
    exit 1
fi
