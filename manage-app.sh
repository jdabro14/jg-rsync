#!/bin/bash

# JG-Rsync Application Management Script
# This script provides easy management of the JG-Rsync .app bundle

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Function to show usage
show_usage() {
    echo "JG-Rsync Application Management"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  install    - Install/Reinstall JG-Rsync .app bundle"
    echo "  update     - Update the installed .app bundle with latest changes"
    echo "  test       - Test the installed .app bundle"
    echo "  uninstall  - Remove JG-Rsync from /Applications"
    echo "  status     - Check if JG-Rsync is installed and running"
    echo "  fix        - Fix common issues with the .app bundle"
    echo "  help       - Show this help message"
    echo ""
}

# Function to install the app
install_app() {
    print_info "Installing JG-Rsync .app bundle..."
    
    # Remove existing installation
    if [ -d "/Applications/JG-Rsync.app" ]; then
        print_warning "Removing existing installation..."
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

    # Create the launcher script
    cat > JG-Rsync.app/Contents/MacOS/JG-Rsync << 'EOF'
#!/bin/bash

# JG-Rsync macOS Application Launcher
# This script launches the JG-Rsync file transfer application

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOURCES_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")/Contents/Resources"

# Change to the resources directory
cd "$RESOURCES_DIR"

# Check if we have the required files
if [ ! -f "start.sh" ]; then
    echo "Error: start.sh not found in $RESOURCES_DIR"
    osascript -e 'display dialog "Error: JG-Rsync application files not found. Please reinstall the application." buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi

# Make start.sh executable
chmod +x start.sh

# Launch the application
exec ./start.sh
EOF

    # Make the launcher executable
    chmod +x JG-Rsync.app/Contents/MacOS/JG-Rsync

    # Create custom icon
    python3 create-simple-icon.py

    # Copy all application files to Resources
    cp start.sh JG-Rsync.app/Contents/Resources/
    cp package.json JG-Rsync.app/Contents/Resources/
    cp index.html JG-Rsync.app/Contents/Resources/
    cp -R src JG-Rsync.app/Contents/Resources/
    cp -R node_modules JG-Rsync.app/Contents/Resources/ 2>/dev/null || print_warning "node_modules not found, will be created on first run"

    # Set proper permissions
    chmod -R 755 JG-Rsync.app

    # Install to /Applications
    sudo cp -R JG-Rsync.app /Applications/
    sudo chmod -R 755 /Applications/JG-Rsync.app

    print_status "JG-Rsync successfully installed to /Applications!"
}

# Function to update the app
update_app() {
    if [ ! -d "/Applications/JG-Rsync.app" ]; then
        print_error "JG-Rsync.app not found in /Applications"
        print_info "Run: $0 install"
        exit 1
    fi

    print_info "Updating JG-Rsync .app bundle..."
    
    # Create a backup
    sudo cp -R /Applications/JG-Rsync.app /Applications/JG-Rsync.app.backup
    print_info "Backup created at /Applications/JG-Rsync.app.backup"

    # Update the .app bundle
    sudo cp -R src /Applications/JG-Rsync.app/Contents/Resources/
    sudo cp package.json /Applications/JG-Rsync.app/Contents/Resources/
    sudo cp index.html /Applications/JG-Rsync.app/Contents/Resources/
    sudo cp start.sh /Applications/JG-Rsync.app/Contents/Resources/

    # Update node_modules if it exists
    if [ -d "node_modules" ]; then
        print_info "Updating node_modules..."
        sudo rm -rf /Applications/JG-Rsync.app/Contents/Resources/node_modules
        sudo cp -R node_modules /Applications/JG-Rsync.app/Contents/Resources/
    fi

    # Set proper permissions
    sudo chmod -R 755 /Applications/JG-Rsync.app

    print_status "JG-Rsync updated successfully!"
}

# Function to test the app
test_app() {
    if [ ! -d "/Applications/JG-Rsync.app" ]; then
        print_error "JG-Rsync.app not found in /Applications"
        print_info "Run: $0 install"
        exit 1
    fi

    print_info "Testing JG-Rsync .app bundle..."
    
    # Test the launcher script directly
    /Applications/JG-Rsync.app/Contents/MacOS/JG-Rsync &
    APP_PID=$!

    # Wait a few seconds
    sleep 5

    # Check if the app is running
    if ps -p $APP_PID > /dev/null; then
        print_status "JG-Rsync is running (PID: $APP_PID)"
        print_status "The app launched successfully!"
    else
        print_error "JG-Rsync failed to start"
    fi

    # Clean up
    pkill -f "JG-Rsync\|electron.*jg-rsync" || true
}

# Function to uninstall the app
uninstall_app() {
    if [ ! -d "/Applications/JG-Rsync.app" ]; then
        print_warning "JG-Rsync.app not found in /Applications"
        exit 0
    fi

    print_info "Uninstalling JG-Rsync..."
    sudo rm -rf /Applications/JG-Rsync.app
    print_status "JG-Rsync uninstalled successfully!"
}

# Function to check status
check_status() {
    if [ ! -d "/Applications/JG-Rsync.app" ]; then
        print_error "JG-Rsync is not installed"
        print_info "Run: $0 install"
        exit 1
    fi

    print_status "JG-Rsync is installed at /Applications/JG-Rsync.app"
    
    # Check if running
    if pgrep -f "JG-Rsync\|electron.*jg-rsync" > /dev/null; then
        print_status "JG-Rsync is currently running"
        ps aux | grep -i "jg-rsync\|electron" | grep -v grep | head -3
    else
        print_info "JG-Rsync is not currently running"
    fi
}

# Function to fix common issues
fix_app() {
    if [ ! -d "/Applications/JG-Rsync.app" ]; then
        print_error "JG-Rsync.app not found in /Applications"
        print_info "Run: $0 install"
        exit 1
    fi

    print_info "Fixing common issues..."
    
    # Fix permissions
    sudo chmod -R 755 /Applications/JG-Rsync.app
    
    # Fix launcher script if needed
    if ! grep -q "Contents/Resources" /Applications/JG-Rsync.app/Contents/MacOS/JG-Rsync; then
        print_info "Fixing launcher script path..."
        cat > /tmp/fixed-launcher.sh << 'EOF'
#!/bin/bash

# JG-Rsync macOS Application Launcher
# This script launches the JG-Rsync file transfer application

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOURCES_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")/Contents/Resources"

# Change to the resources directory
cd "$RESOURCES_DIR"

# Check if we have the required files
if [ ! -f "start.sh" ]; then
    echo "Error: start.sh not found in $RESOURCES_DIR"
    osascript -e 'display dialog "Error: JG-Rsync application files not found. Please reinstall the application." buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi

# Make start.sh executable
chmod +x start.sh

# Launch the application
exec ./start.sh
EOF
        sudo cp /tmp/fixed-launcher.sh /Applications/JG-Rsync.app/Contents/MacOS/JG-Rsync
        sudo chmod +x /Applications/JG-Rsync.app/Contents/MacOS/JG-Rsync
        rm /tmp/fixed-launcher.sh
    fi

    print_status "Common issues fixed!"
}

# Main script logic
case "${1:-help}" in
    install)
        install_app
        ;;
    update)
        update_app
        ;;
    test)
        test_app
        ;;
    uninstall)
        uninstall_app
        ;;
    status)
        check_status
        ;;
    fix)
        fix_app
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        print_error "Unknown command: $1"
        show_usage
        exit 1
        ;;
esac
