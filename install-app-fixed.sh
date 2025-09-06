#!/bin/bash

# Fixed Installation script for JG-Rsync macOS Application
# This script creates a proper standalone .app bundle

set -e

echo "🚀 Installing JG-Rsync to /Applications (Fixed Version)..."

# Remove any existing installation
if [ -d "/Applications/JG-Rsync.app" ]; then
    echo "🗑️  Removing existing installation..."
    sudo rm -rf /Applications/JG-Rsync.app
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
</dict>
</plist>
EOF

# Create the FIXED executable launcher
echo "🚀 Creating FIXED launcher..."
cat > JG-Rsync.app/Contents/MacOS/JG-Rsync << 'EOF'
#!/bin/bash

# JG-Rsync FIXED macOS Application Launcher
# This script launches the JG-Rsync file transfer application

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOURCES_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")/Resources"

# Debug output
echo "Script directory: $SCRIPT_DIR"
echo "Resources directory: $RESOURCES_DIR"

# Change to the resources directory
cd "$RESOURCES_DIR"

# Check if we have the required files
if [ ! -f "start.sh" ]; then
    echo "Error: start.sh not found in $RESOURCES_DIR"
    echo "Contents of Resources directory:"
    ls -la "$RESOURCES_DIR"
    osascript -e 'display dialog "Error: JG-Rsync application files not found. Please reinstall the application." buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi

# Make start.sh executable
chmod +x start.sh

# Launch the application
echo "Starting JG-Rsync from: $(pwd)"
exec ./start.sh
EOF

# Make the launcher executable
chmod +x JG-Rsync.app/Contents/MacOS/JG-Rsync

# Create custom icon
echo "🎨 Creating custom JG-Rsync icon..."
python3 create-simple-icon.py

# Copy all application files to Resources
echo "📦 Embedding application files..."
cp start.sh JG-Rsync.app/Contents/Resources/
cp package.json JG-Rsync.app/Contents/Resources/
cp index.html JG-Rsync.app/Contents/Resources/
cp -R src JG-Rsync.app/Contents/Resources/
cp -R node_modules JG-Rsync.app/Contents/Resources/ 2>/dev/null || echo "⚠️  Warning: node_modules not found, will be created on first run"

# Set proper permissions
chmod -R 755 JG-Rsync.app

# Install to /Applications
echo "📦 Installing to /Applications..."
sudo cp -R JG-Rsync.app /Applications/

# Set proper permissions
sudo chmod -R 755 /Applications/JG-Rsync.app

echo "✅ JG-Rsync successfully installed to /Applications!"
echo ""
echo "🎉 You can now launch JG-Rsync from:"
echo "   • Launchpad"
echo "   • Applications folder in Finder"
echo "   • Spotlight search (Cmd+Space, then type 'JG-Rsync')"
echo ""
echo "🔄 To update the app in the future, run: ./update-app.sh"
echo ""
echo "✅ This .app bundle is completely self-contained!"
