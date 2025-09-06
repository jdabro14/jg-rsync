# JG-Rsync Application Management

This document explains how to manage the JG-Rsync macOS application bundle.

## 🚀 Quick Start

### Install the App
```bash
./manage-app.sh install
```

### Update the App (after making changes)
```bash
./manage-app.sh update
```

### Test the App
```bash
./manage-app.sh test
```

## 📋 Available Commands

| Command | Description |
|---------|-------------|
| `install` | Install/Reinstall JG-Rsync .app bundle |
| `update` | Update the installed .app bundle with latest changes |
| `test` | Test the installed .app bundle |
| `uninstall` | Remove JG-Rsync from /Applications |
| `status` | Check if JG-Rsync is installed and running |
| `fix` | Fix common issues with the .app bundle |
| `help` | Show help message |

## 🔄 Typical Workflow

1. **Make changes** to your code (CSS, React components, etc.)
2. **Update the app**: `./manage-app.sh update`
3. **Test the app**: `./manage-app.sh test`
4. **Launch from Applications** or Launchpad

## 🎨 Making UI Updates

For alignment and UI improvements like the screenshot you provided:

1. **Edit the CSS** in `src/index.css`
2. **Update the app**: `./manage-app.sh update`
3. **Test the changes**: `./manage-app.sh test`

## 🛠️ Troubleshooting

### App won't start
```bash
./manage-app.sh fix
```

### App shows "files not found" error
```bash
./manage-app.sh uninstall
./manage-app.sh install
```

### Check if app is running
```bash
./manage-app.sh status
```

## 📁 File Structure

```
JG-Rsync.app/
├── Contents/
│   ├── Info.plist          # App metadata
│   ├── MacOS/
│   │   └── JG-Rsync        # Launcher script
│   └── Resources/
│       ├── icon.icns       # App icon
│       ├── start.sh        # Main startup script
│       ├── package.json    # Dependencies
│       ├── index.html      # HTML entry point
│       ├── src/            # Source code
│       └── node_modules/   # Dependencies
```

## ✅ Benefits

- **Self-contained**: No external dependencies
- **Easy updates**: Simple command to update
- **Professional**: Proper macOS .app bundle
- **Custom icon**: Professional branding
- **Native integration**: Shows in Launchpad, Spotlight, etc.

## 🎯 Next Steps

After making UI improvements:

1. Run `./manage-app.sh update`
2. Test with `./manage-app.sh test`
3. Launch from Applications folder
4. Your changes will be live!

The app is now properly installed and ready for easy updates! 🎉
