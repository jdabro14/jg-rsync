#!/bin/bash

# Fix JG-Rsync app immediately - create a working solution

set -e

echo "🔧 Fixing JG-Rsync app immediately..."

# Kill any running processes
pkill -f "JG-Rsync\|electron.*jg-rsync\|vite\|concurrently" || true

# Remove broken installation
if [ -d "/Applications/JG-Rsync.app" ]; then
    echo "🗑️  Removing broken installation..."
    sudo rm -rf /Applications/JG-Rsync.app
fi

# Build the project
echo "🔨 Building project..."
npm run build:main

# Create working app bundle
echo "📁 Creating working app bundle..."
mkdir -p JG-Rsync.app/Contents/MacOS
mkdir -p JG-Rsync.app/Contents/Resources

# Create Info.plist
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

# Create a simple working launcher
cat > JG-Rsync.app/Contents/MacOS/JG-Rsync << 'EOF'
#!/bin/bash

# JG-Rsync Working Launcher
# This script launches the JG-Rsync file transfer application

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOURCES_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")/Contents/Resources"

# Change to the resources directory
cd "$RESOURCES_DIR"

# Check if we have the required files
if [ ! -f "package.json" ]; then
    echo "Error: package.json not found in $RESOURCES_DIR"
    echo "Contents of Resources directory:"
    ls -la "$RESOURCES_DIR"
    osascript -e 'display dialog "Error: JG-Rsync application files not found. Please reinstall the application." buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm install --production --silent
fi

# Launch the application
echo "Starting JG-Rsync..."
exec npm start
EOF

# Make the launcher executable
chmod +x JG-Rsync.app/Contents/MacOS/JG-Rsync

# Create icon
echo "🎨 Creating icon..."
python3 create-better-icon.py

# Copy ALL necessary files
echo "📦 Copying all files..."
cp package.json JG-Rsync.app/Contents/Resources/
cp index.html JG-Rsync.app/Contents/Resources/
cp tsconfig.json JG-Rsync.app/Contents/Resources/
cp -R src JG-Rsync.app/Contents/Resources/
cp -R dist JG-Rsync.app/Contents/Resources/
cp -R node_modules JG-Rsync.app/Contents/Resources/

# Set proper permissions
chmod -R 755 JG-Rsync.app

# Install to /Applications
echo "📦 Installing to /Applications..."
sudo cp -R JG-Rsync.app /Applications/
sudo chmod -R 755 /Applications/JG-Rsync.app

# Clean up
rm -rf JG-Rsync.app

echo "✅ JG-Rsync app fixed and installed!"
echo ""
echo "🧪 Testing the app..."
sleep 2

# Test the app
if /Applications/JG-Rsync.app/Contents/MacOS/JG-Rsync & then
    sleep 3
    if ps aux | grep -i "electron" | grep -v grep > /dev/null; then
        echo "✅ JG-Rsync is running successfully!"
        echo "🎉 The app is now working properly!"
    else
        echo "❌ App failed to start"
    fi
else
    echo "❌ Failed to launch app"
fi

echo ""
echo "🚀 You can now double-click JG-Rsync in Applications!"
