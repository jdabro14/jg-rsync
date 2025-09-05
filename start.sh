#!/bin/bash

# TwinSync Startup Script
echo "🚀 Starting TwinSync Development Environment..."

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18+ first."
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "❌ npm is not installed. Please install npm first."
    exit 1
fi

# Check if rsync is installed
if ! command -v rsync &> /dev/null; then
    echo "⚠️  rsync is not installed. Installing via Homebrew..."
    if command -v brew &> /dev/null; then
        brew install rsync
    else
        echo "❌ Homebrew is not installed. Please install rsync manually:"
        echo "   brew install rsync"
        exit 1
    fi
fi

# Check if dependencies are installed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
    if [ $? -ne 0 ]; then
        echo "❌ Failed to install dependencies"
        exit 1
    fi
fi

# Always build TypeScript to ensure latest changes
echo "🔨 Building TypeScript..."
npm run build:main
if [ $? -ne 0 ]; then
    echo "❌ Failed to build TypeScript"
    exit 1
fi

# Set environment variables
export NODE_ENV=development

# Start the development environment
echo "🎯 Starting TwinSync in development mode..."
echo "   - Vite dev server will start on http://localhost:5173"
echo "   - Electron will launch the app"
echo "   - Press Ctrl+C to stop"
echo ""

# Start the development environment
npm run electron:dev
