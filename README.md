# JG-Rsync

A lightweight, production-grade three-pane file transfer application for macOS built with Electron, React, and TypeScript.

## Features

- **Three-Pane Interface**: Connection management, local files, and remote files
- **SSH File Transfers**: Secure rsync-powered transfers over SSH
- **Connection Profiles**: Save and manage multiple SSH connections
- **Local File Operations**: Local-to-local file transfers
- **Modern UI**: Clean, responsive interface with Tailwind CSS
- **Security**: Context isolation and secure IPC communication

## Quick Start

### Development
```bash
npm run dev
```

### Production Build
```bash
npm run build
npm run dist
```

### Available Scripts
- `npm run dev` - Start development server with hot reload
- `npm run build` - Build for production
- `npm run dist` - Package as macOS DMG
- `npm test` - Run tests
- `npm run lint` - Run ESLint

## Requirements

- macOS 10.15 or later
- Node.js 18+
- rsync (install via Homebrew: `brew install rsync`)
- SSH key for remote connections

## Usage

1. **Connect**: Enter SSH connection details (host, user, key path)
2. **Browse**: Navigate local and remote directories
3. **Transfer**: Select files and use transfer buttons or drag & drop
4. **Profiles**: Save connection configurations for quick access

## Architecture

- **Main Process**: TypeScript-based Electron main process
- **Renderer**: React 18 with modern hooks and TypeScript
- **Styling**: Custom CSS with three-vertical-panes layout
- **File Operations**: Node.js fs.promises for local, rsync for transfers
- **Security**: Context isolation with preload script for IPC

## Development

The project uses a modern, lightweight architecture:
- Single TypeScript main process with no duplicate code
- Vite for fast development and optimized builds
- Electron Builder for macOS packaging
- Custom CSS with three-vertical-panes layout
- Comprehensive error handling and logging
- Clean, consolidated codebase with no duplicates

## License

MIT License