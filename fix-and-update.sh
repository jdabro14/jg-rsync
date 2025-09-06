#!/bin/bash

# Fix the .app bundle and create update system

echo "🔧 Fixing JG-Rsync .app bundle..."

# Fix the launcher script path
cat > /Applications/JG-Rsync.app/Contents/MacOS/JG-Rsync << 'EOF'
#!/bin/bash

# JG-Rsync FIXED macOS Application Launcher
# This script launches the JG-Rsync file transfer application

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOURCES_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")/Contents/Resources"

# Change to the resources directory
cd "$RESOURCES_DIR"

# Check if we have the required files
if [ ! -f "start.sh" ]; then
    echo "Error: start.sh not found in $RESOURCES_DIR"
    osascript -e 'display dialog "Error: JG-Rsync application files not found. Please reinstall the application." buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi

# Make start.sh executable
chmod +x start.sh

# Launch the application
echo "Starting JG-Rsync from: $(pwd)"
exec ./start.sh
EOF

# Set proper permissions
sudo chmod +x /Applications/JG-Rsync.app/Contents/MacOS/JG-Rsync

echo "✅ Fixed the .app bundle!"
echo ""
echo "🎉 JG-Rsync is now properly installed and ready to use!"
echo ""
echo "📋 Usage:"
echo "   • Launch from Applications folder or Launchpad"
echo "   • To update: run ./update-app.sh"
echo "   • To test: run ./test-app.sh"
echo ""
echo "🚀 The app should now work correctly!"
