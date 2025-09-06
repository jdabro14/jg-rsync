#!/bin/bash

# JG-Rsync Update Script
# This script helps manage app updates and releases

set -e

echo "🚀 JG-Rsync Update Manager"
echo "=========================="

# Function to build and package the app
build_app() {
    echo "📦 Building application..."
    npm run build
    
    echo "🔨 Creating macOS app bundle..."
    npx electron-builder --config.npmRebuild=false
    
    echo "✅ Build completed successfully!"
}

# Function to install the app
install_app() {
    echo "📱 Installing app to /Applications..."
    
    # Remove existing app
    if [ -d "/Applications/JG-Rsync.app" ]; then
        echo "🗑️  Removing existing app..."
        sudo rm -rf /Applications/JG-Rsync.app
    fi
    
    # Install new app
    echo "⬇️  Installing new version..."
    sudo cp -R dist-electron/mac-arm64/JG-Rsync.app /Applications/
    
    # Fix permissions
    echo "🔧 Fixing permissions..."
    sudo chown -R root:admin /Applications/JG-Rsync.app
    sudo chmod -R 755 /Applications/JG-Rsync.app
    
    echo "✅ App installed successfully!"
    echo "🎉 You can now launch JG-Rsync from /Applications/"
}

# Function to create a release
create_release() {
    echo "🏷️  Creating release..."
    
    # Get version from package.json
    VERSION=$(node -p "require('./package.json').version")
    
    echo "📋 Version: $VERSION"
    
    # Build the app
    build_app
    
    # Create DMG
    echo "💿 Creating DMG installer..."
    npx electron-builder --config.npmRebuild=false
    
    echo "✅ Release created: dist-electron/JG-Rsync-$VERSION.dmg"
    echo "📤 Ready for distribution!"
}

# Function to check for updates
check_updates() {
    echo "🔍 Checking for updates..."
    npx electron-builder --config.npmRebuild=false --publish=never
    echo "✅ Update check completed!"
}

# Main menu
case "${1:-help}" in
    "build")
        build_app
        ;;
    "install")
        build_app
        install_app
        ;;
    "release")
        create_release
        ;;
    "check")
        check_updates
        ;;
    "help"|*)
        echo "Usage: $0 {build|install|release|check|help}"
        echo ""
        echo "Commands:"
        echo "  build   - Build the application"
        echo "  install - Build and install to /Applications"
        echo "  release - Create a release package"
        echo "  check   - Check for updates"
        echo "  help    - Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0 build     # Just build the app"
        echo "  $0 install   # Build and install"
        echo "  $0 release   # Create release package"
        ;;
esac
