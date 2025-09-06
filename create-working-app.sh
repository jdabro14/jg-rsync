#!/bin/bash

# Create a working macOS app bundle for JG-Rsync
# This script creates a proper self-contained .app bundle

set -e

echo "🚀 Creating working JG-Rsync macOS app bundle..."

# Clean up any existing app
rm -rf JG-Rsync.app

# Create app bundle structure
mkdir -p JG-Rsync.app/Contents/MacOS
mkdir -p JG-Rsync.app/Contents/Resources

# Build the project first
echo "📦 Building the project..."
npx tsc
npm run build:renderer

# Rebuild main.js after vite clears the dist directory
echo "🔧 Rebuilding main.js after vite build..."
npx tsc

# Create a production package.json with Electron in dependencies
echo "📝 Creating production package.json..."
cat > JG-Rsync.app/Contents/Resources/package.json << 'EOF'
{
  "name": "jg-rsync",
  "version": "1.0.0",
  "description": "A production-grade two-pane file transfer app for macOS",
  "main": "main.js",
  "homepage": "./",
  "scripts": {
    "start": "electron ."
  },
  "dependencies": {
    "electron": "^28.1.0",
    "autoprefixer": "^10.4.16",
    "lucide-react": "^0.294.0",
    "postcss": "^8.4.32",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "rxjs": "^7.8.1",
    "ssh2-sftp-client": "^10.0.3",
    "tailwindcss": "^3.4.0"
  }
}
EOF

# Copy all necessary files
echo "📋 Copying application files..."
cp dist/main.js JG-Rsync.app/Contents/Resources/
cp -r dist/renderer JG-Rsync.app/Contents/Resources/
cp index.html JG-Rsync.app/Contents/Resources/
cp tsconfig.json JG-Rsync.app/Contents/Resources/

# Fix: Copy CSS to renderer directory and update index.html
echo "🔧 Fixing production paths..."
cp src/index.css JG-Rsync.app/Contents/Resources/renderer/index.css

# Create and copy preload script
echo "🔧 Creating preload script..."
npx tsc src/preload/index.ts --outDir dist/preload --target es2020 --module commonjs --moduleResolution node
mkdir -p JG-Rsync.app/Contents/Resources/preload
cp dist/preload/index.js JG-Rsync.app/Contents/Resources/preload/index.js

# Update index.html with correct production paths
cat > JG-Rsync.app/Contents/Resources/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>JG-Rsync</title>
    <link rel="stylesheet" href="/renderer/index.css">
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/renderer/index.js"></script>
  </body>
</html>
EOF

# Install production dependencies
echo "📦 Installing production dependencies..."
cd JG-Rsync.app/Contents/Resources
npm install --production --silent
cd ../../../../

# Create the launcher script
echo "🔧 Creating launcher script..."
cat > JG-Rsync.app/Contents/MacOS/JG-Rsync << 'EOF'
#!/bin/bash

# JG-Rsync Working Electron Launcher
# This script launches the JG-Rsync file transfer application

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOURCES_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")/Contents/Resources"

# Change to the resources directory
cd "$RESOURCES_DIR"

# Check if we have the required files
if [ ! -f "main.js" ]; then
    echo "Error: main.js not found in $RESOURCES_DIR"
    osascript -e 'display dialog "Error: JG-Rsync application files not found. Please reinstall the application." buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi

if [ ! -f "node_modules/.bin/electron" ]; then
    echo "Error: Electron not found in node_modules"
    osascript -e 'display dialog "Error: Electron runtime not found. Please reinstall the application." buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi

# Launch the application using the local Electron
echo "Starting JG-Rsync with local Electron..."
exec ./node_modules/.bin/electron main.js
EOF

# Make the launcher executable
chmod +x JG-Rsync.app/Contents/MacOS/JG-Rsync

# Create Info.plist
echo "📄 Creating Info.plist..."
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
    <key>CFBundleIconFile</key>
    <string>icon.icns</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSRequiresAquaSystemAppearance</key>
    <false/>
</dict>
</plist>
EOF

# Create a better icon
echo "🎨 Creating application icon..."
python3 << 'EOF'
from PIL import Image, ImageDraw
import os

# Create a 512x512 icon with a professional look
size = 512
img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Background circle with gradient effect
center = size // 2
radius = 200

# Draw multiple circles for gradient effect
for i in range(radius, 0, -5):
    alpha = int(255 * (1 - i / radius) * 0.8)
    color = (52, 152, 219, alpha)  # Blue color
    draw.ellipse([center - i, center - i, center + i, center + i], fill=color)

# Draw sync arrows
arrow_size = 80
arrow_color = (255, 255, 255, 255)

# Left arrow
left_center = (center - 60, center)
draw.polygon([
    (left_center[0] - arrow_size//2, left_center[1]),
    (left_center[0] + arrow_size//2, left_center[1] - arrow_size//3),
    (left_center[0] + arrow_size//2, left_center[1] + arrow_size//3)
], fill=arrow_color)

# Right arrow
right_center = (center + 60, center)
draw.polygon([
    (right_center[0] + arrow_size//2, right_center[1]),
    (right_center[0] - arrow_size//2, right_center[1] - arrow_size//3),
    (right_center[0] - arrow_size//2, right_center[1] + arrow_size//3)
], fill=arrow_color)

# Save the icon
img.save('JG-Rsync.app/Contents/Resources/icon.png')

# Create .icns file using sips
os.system('sips -s format icns JG-Rsync.app/Contents/Resources/icon.png --out JG-Rsync.app/Contents/Resources/icon.icns')
EOF

# Set proper permissions
echo "🔐 Setting permissions..."
chmod -R 755 JG-Rsync.app

# Clear icon cache
echo "🧹 Clearing icon cache..."
killall Dock 2>/dev/null || true

echo "✅ JG-Rsync app bundle created successfully!"
echo "📱 App location: $(pwd)/JG-Rsync.app"
echo ""
echo "To install:"
echo "  sudo cp -r JG-Rsync.app /Applications/"
echo ""
echo "To test:"
echo "  open JG-Rsync.app"