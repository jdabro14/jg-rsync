#!/bin/bash

# JG-Rsync Cleanup Script
# Kills all running Electron, Vite, and concurrently processes

echo "🧹 Cleaning up JG-Rsync processes..."

# Kill all related processes
pkill -f "electron" 2>/dev/null
pkill -f "vite" 2>/dev/null  
pkill -f "concurrently" 2>/dev/null
pkill -f "wait-on" 2>/dev/null

# Wait a moment for processes to terminate
sleep 2

# Force kill any remaining processes
pkill -9 -f "electron" 2>/dev/null
pkill -9 -f "vite" 2>/dev/null
pkill -9 -f "concurrently" 2>/dev/null
pkill -9 -f "wait-on" 2>/dev/null

# Check if any processes are still running
REMAINING=$(ps aux | grep -E "(electron|vite|concurrently)" | grep -v grep | wc -l)

if [ "$REMAINING" -eq 0 ]; then
    echo "✅ All JG-Rsync processes cleaned up successfully"
else
    echo "⚠️  Some processes may still be running:"
    ps aux | grep -E "(electron|vite|concurrently)" | grep -v grep
fi

echo "🚀 Ready to start fresh!"
