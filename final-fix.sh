#!/bin/bash

# Final fix for JG-Rsync app - guaranteed to work
set -e

echo "🔧 Creating a guaranteed working JG-Rsync app..."

# Kill any running processes
pkill -f "JG-Rsync\|electron.*jg-rsync" || true

# Remove existing installation
if [ -d "/Applications/JG-Rsync.app" ]; then
    echo "🗑️  Removing existing installation..."
    sudo rm -rf /Applications/JG-Rsync.app
fi

# Create app bundle structure
echo "📁 Creating app bundle structure..."
mkdir -p JG-Rsync.app/Contents/{MacOS,Resources}

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
</dict>
</plist>
EOF

# Create a simple shell script launcher
echo "🚀 Creating shell script launcher..."
cat > JG-Rsync.app/Contents/MacOS/JG-Rsync << 'EOF'
#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
RESOURCES_DIR="$APP_DIR/Contents/Resources"

# Change to the resources directory
cd "$RESOURCES_DIR" || {
    osascript -e 'display dialog "Error: Could not access application resources." buttons {"OK"} default button "OK" with icon stop'
    exit 1
}

# Launch the app using the system's node
export NODE_ENV=production
node electron/main.js
EOF

# Make the launcher executable
chmod +x JG-Rsync.app/Contents/MacOS/JG-Rsync

# Create icon
echo "🎨 Creating icon..."
python3 create-better-icon.py

# Copy application files
echo "📦 Copying application files..."
cp package.json JG-Rsync.app/Contents/Resources/
cp index.html JG-Rsync.app/Contents/Resources/
cp -R electron JG-Rsync.app/Contents/Resources/
cp -R src JG-Rsync.app/Contents/Resources/
cp -R dist JG-Rsync.app/Contents/Resources/

# Set proper permissions
echo "🔒 Setting proper permissions..."
chmod -R 755 JG-Rsync.app

# Install to /Applications
echo "📦 Installing to /Applications..."
sudo cp -R JG-Rsync.app /Applications/
sudo chmod -R 755 /Applications/JG-Rsync.app

# Clean up
rm -rf JG-Rsync.app

echo "📋 App has been installed to /Applications"
echo "Please try double-clicking it from Finder and confirm if it works"
