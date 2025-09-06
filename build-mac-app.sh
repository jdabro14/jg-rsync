#!/bin/bash

# Build macOS app bundle with electron-packager
echo "🔨 Building JG-Rsync macOS app bundle..."

# Build TypeScript and Vite
echo "📦 Building TypeScript and Vite..."
npm run build:main
npm run build:renderer

# Package the app with electron-packager
echo "📦 Packaging app with electron-packager..."
npx electron-packager . "JG-Rsync" \
  --platform=darwin \
  --arch=x64 \
  --icon=assets/icon.icns \
  --overwrite \
  --app-bundle-id=com.jg-rsync.app \
  --app-version=1.0.0 \
  --build-version=1.0.0 \
  --darwin-dark-mode-support \
  --extend-info=assets/entitlements.mac.plist \
  --ignore="node_modules/(.cache|.bin)" \
  --out=dist_electron

# Copy the app to /Applications
echo "📦 Installing to /Applications..."
sudo cp -R "dist_electron/JG-Rsync-darwin-x64/JG-Rsync.app" /Applications/

echo "✅ JG-Rsync.app has been built and installed to /Applications"
echo "🚀 You can now launch it by double-clicking the app icon in /Applications"
