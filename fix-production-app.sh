#!/bin/bash

# JG-Rsync Production App Fix Script
# This script fixes common production app issues and ensures proper file paths

set -e

echo "🔧 Fixing JG-Rsync Production App..."

# Check if app exists
if [ ! -d "/Applications/JG-Rsync.app" ]; then
    echo "❌ Error: JG-Rsync.app not found in /Applications"
    exit 1
fi

APP_DIR="/Applications/JG-Rsync.app/Contents/Resources"
RENDERER_DIR="$APP_DIR/renderer"

echo "📁 App directory: $APP_DIR"
echo "📁 Renderer directory: $RENDERER_DIR"

# Fix 1: Use Vite-built files for proper alignment
echo "🔧 Using Vite-built files for proper alignment..."
if [ -f "dist/index.html" ]; then
    sudo cp dist/index.html "$APP_DIR/index.html"
    sudo cp -r dist/assets "$APP_DIR/"
    echo "✅ Vite-built files copied"
else
    echo "⚠️  Warning: dist/index.html not found, run 'npm run build:renderer' first"
fi

# Fix 2: Ensure CSS file is in renderer directory
echo "🔧 Copying CSS file to renderer directory..."
if [ -f "src/index.css" ]; then
    sudo cp src/index.css "$RENDERER_DIR/index.css"
    echo "✅ CSS file copied"
else
    echo "⚠️  Warning: src/index.css not found, skipping CSS copy"
fi

# Fix 2.5: Create and copy preload script
echo "🔧 Creating preload script..."
if [ -f "src/preload/index.ts" ]; then
    # Compile preload script
    npx tsc src/preload/index.ts --outDir dist/preload --target es2020 --module commonjs --moduleResolution node
    
    # Create preload directory
    sudo mkdir -p "$APP_DIR/preload"
    
    # Copy preload script
    sudo cp dist/preload/index.js "$APP_DIR/preload/index.js"
    echo "✅ Preload script created and copied"
else
    echo "⚠️  Warning: src/preload/index.ts not found, skipping preload script"
fi

# Fix 3: Verify all required files exist
echo "🔍 Verifying required files..."
REQUIRED_FILES=(
    "$APP_DIR/index.html"
    "$APP_DIR/main.js"
    "$RENDERER_DIR/index.js"
    "$RENDERER_DIR/SimpleApp.js"
    "$RENDERER_DIR/index.css"
    "$APP_DIR/preload/index.js"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ Missing: $file"
        exit 1
    fi
done

# Fix 4: Set proper permissions
echo "🔧 Setting proper permissions..."
sudo chmod -R 755 "$APP_DIR"
sudo chown -R root:admin "$APP_DIR"

# Fix 5: Clear icon cache (macOS specific)
echo "🔧 Clearing macOS icon cache..."
sudo killall Dock 2>/dev/null || true
sudo killall Finder 2>/dev/null || true

echo "✅ Production app fix completed!"
echo ""
echo "🚀 You can now launch the app by:"
echo "   1. Double-clicking JG-Rsync in /Applications"
echo "   2. Or running: open /Applications/JG-Rsync.app"
echo ""
echo "🔍 To verify the app is working:"
echo "   ps aux | grep -i 'jg-rsync\\|electron.*main.js' | grep -v grep"
