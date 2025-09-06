#!/bin/bash

# Fix JG-Rsync app to launch properly when double-clicked
set -e

echo "🔧 Creating a properly double-clickable JG-Rsync app..."

# Kill any running processes
pkill -f "JG-Rsync\|electron.*jg-rsync" || true

# Remove existing installation
if [ -d "/Applications/JG-Rsync.app" ]; then
    echo "🗑️  Removing existing installation..."
    sudo rm -rf /Applications/JG-Rsync.app
fi

# Create app bundle structure
echo "📁 Creating app bundle structure..."
mkdir -p JG-Rsync.app/Contents/{MacOS,Resources}

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
    <key>NSAppleScriptEnabled</key>
    <true/>
</dict>
</plist>
EOF

# Create AppleScript launcher
echo "🚀 Creating AppleScript launcher..."
cat > JG-Rsync.app/Contents/MacOS/JG-Rsync << 'EOF'
#!/usr/bin/osascript

on run
    -- Get the path to the app bundle
    set appPath to POSIX path of ((path to me as text) & "::")
    
    -- Log the app path for debugging
    log "App path: " & appPath
    
    -- Set the resources path
    set resourcesPath to appPath & "Contents/Resources"
    log "Resources path: " & resourcesPath
    
    -- Change to the resources directory and run electron
    try
        -- First, check if the resources directory exists
        do shell script "if [ ! -d \"" & resourcesPath & "\" ]; then exit 1; fi"
        
        -- Check if electron is available
        set electronPath to resourcesPath & "/node_modules/.bin/electron"
        set hasElectron to false
        
        try
            do shell script "if [ -f \"" & electronPath & "\" ]; then exit 0; else exit 1; fi"
            set hasElectron to true
        on error
            set hasElectron to false
        end try
        
        -- Run the app
        if hasElectron then
            log "Using bundled electron"
            do shell script "cd \"" & resourcesPath & "\" && \"" & electronPath & "\" ."
        else
            log "Using npm start"
            do shell script "cd \"" & resourcesPath & "\" && npm start"
        end if
    on error errMsg
        display dialog "Error launching JG-Rsync: " & errMsg buttons {"OK"} default button "OK" with icon stop
        log "Error: " & errMsg
    end try
end run
EOF

# Make the launcher executable
chmod +x JG-Rsync.app/Contents/MacOS/JG-Rsync

# Create icon
echo "🎨 Creating icon..."
python3 create-better-icon.py

# Copy application files
echo "📦 Copying application files..."
cp package.json JG-Rsync.app/Contents/Resources/
cp index.html JG-Rsync.app/Contents/Resources/
cp -R electron JG-Rsync.app/Contents/Resources/
cp -R src JG-Rsync.app/Contents/Resources/
cp -R dist JG-Rsync.app/Contents/Resources/

# Install electron locally in the app bundle
echo "📦 Installing electron in the app bundle..."
mkdir -p JG-Rsync.app/Contents/Resources/node_modules
npm install --prefix JG-Rsync.app/Contents/Resources electron --save-dev

# Copy other node modules
echo "📦 Copying node modules..."
cp -R node_modules JG-Rsync.app/Contents/Resources/

# Set proper permissions
echo "🔒 Setting proper permissions..."
chmod -R 755 JG-Rsync.app

# Install to /Applications
echo "📦 Installing to /Applications..."
sudo cp -R JG-Rsync.app /Applications/
sudo chmod -R 755 /Applications/JG-Rsync.app

# Clean up
rm -rf JG-Rsync.app

echo "✅ JG-Rsync app fixed and installed!"
echo ""
echo "🚀 You can now double-click JG-Rsync in Applications!"
