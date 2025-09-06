#!/bin/bash

# Test script for JG-Rsync .app bundle

echo "🧪 Testing JG-Rsync .app bundle..."

# Test the launcher script directly
echo "Testing launcher script..."
/Applications/JG-Rsync.app/Contents/MacOS/JG-Rsync &
APP_PID=$!

# Wait a few seconds
sleep 5

# Check if the app is running
if ps -p $APP_PID > /dev/null; then
    echo "✅ JG-Rsync is running (PID: $APP_PID)"
    echo "🎉 The app launched successfully!"
    
    # Show running processes
    echo "Running processes:"
    ps aux | grep -i "jg-rsync\|electron" | grep -v grep | head -3
else
    echo "❌ JG-Rsync failed to start"
    echo "Exit code: $?"
fi

# Clean up
echo "Cleaning up..."
pkill -f "JG-Rsync\|electron.*jg-rsync" || true
