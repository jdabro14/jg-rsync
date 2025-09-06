#!/bin/bash

# Create Final Production-Ready JG-Rsync .app Bundle
# This creates a completely self-contained application

set -e

echo " Creating Final Production-Ready JG-Rsync .app Bundle..."

# Remove existing installation
echo "  Removing existing installation..."
sudo rm -rf /Applications/JG-Rsync.app

# Clean up local build
echo "  Cleaning up local build..."
rm -rf JG-Rsync.app

# Build the project
echo " Building project..."
npm run build:main

# Create app bundle structure
echo " Creating app bundle structure..."
mkdir -p JG-Rsync.app/Contents/{MacOS,Resources}

# Create Info.plist
echo " Creating Info.plist..."
cat > JG-Rsync.app/Contents/Info.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>JG-Rsync</string>
    <key>CFBundleIconFile</key>
    <string>icon.icns</string>
    <key>CFBundleIdentifier</key>
    <string>com.jg.rsync</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>JG-Rsync</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright 2025 JG. All rights reserved.</string>
</dict>
</plist>
EOF

# Download Electron binary
echo "📦 Downloading Electron binary..."
ELECTRON_VERSION="28.1.0"
ELECTRON_DIR="electron-v${ELECTRON_VERSION}-darwin-x64"
ELECTRON_ZIP="${ELECTRON_DIR}.zip"
ELECTRON_URL="https://github.com/electron/electron/releases/download/v${ELECTRON_VERSION}/${ELECTRON_ZIP}"

if [ ! -f "${ELECTRON_ZIP}" ]; then
    curl -L "${ELECTRON_URL}" -o "${ELECTRON_ZIP}"
fi

if [ ! -d "${ELECTRON_DIR}" ]; then
    echo "📦 Extracting Electron..."
    unzip -q "${ELECTRON_ZIP}"
fi

# Create a launcher script that uses the bundled Electron
echo "🚀 Creating production launcher..."
cat > JG-Rsync.app/Contents/MacOS/JG-Rsync << 'EOF'
#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOURCES_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")/Contents/Resources"
ELECTRON_APP="${RESOURCES_DIR}/Electron.app/Contents/MacOS/Electron"

# Debug information
echo "Script directory: $SCRIPT_DIR"
echo "Resources directory: $RESOURCES_DIR"
echo "Electron app path: $ELECTRON_APP"

# Check if we have the required files
if [ ! -f "${ELECTRON_APP}" ]; then
    osascript -e 'display dialog "Error: Electron binary not found. Please reinstall the application." buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi

if [ ! -f "${RESOURCES_DIR}/app/package.json" ]; then
    osascript -e 'display dialog "Error: Application files not found. Please reinstall the application." buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi

# Launch the application using the bundled Electron
export NODE_ENV=production
"${ELECTRON_APP}" "${RESOURCES_DIR}/app"
EOF

# Make the launcher executable
chmod +x JG-Rsync.app/Contents/MacOS/JG-Rsync

# Create the custom icon
echo " Creating custom icon..."
python3 create-better-icon.py

# Copy Electron.app to Resources
echo "📦 Copying Electron.app to Resources..."
cp -R "${ELECTRON_DIR}/Electron.app" JG-Rsync.app/Contents/Resources/

# Create app directory structure
echo "📁 Creating app directory structure..."
mkdir -p JG-Rsync.app/Contents/Resources/app

# Copy all necessary files to app directory
echo "📦 Embedding application files..."
cp package.json JG-Rsync.app/Contents/Resources/app/
cp index.html JG-Rsync.app/Contents/Resources/app/
cp tsconfig.json JG-Rsync.app/Contents/Resources/app/
cp -R src JG-Rsync.app/Contents/Resources/app/
cp -R dist JG-Rsync.app/Contents/Resources/app/

# Copy electron directory with main.js
echo "📦 Copying electron directory..."
mkdir -p JG-Rsync.app/Contents/Resources/app/electron
cp electron/main.js JG-Rsync.app/Contents/Resources/app/electron/

# Install production dependencies in app directory
echo "📦 Installing production dependencies..."
cd JG-Rsync.app/Contents/Resources/app
npm install --production
cd ../../../..

# Set proper permissions
chmod -R 755 JG-Rsync.app

# Install to /Applications
echo " Installing to /Applications..."
sudo cp -R JG-Rsync.app /Applications/
sudo chmod -R 755 /Applications/JG-Rsync.app

echo " Final Production JG-Rsync successfully installed!"

echo "
 JG-Rsync is now ready for production use!

 Features:
   Self-contained .app bundle
   Custom professional icon
   Simple launcher script
   Production-ready
   No external dependencies

 Launch from:
   • Applications folder in Finder
   • Launchpad
   • Spotlight search (Cmd+Space, then type 'JG-Rsync')

 To update in the future:
   • Edit your code
   • Run: ./quick-update.sh

 This is a complete, production-ready application!"
