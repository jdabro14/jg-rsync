#!/bin/bash

# Create Proper macOS App Bundle
# This creates a production-ready Electron app following macOS standards

set -e

echo "🔧 Creating Proper macOS App Bundle..."

# Kill any running processes
pkill -f "JG-Rsync\|electron.*jg-rsync\|vite\|concurrently" || true

# Remove broken installation
if [ -d "/Applications/JG-Rsync.app" ]; then
    echo "🗑️  Removing broken installation..."
    sudo rm -rf /Applications/JG-Rsync.app
fi

# Build everything properly
echo "🔨 Building project properly..."
npm run build:main
npm run build:renderer

# Create proper app bundle structure
echo "📁 Creating proper app bundle structure..."
mkdir -p JG-Rsync.app/Contents/MacOS
mkdir -p JG-Rsync.app/Contents/Resources

# Create proper Info.plist
echo "📝 Creating proper Info.plist..."
cat > JG-Rsync.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>JG-Rsync</string>
    <key>CFBundleIdentifier</key>
    <string>com.jg-rsync.app</string>
    <key>CFBundleName</key>
    <string>JG-Rsync</string>
    <key>CFBundleDisplayName</key>
    <string>JG-Rsync</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleIconFile</key>
    <string>icon.icns</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSRequiresAquaSystemAppearance</key>
    <false/>
    <key>LSUIElement</key>
    <false/>
    <key>NSAppleScriptEnabled</key>
    <true/>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>All Files</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
        </dict>
    </array>
</dict>
</plist>
EOF

# Create proper launcher that uses built files
echo "🚀 Creating proper launcher..."
cat > JG-Rsync.app/Contents/MacOS/JG-Rsync << 'EOF'
#!/bin/bash

# JG-Rsync Proper macOS Launcher
# This script launches the JG-Rsync file transfer application

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOURCES_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")/Contents/Resources"

# Change to the resources directory
cd "$RESOURCES_DIR"

# Check if we have the required files
if [ ! -f "main.js" ]; then
    echo "Error: main.js not found in $RESOURCES_DIR"
    echo "Contents of Resources directory:"
    ls -la "$RESOURCES_DIR"
    osascript -e 'display dialog "Error: JG-Rsync application files not found. Please reinstall the application." buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi

# Launch the application using the built main.js
echo "Starting JG-Rsync..."
exec node main.js
EOF

# Make the launcher executable
chmod +x JG-Rsync.app/Contents/MacOS/JG-Rsync

# Create proper icon
echo "🎨 Creating proper icon..."
python3 create-better-icon.py

# Copy built files to Resources
echo "📦 Copying built files..."
cp electron/main.js JG-Rsync.app/Contents/Resources/
cp electron/preload.js JG-Rsync.app/Contents/Resources/ 2>/dev/null || echo "No preload file to copy"

# Copy built renderer files
if [ -d "dist/renderer" ]; then
    cp -R dist/renderer JG-Rsync.app/Contents/Resources/
else
    echo "⚠️  No built renderer found, creating fallback..."
    mkdir -p JG-Rsync.app/Contents/Resources/renderer
    cp index.html JG-Rsync.app/Contents/Resources/renderer/
fi

# Copy package.json and install production dependencies
cp package.json JG-Rsync.app/Contents/Resources/
cd JG-Rsync.app/Contents/Resources/
npm install --production --silent
cd - > /dev/null

# Set proper permissions
chmod -R 755 JG-Rsync.app

# Install to /Applications
echo "📦 Installing to /Applications..."
sudo cp -R JG-Rsync.app /Applications/
sudo chmod -R 755 /Applications/JG-Rsync.app

# Clear icon cache
echo "🧹 Clearing icon cache..."
sudo rm -rf /Library/Caches/com.apple.iconservices.store
sudo find /private/var/folders -name "com.apple.dock.iconcache" -delete 2>/dev/null || true
killall Dock 2>/dev/null || true

# Clean up
rm -rf JG-Rsync.app

echo "✅ Proper macOS app bundle created and installed!"
echo ""
echo "🧪 Testing the app..."
sleep 2

# Test the app
if /Applications/JG-Rsync.app/Contents/MacOS/JG-Rsync & then
    sleep 5
    if ps aux | grep -i "node.*main.js" | grep -v grep > /dev/null; then
        echo "✅ JG-Rsync is running successfully!"
        echo "🎉 The app is now working properly!"
    else
        echo "❌ App failed to start - checking logs..."
        # Check what happened
        ps aux | grep -i "jg-rsync\|electron\|node" | grep -v grep
    fi
else
    echo "❌ Failed to launch app"
fi

echo ""
echo "🚀 You can now double-click JG-Rsync in Applications!"
echo "   The app should show the proper icon and load the UI correctly."
