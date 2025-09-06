#!/bin/bash

# JG-Rsync Startup Script
# Clean, lightweight three-pane file transfer application for macOS

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

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    print_error "Node.js is required but not installed. Please install Node.js 18+ first."
    exit 1
fi

# Check if rsync is installed
if ! command -v rsync &> /dev/null; then
    print_error "rsync is required but not installed. Please install rsync first."
    print_info "Install with: brew install rsync"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    print_error "package.json not found. Please run this script from the project root directory."
    exit 1
fi

# Determine mode
MODE=${1:-"production"}

case "$MODE" in
    "dev"|"development")
        print_info "Starting JG-Rsync in development mode..."
        print_info "This will start Vite dev server and Electron with hot reload"
        
        # Check if dependencies are installed
        if [ ! -d "node_modules" ]; then
            print_info "Installing dependencies..."
            npm install
        fi
        
        # Build TypeScript first
        print_info "Building TypeScript..."
        npm run build:main
        
        # Start development mode
        print_info "Starting development server..."
        npm run dev
        ;;
        
    "prod"|"production")
        print_info "Starting JG-Rsync in production mode..."
        
        # Check if dependencies are installed
        if [ ! -d "node_modules" ]; then
            print_info "Installing dependencies..."
            npm install --production
        fi
        
        # Check if build exists
        if [ ! -d "dist" ] || [ ! -f "dist/main/index.js" ]; then
            print_info "Building application..."
            npm run build
        fi
        
        # Start production mode
        print_info "Starting production application..."
        NODE_ENV=production npm start
        ;;
        
    "build")
        print_info "Building JG-Rsync for production..."
        
        # Check if dependencies are installed
        if [ ! -d "node_modules" ]; then
            print_info "Installing dependencies..."
            npm install
        fi
        
        # Build the application
        print_info "Building TypeScript and Vite assets..."
        npm run build
        
        print_status "Build completed successfully!"
        print_info "You can now run: ./start.sh production"
        ;;
        
    "dist"|"package")
        print_info "Packaging JG-Rsync as macOS DMG..."
        
        # Check if dependencies are installed
        if [ ! -d "node_modules" ]; then
            print_info "Installing dependencies..."
            npm install
        fi
        
        # Build and package
        print_info "Building and packaging application..."
        npm run dist
        
        print_status "DMG package created successfully!"
        print_info "Check the dist-electron directory for the DMG file."
        ;;
        
    "help"|"--help"|"-h")
        echo "JG-Rsync Startup Script"
        echo ""
        echo "Usage: $0 [mode]"
        echo ""
        echo "Modes:"
        echo "  dev, development  - Start in development mode with hot reload"
        echo "  prod, production  - Start in production mode"
        echo "  build            - Build the application for production"
        echo "  dist, package    - Create macOS DMG package"
        echo "  help             - Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0 dev           # Start development mode"
        echo "  $0 production    # Start production mode"
        echo "  $0 build         # Build for production"
        echo "  $0 dist          # Create DMG package"
        ;;
        
    *)
        print_error "Unknown mode: $MODE"
        print_info "Run '$0 help' for usage information"
        exit 1
        ;;
esac
