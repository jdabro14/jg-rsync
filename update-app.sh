#!/bin/bash

# Update JG-Rsync App
# This script updates the installed app with latest changes

set -e

echo "🔄 Updating JG-Rsync App..."

# Kill any running instances
pkill -f "JG-Rsync\|electron.*jg-rsync\|vite\|concurrently" || true

# Build everything properly
echo "🔨 Building project..."
npm run build:main
npm run build:renderer

# Update the installed app
echo "📦 Updating installed app..."
sudo cp electron/main.js /Applications/JG-Rsync.app/Contents/Resources/
sudo cp electron/preload.js /Applications/JG-Rsync.app/Contents/Resources/ 2>/dev/null || echo "No preload file to update"
sudo cp -R dist /Applications/JG-Rsync.app/Contents/Resources/renderer
sudo cp package.json /Applications/JG-Rsync.app/Contents/Resources/

# Update node_modules if it exists
if [ -d "node_modules" ]; then
    echo "📦 Updating dependencies..."
    sudo rm -rf /Applications/JG-Rsync.app/Contents/Resources/node_modules
    sudo cp -R node_modules /Applications/JG-Rsync.app/Contents/Resources/
fi

# Set proper permissions
sudo chmod -R 755 /Applications/JG-Rsync.app

echo "✅ App updated successfully!"
echo ""
echo "🎉 JG-Rsync has been updated with your latest changes"
echo "   - Updated source code"
echo "   - Updated dependencies"
echo "   - All files are self-contained"
echo ""
echo "🚀 You can now launch JG-Rsync from Applications or Launchpad"
echo "   Double-click the app in /Applications to launch it!"