#!/bin/bash

# Quick update script for JG-Rsync
# This script updates the app with latest changes and fixes

set -e

echo "🔄 Quick update for JG-Rsync..."

# Kill any running instances
echo "🧹 Cleaning up running instances..."
pkill -f "JG-Rsync\|electron.*jg-rsync\|vite\|concurrently" || true

# Build the project
echo "🔨 Building project..."
npm run build:main

# Update the installed app
echo "📦 Updating installed app..."
sudo cp dist/main.js /Applications/JG-Rsync.app/Contents/Resources/dist/
sudo cp package.json /Applications/JG-Rsync.app/Contents/Resources/
sudo cp index.html /Applications/JG-Rsync.app/Contents/Resources/
sudo cp -R src /Applications/JG-Rsync.app/Contents/Resources/

# Update node_modules if it exists
if [ -d "node_modules" ]; then
    echo "📦 Updating dependencies..."
    sudo rm -rf /Applications/JG-Rsync.app/Contents/Resources/node_modules
    sudo cp -R node_modules /Applications/JG-Rsync.app/Contents/Resources/
fi

# Set proper permissions
sudo chmod -R 755 /Applications/JG-Rsync.app

echo "✅ Update complete!"
echo ""
echo "🎉 JG-Rsync has been updated with your latest changes"
echo "   - Updated source code"
echo "   - Updated dependencies"
echo "   - Fixed icon"
echo ""
echo "🚀 You can now launch JG-Rsync from Applications or Launchpad"
echo "   The app should show the new icon and your latest changes!"
