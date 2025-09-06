#!/bin/bash

# Professional JG-Rsync macOS Application Builder
# Creates a proper macOS application bundle for JG-Rsync

set -e

# Configuration
APP_NAME="JG-Rsync"
APP_VERSION="1.0.0"
APP_IDENTIFIER="com.jg-rsync.app"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
DIST_DIR="$PROJECT_DIR/dist"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
ICON_PATH="$PROJECT_DIR/assets/icon.icns"

echo "🔨 Building $APP_NAME $APP_VERSION..."

# Clean up previous builds
echo "🧹 Cleaning up previous builds..."
rm -rf "$BUILD_DIR" "$APP_BUNDLE"
mkdir -p "$BUILD_DIR"

# Build the application
echo "📦 Building application..."
npm run build:main
npm run build:renderer

# Create app bundle structure
echo "📁 Creating app bundle structure..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Create Info.plist
echo "📝 Creating Info.plist..."
cat > "$APP_BUNDLE/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$APP_IDENTIFIER</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleVersion</key>
    <string>$APP_VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$APP_VERSION</string>
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
</dict>
</plist>
EOF

# Create launcher script
echo "🚀 Creating launcher script..."
cat > "$APP_BUNDLE/Contents/MacOS/$APP_NAME" << EOF
#!/bin/bash

# $APP_NAME macOS Application Launcher

# Get the directory where this script is located
SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
RESOURCES_DIR="\$(dirname "\$(dirname "\$SCRIPT_DIR")")/Contents/Resources"

# Change to the resources directory
cd "\$RESOURCES_DIR"

# Check if we have the required files
if [ ! -f "package.json" ]; then
    echo "Error: package.json not found in \$RESOURCES_DIR"
    osascript -e 'display dialog "Error: $APP_NAME application files not found. Please reinstall the application." buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi

# Launch the application
echo "Starting $APP_NAME..."
NODE_ENV=production ./node_modules/.bin/electron .
EOF

# Make launcher executable
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Copy icon
echo "🎨 Copying application icon..."
if [ -f "$ICON_PATH" ]; then
    cp "$ICON_PATH" "$APP_BUNDLE/Contents/Resources/icon.icns"
else
    echo "⚠️  Icon not found at $ICON_PATH, using default icon..."
    # Create a simple icon using system resources
    cp "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericApplicationIcon.icns" "$APP_BUNDLE/Contents/Resources/icon.icns"
fi

# Copy application files
echo "📦 Copying application files..."
mkdir -p "$APP_BUNDLE/Contents/Resources/node_modules"

# Copy package.json and update it for production
cp "$PROJECT_DIR/package.json" "$APP_BUNDLE/Contents/Resources/"
cp "$PROJECT_DIR/package-lock.json" "$APP_BUNDLE/Contents/Resources/" 2>/dev/null || true

# Copy main process files
mkdir -p "$APP_BUNDLE/Contents/Resources/dist"
cp -R "$DIST_DIR"/* "$APP_BUNDLE/Contents/Resources/dist/"

# Copy electron main.js
mkdir -p "$APP_BUNDLE/Contents/Resources/electron"
cp "$PROJECT_DIR/electron/main.js" "$APP_BUNDLE/Contents/Resources/electron/"

# Install production dependencies
echo "📦 Installing production dependencies..."
cd "$APP_BUNDLE/Contents/Resources"
npm install --production --no-optional

echo "✅ $APP_NAME.app bundle created successfully at $APP_BUNDLE"

# Install to Applications folder
echo "📦 Installing to /Applications..."
if [ -d "/Applications/$APP_NAME.app" ]; then
    echo "🗑️  Removing existing installation..."
    sudo rm -rf "/Applications/$APP_NAME.app"
fi

sudo cp -R "$APP_BUNDLE" "/Applications/"
sudo chmod -R 755 "/Applications/$APP_NAME.app"
sudo chown -R root:wheel "/Applications/$APP_NAME.app"

echo "✅ $APP_NAME has been installed to /Applications"
echo "🚀 You can now launch $APP_NAME from the Applications folder or Launchpad"
