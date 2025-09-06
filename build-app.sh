#!/bin/bash

# Build script for JG-Rsync macOS Application Bundle
# This script creates a complete .app bundle ready for installation

set -e

echo "🔨 Building JG-Rsync macOS Application Bundle..."

# Clean up any existing build
if [ -d "JG-Rsync.app" ]; then
    echo "🧹 Cleaning up existing .app bundle..."
    rm -rf JG-Rsync.app
fi

# Create the app bundle structure
echo "📁 Creating app bundle structure..."
mkdir -p JG-Rsync.app/Contents/MacOS
mkdir -p JG-Rsync.app/Contents/Resources

# Create Info.plist
echo "📝 Creating Info.plist..."
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
            <key>LSHandlerRank</key>
            <string>Alternate</string>
        </dict>
    </array>
</dict>
</plist>
EOF

# Create the executable launcher
echo "🚀 Creating executable launcher..."
cat > JG-Rsync.app/Contents/MacOS/JG-Rsync << 'EOF'
#!/bin/bash

# JG-Rsync macOS Application Launcher
# This script launches the JG-Rsync file transfer application

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"

# Change to the application directory
cd "$APP_DIR"

# Check if we're in the right directory
if [ ! -f "start.sh" ]; then
    echo "Error: start.sh not found in $APP_DIR"
    echo "Please ensure the JG-Rsync.app is in the same directory as the start.sh script"
    osascript -e 'display dialog "Error: JG-Rsync application files not found. Please ensure the .app bundle is in the correct location." buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi

# Make start.sh executable
chmod +x start.sh

# Launch the application
echo "Starting JG-Rsync..."
exec ./start.sh
EOF

# Make the launcher executable
chmod +x JG-Rsync.app/Contents/MacOS/JG-Rsync

# Create custom icon
echo "🎨 Creating custom JG-Rsync icon..."
python3 create-simple-icon.py

# Copy application files to Resources
echo "📦 Embedding application files..."
cp start.sh JG-Rsync.app/Contents/Resources/
cp package.json JG-Rsync.app/Contents/Resources/
cp index.html JG-Rsync.app/Contents/Resources/
cp -R src JG-Rsync.app/Contents/Resources/
cp -R node_modules JG-Rsync.app/Contents/Resources/ 2>/dev/null || echo "⚠️  Warning: node_modules not found, will be created on first run"

# Set proper permissions
chmod -R 755 JG-Rsync.app

echo "✅ JG-Rsync.app bundle created successfully!"
echo ""
echo "📋 Installation instructions:"
echo "1. Copy JG-Rsync.app to your /Applications folder:"
echo "   sudo cp -R JG-Rsync.app /Applications/"
echo ""
echo "2. Or drag and drop JG-Rsync.app to your Applications folder in Finder"
echo ""
echo "3. Launch JG-Rsync from Launchpad or Applications folder"
echo ""
echo "⚠️  Note: The .app bundle must remain in the same directory as start.sh"
echo "   for the application to work properly."
