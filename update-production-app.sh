#!/bin/bash

# Update the production JG-Rsync app in /Applications
# This script rebuilds the app and updates the installed version

set -e

echo "🔄 Updating production JG-Rsync app..."

# Kill any running instances
echo "🛑 Stopping running instances..."
pkill -f "JG-Rsync\|electron.*main.js" 2>/dev/null || true

# Build the project
echo "📦 Building the project..."
npx tsc
npm run build:renderer

# Rebuild main.js after vite clears the dist directory
echo "🔧 Rebuilding main.js after vite build..."
npx tsc

# Update the installed app
echo "📋 Updating installed app files..."
sudo cp dist/main.js /Applications/JG-Rsync.app/Contents/Resources/
sudo cp -r dist/renderer /Applications/JG-Rsync.app/Contents/Resources/
sudo cp index.html /Applications/JG-Rsync.app/Contents/Resources/

# Update the launcher script with the correct Electron path
echo "🔧 Updating launcher script..."
sudo tee /Applications/JG-Rsync.app/Contents/MacOS/JG-Rsync > /dev/null << 'EOF'
#!/bin/bash

# JG-Rsync Working Electron Launcher
# This script launches the JG-Rsync file transfer application

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOURCES_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")/Contents/Resources"

# Change to the resources directory
cd "$RESOURCES_DIR"

# Check if we have the required files
if [ ! -f "main.js" ]; then
    echo "Error: main.js not found in $RESOURCES_DIR"
    osascript -e 'display dialog "Error: JG-Rsync application files not found. Please reinstall the application." buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi

# Find the Electron executable
ELECTRON_PATH="$RESOURCES_DIR/node_modules/electron/dist/Electron.app/Contents/MacOS/Electron"
if [ ! -f "$ELECTRON_PATH" ]; then
    echo "Error: Electron not found at $ELECTRON_PATH"
    osascript -e 'display dialog "Error: Electron runtime not found. Please reinstall the application." buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi

# Launch the application using the local Electron
echo "Starting JG-Rsync with local Electron..."
exec "$ELECTRON_PATH" main.js
EOF

# Set proper permissions
sudo chmod +x /Applications/JG-Rsync.app/Contents/MacOS/JG-Rsync

# Clear icon cache
echo "🧹 Clearing icon cache..."
killall Dock 2>/dev/null || true

echo "✅ Production app updated successfully!"
echo "📱 App location: /Applications/JG-Rsync.app"
echo ""
echo "To test:"
echo "  open /Applications/JG-Rsync.app"
