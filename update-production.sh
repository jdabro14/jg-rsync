#!/bin/bash

# Update Production JG-Rsync App
# This script updates the installed app with latest changes

set -e

echo "🔄 Updating Production JG-Rsync App..."

# Kill any running instances
pkill -f "JG-Rsync\|electron.*jg-rsync\|vite\|concurrently" || true

# Build the project
echo "🔨 Building project..."
npm run build:main

# Update the installed app
echo "📦 Updating installed app..."
sudo cp dist/main.js /Applications/JG-Rsync.app/Contents/Resources/dist/
sudo cp package.json /Applications/JG-Rsync.app/Contents/Resources/
sudo cp index.html /Applications/JG-Rsync.app/Contents/Resources/
sudo cp tsconfig.json /Applications/JG-Rsync.app/Contents/Resources/
sudo cp -R src /Applications/JG-Rsync.app/Contents/Resources/

# Update node_modules if it exists
if [ -d "node_modules" ]; then
    echo "📦 Updating dependencies..."
    sudo rm -rf /Applications/JG-Rsync.app/Contents/Resources/node_modules
    sudo cp -R node_modules /Applications/JG-Rsync.app/Contents/Resources/
fi

# Set proper permissions
sudo chmod -R 755 /Applications/JG-Rsync.app

echo "✅ Production app updated successfully!"
echo ""
echo "🎉 JG-Rsync has been updated with your latest changes"
echo "   - Updated source code"
echo "   - Updated dependencies"
echo "   - All files are self-contained"
echo ""
echo "🚀 You can now launch JG-Rsync from Applications or Launchpad"
echo "   Double-click the app in /Applications to launch it!"
