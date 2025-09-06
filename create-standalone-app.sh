#!/bin/bash

# Create a completely standalone JG-Rsync .app bundle
# This version doesn't depend on external files

set -e

echo "🔨 Creating standalone JG-Rsync .app bundle..."

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
</dict>
</plist>
EOF

# Create a bash script launcher that directly runs the app
echo "🚀 Creating direct bash script launcher..."
cat > JG-Rsync.app/Contents/MacOS/JG-Rsync << 'EOF'
#!/bin/bash

# Get the absolute path to the Resources directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOURCES_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")/Resources"

# Debug information
echo "Script directory: $SCRIPT_DIR"
echo "Resources directory: $RESOURCES_DIR"

# Change to the Resources directory
cd "$RESOURCES_DIR" || {
    osascript -e 'display dialog "Error: Could not access application resources. Please reinstall the application." buttons {"OK"} default button "OK" with icon stop'
    exit 1
}

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    osascript -e 'display dialog "Node.js is required but not installed. Please install Node.js 18+ first." buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi

# Check if rsync is installed
if ! command -v rsync &> /dev/null; then
    osascript -e 'display dialog "rsync is required but not installed. Please install rsync first." buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi

# Set environment variables
export NODE_ENV=production

# Start the application directly
echo "🚀 Starting JG-Rsync in production mode..."

# Try different methods to start the app
if [ -f "$RESOURCES_DIR/electron/main.js" ]; then
    echo "Found electron/main.js, launching..."
    exec node "$RESOURCES_DIR/electron/main.js"
elif [ -f "$RESOURCES_DIR/dist/main/index.js" ]; then
    echo "Found dist/main/index.js, launching..."
    exec node "$RESOURCES_DIR/dist/main/index.js"
else
    osascript -e 'display dialog "Application entry point not found. Please reinstall the application." buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi
EOF

# Make the launcher executable
chmod +x JG-Rsync.app/Contents/MacOS/JG-Rsync

# Create custom icon
echo "🎨 Creating custom JG-Rsync icon..."
python3 create-simple-icon.py

# Copy all application files to Resources
echo "📦 Embedding application files..."
cp package.json JG-Rsync.app/Contents/Resources/
cp index.html JG-Rsync.app/Contents/Resources/
cp tsconfig.json JG-Rsync.app/Contents/Resources/
cp -R src JG-Rsync.app/Contents/Resources/
cp -R dist JG-Rsync.app/Contents/Resources/ 2>/dev/null || echo "⚠️  Warning: dist directory not found"

# Create electron directory and copy main.js
echo "📦 Creating electron directory and copying main.js..."
mkdir -p JG-Rsync.app/Contents/Resources/electron
cp electron/main.js JG-Rsync.app/Contents/Resources/electron/

# Copy node_modules or prepare for installation
cp -R node_modules JG-Rsync.app/Contents/Resources/ 2>/dev/null || echo "⚠️  Warning: node_modules not found, will be created on first run"

# Set proper permissions
chmod -R 755 JG-Rsync.app

echo "✅ Standalone JG-Rsync.app bundle created successfully!"
echo ""
echo "📋 Installation instructions:"
echo "1. Copy JG-Rsync.app to your /Applications folder:"
echo "   sudo cp -R JG-Rsync.app /Applications/"
echo ""
echo "2. Or drag and drop JG-Rsync.app to your Applications folder in Finder"
echo ""
echo "3. Launch JG-Rsync from Launchpad or Applications folder"
echo ""
echo "✅ This .app bundle is completely self-contained and doesn't depend on external files!"
