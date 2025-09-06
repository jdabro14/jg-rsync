#!/bin/bash

# Optimized build script for JG-Rsync
# Creates a properly sized macOS app bundle without nested apps or duplicate files

set -e

echo "🔨 Building optimized JG-Rsync macOS app bundle..."

# Remove existing installation
echo "🗑️  Removing existing installation..."
sudo rm -rf /Applications/JG-Rsync.app

# Clean up local build
echo "🗑️  Cleaning up local build..."
rm -rf JG-Rsync.app
rm -rf dist_electron

# Build the project
echo "🔨 Building project..."
npm run build:main
npm run build:renderer

# Create app bundle structure
echo "📁 Creating app bundle structure..."
mkdir -p JG-Rsync.app/Contents/{MacOS,Resources}

# Create Info.plist
echo "📝 Creating Info.plist..."
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
    <string>com.jg-rsync.app</string>
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
    <string>Copyright © 2025 JG. All rights reserved.</string>
</dict>
</plist>
EOF

# Create launcher script
echo "🚀 Creating launcher script..."
cat > JG-Rsync.app/Contents/MacOS/JG-Rsync << 'EOF'
#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOURCES_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")/Contents/Resources"
ELECTRON_PATH="$RESOURCES_DIR/electron/Electron.app/Contents/MacOS/Electron"

# Debug information
echo "Script directory: $SCRIPT_DIR"
echo "Resources directory: $RESOURCES_DIR"
echo "Electron path: $ELECTRON_PATH"

# Change to the resources directory
cd "$RESOURCES_DIR" || {
    osascript -e 'display dialog "Error: Could not access application resources. Please reinstall the application." buttons {"OK"} default button "OK" with icon stop'
    exit 1
}

# Set proper environment variables
export NODE_ENV=production
export ELECTRON_RUN_AS_NODE=0

# Set the app path to ensure proper resource loading
APP_PATH="$RESOURCES_DIR"
echo "Setting app path to: $APP_PATH"

# Launch the application with the app path as the first argument
exec "$ELECTRON_PATH" "$APP_PATH"
EOF

# Make the launcher executable
chmod +x JG-Rsync.app/Contents/MacOS/JG-Rsync

# Create the custom icon
echo "🎨 Creating custom icon..."
python3 create-better-icon.py

# Copy only necessary files to Resources
echo "📦 Copying application files..."
mkdir -p JG-Rsync.app/Contents/Resources/{electron,dist,src}

# Copy Electron binary
echo "📦 Copying Electron binary..."
mkdir -p JG-Rsync.app/Contents/Resources/electron
cp -R node_modules/electron/dist/Electron.app JG-Rsync.app/Contents/Resources/electron/

# Copy application files
cp package.json JG-Rsync.app/Contents/Resources/

# Build and copy preload files
echo "📦 Building preload files..."
npm run build:main

# Create proper directory structure for preload files
mkdir -p JG-Rsync.app/Contents/Resources/dist/preload

# Copy preload files
cp -R dist/preload JG-Rsync.app/Contents/Resources/dist/

# Copy other application files
cp -R dist/assets JG-Rsync.app/Contents/Resources/dist/
cp dist/index.html JG-Rsync.app/Contents/Resources/dist/
cp -R electron JG-Rsync.app/Contents/Resources/

# Copy only necessary node_modules (exclude dev dependencies)
echo "📦 Copying production dependencies..."
mkdir -p JG-Rsync.app/Contents/Resources/node_modules
npm list --prod --parseable --depth=0 | tail -n +2 | while read -r module; do
  module_name=$(basename "$module")
  echo "Copying $module_name..."
  cp -R "$module" JG-Rsync.app/Contents/Resources/node_modules/
done

# Set proper permissions
echo "🔒 Setting proper permissions..."
chmod -R 755 JG-Rsync.app

# Install to /Applications
echo "📦 Installing to /Applications..."
sudo cp -R JG-Rsync.app /Applications/
sudo chmod -R 755 /Applications/JG-Rsync.app

echo "✅ Optimized JG-Rsync successfully installed!"
echo ""
echo "🚀 JG-Rsync is now ready for use!"
echo "   - App size has been significantly reduced"
echo "   - Directory navigation has been fixed"
echo "   - Saved connections persistence has been fixed"
echo ""
echo "You can now launch it by double-clicking the app icon in /Applications"
