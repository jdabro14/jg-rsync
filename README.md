# TwinSync

A production-grade two-pane file transfer app for macOS that works like WinSCP. Features local and remote file browsing with rsync-powered transfers over SSH/SFTP.

## Features

- **Two-Pane Interface**: Left pane shows local filesystem, right pane shows remote files over SSH/SFTP
- **Rsync Transfers**: All file transfers use rsync over SSH for reliability and speed
- **Connection Profiles**: Save and manage multiple connection profiles
- **Drag & Drop**: Drag files between panes to initiate transfers
- **Progress Tracking**: Real-time transfer progress with speed and ETA
- **File Operations**: Create, delete, rename folders and files on both local and remote
- **Security**: Context isolation enabled, no node integration in renderer
- **Logging**: Comprehensive logging with export functionality

## Prerequisites

- macOS 10.15 or later
- Node.js 18+ and npm
- rsync (install via Homebrew: `brew install rsync`)
- SSH key for remote connections

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd twinsync
```

2. Install dependencies:
```bash
npm install
```

3. Build the project:
```bash
npm run build
```

4. Run in development mode:
```bash
npm run electron:dev
```

## Building for Production

1. Build the application:
```bash
npm run build
```

2. Package as DMG:
```bash
npm run dist
```

The DMG will be created in the `dist-electron` directory.

## Usage

### Connecting to a Remote Server

1. Click the "Connect" button in the connection bar
2. Fill in the connection details:
   - **User**: SSH username
   - **Host**: Server hostname or IP address
   - **Port**: SSH port (default: 22)
   - **Remote Path**: Initial remote directory
   - **SSH Key Path**: Path to your private SSH key
   - **Known Hosts**: Optional path to known_hosts file

3. Click "Connect" to establish the connection

### File Operations

- **Browse**: Double-click folders to navigate
- **Select**: Click files to select, Cmd+Click for multiple selection
- **Upload**: Select local files and click "Upload" or drag to remote pane
- **Download**: Select remote files and click "Download" or drag to local pane
- **Create Folder**: Use the folder icon in each pane's toolbar
- **Delete**: Select files and click the trash icon
- **Rename**: Select a single file and click "Rename"

### Transfer Management

- View active transfers in the bottom panel
- Monitor progress with real-time speed and ETA
- Cancel transfers by clicking the X button
- View detailed logs in the logs drawer

### Settings

Access settings via the settings icon in the connection bar:

- **Rsync Settings**: Configure rsync path and default flags
- **SSH Settings**: Adjust SSH connection options
- **Transfer Settings**: Set include/exclude patterns and delete mode
- **Default Paths**: Set default local and remote directories

### Profiles

Save connection configurations as profiles for quick access:

1. Click the profiles icon in the connection bar
2. Click "New Profile" to create a new profile
3. Fill in connection details and save
4. Use saved profiles to quickly connect to servers

## Architecture

### Main Process
- Handles SSH/SFTP connections using `ssh2-sftp-client`
- Manages rsync processes for file transfers
- Provides secure IPC API to renderer process
- Manages settings and profiles persistence

### Renderer Process
- React-based UI with TypeScript
- Two-pane file browser with drag & drop
- Real-time transfer progress display
- Settings and profile management

### Security
- Context isolation enabled
- No node integration in renderer
- All shell arguments are sanitized
- SSH keys are handled securely

## Development

### Project Structure
```
src/
├── main/           # Electron main process
├── renderer/       # React renderer process
├── shared/         # Shared types and utilities
├── preload/        # Preload script for secure IPC
└── __tests__/      # Unit tests
```

### Available Scripts

- `npm run dev` - Start Vite dev server
- `npm run electron:dev` - Run Electron in development mode
- `npm run build` - Build for production
- `npm run dist` - Package as DMG
- `npm test` - Run unit tests
- `npm run lint` - Run ESLint

### Testing

Run the test suite:
```bash
npm test
```

Run tests with coverage:
```bash
npm run test:coverage
```

## Configuration

### Settings Location
Settings are stored in `~/.twinsync/settings.json`

### Profiles Location
Profiles are stored in `~/.twinsync/profiles.json`

### Logs Location
Application logs are stored in `~/Library/Logs/TwinSync/app.log`

## Troubleshooting

### Common Issues

1. **rsync not found**: Install rsync via Homebrew: `brew install rsync`
2. **SSH connection failed**: Verify SSH key path and permissions
3. **Transfer fails**: Check remote rsync installation and permissions
4. **Permission denied**: Ensure proper file permissions on both local and remote

### Debug Mode

Run with debug logging:
```bash
DEBUG=* npm run electron:dev
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Acknowledgments

- Built with Electron, React, and TypeScript
- Uses `ssh2-sftp-client` for SFTP operations
- Styled with Tailwind CSS
- Icons from Lucide React
