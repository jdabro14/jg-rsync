#!/bin/bash

# Create a production-ready JG-Rsync .app bundle
# This version includes pre-built files and doesn't require development tools

set -e

echo "🚀 Creating production-ready JG-Rsync .app bundle..."

# Build the project first
echo "🔨 Building the project..."
npm run build:main

# Remove existing installation
if [ -d "/Applications/JG-Rsync.app" ]; then
    echo "🗑️  Removing existing installation..."
    sudo rm -rf /Applications/JG-Rsync.app
fi

# Create the app bundle structure
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

# Create a production launcher that uses the built files
cat > JG-Rsync.app/Contents/MacOS/JG-Rsync << 'EOF'
#!/bin/bash

# JG-Rsync Production macOS Application Launcher
# This script launches the JG-Rsync file transfer application

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOURCES_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")/Contents/Resources"

# Change to the resources directory
cd "$RESOURCES_DIR"

# Check if we have the required files
if [ ! -f "package.json" ]; then
    echo "Error: package.json not found in $RESOURCES_DIR"
    osascript -e 'display dialog "Error: JG-Rsync application files not found. Please reinstall the application." buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm install --production
fi

# Launch the application using the built files
echo "Starting JG-Rsync..."
exec npm start
EOF

# Make the launcher executable
chmod +x JG-Rsync.app/Contents/MacOS/JG-Rsync

# Create custom icon
python3 create-simple-icon.py

# Copy all necessary files to Resources
echo "📦 Embedding application files..."
cp package.json JG-Rsync.app/Contents/Resources/
cp index.html JG-Rsync.app/Contents/Resources/
cp tsconfig.json JG-Rsync.app/Contents/Resources/
cp -R src JG-Rsync.app/Contents/Resources/
cp -R dist JG-Rsync.app/Contents/Resources/

# Copy node_modules (production only)
if [ -d "node_modules" ]; then
    echo "📦 Copying production dependencies..."
    cp -R node_modules JG-Rsync.app/Contents/Resources/
fi

# Set proper permissions
chmod -R 755 JG-Rsync.app

# Install to /Applications
echo "📦 Installing to /Applications..."
sudo cp -R JG-Rsync.app /Applications/
sudo chmod -R 755 /Applications/JG-Rsync.app

echo "✅ Production JG-Rsync successfully installed!"
echo ""
echo "🎉 You can now launch JG-Rsync from:"
echo "   • Applications folder in Finder"
echo "   • Launchpad"
echo "   • Spotlight search (Cmd+Space, then type 'JG-Rsync')"
echo ""
echo "✅ This .app bundle is production-ready and self-contained!"
