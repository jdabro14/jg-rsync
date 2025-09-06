const { app, BrowserWindow, ipcMain } = require('electron');
const path = require('path');

// Keep a global reference of the window object
let mainWindow;

function createWindow() {
  // Create the browser window
  // Determine the correct preload path based on whether we're in development or production
  let preloadPath;
  if (process.env.NODE_ENV === 'development') {
    preloadPath = path.join(__dirname, '../dist/preload/index.js');
  } else {
    // In production, we're likely inside the app bundle
    preloadPath = path.join(app.getAppPath(), 'dist/preload/index.js');
  }
  
  console.log('Using preload path:', preloadPath);
  
  mainWindow = new BrowserWindow({
    width: 1400,
    height: 900,
    minWidth: 800,
    minHeight: 600,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: preloadPath,
    },
    titleBarStyle: 'hiddenInset',
    show: false,
  });

  // Load the app
  if (process.env.NODE_ENV === 'development') {
    mainWindow.loadURL('http://localhost:5173');
    mainWindow.webContents.openDevTools();
  } else {
    mainWindow.loadFile(path.join(__dirname, '../dist/index.html'));
  }

  // Show window when ready
  mainWindow.once('ready-to-show', () => {
    mainWindow.show();
  });

  // Emitted when the window is closed
  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}

// This method will be called when Electron has finished initialization
app.whenReady().then(() => {
  // Test handler
  ipcMain.handle('test', (event, arg) => {
    console.log('Received test message:', arg);
    return 'Test response';
  });

  // Connection handlers
  ipcMain.handle('connect', async (event, config) => {
    console.log('connect handler called with:', config);
    const { spawn } = require('child_process');
    
    try {
      // Test SSH connection
      await new Promise((resolve, reject) => {
        const ssh = spawn('ssh', [
          '-i', config.keyPath,
          '-p', config.port.toString(),
          '-o', 'ConnectTimeout=10',
          '-o', 'StrictHostKeyChecking=no',
          `${config.user}@${config.host}`,
          'echo "SSH connection test successful"'
        ]);

        let output = '';
        ssh.stdout.on('data', (data) => {
          output += data.toString();
        });

        ssh.stderr.on('data', (data) => {
          output += data.toString();
        });

        ssh.on('close', (code) => {
          if (code === 0) {
            resolve();
          } else {
            reject(new Error(`SSH test failed: ${output}`));
          }
        });
      });
      
      console.log('Connected to:', config.host);
      return { success: true };
    } catch (error) {
      console.error('Connection error:', error);
      throw new Error(`SSH connection failed: ${error.message}`);
    }
  });

  ipcMain.handle('disconnect', async () => {
    console.log('disconnect handler called');
    return { success: true };
  });

  // File listing handlers
  ipcMain.handle('list-local', async (event, dir) => {
    console.log('list-local handler called with:', dir);
    const { spawn } = require('child_process');
    
    try {
      return new Promise((resolve, reject) => {
        const ls = spawn('ls', ['-la', dir]);
        let output = '';
        let errorOutput = '';
        
        ls.stdout.on('data', (data) => {
          output += data.toString();
        });

        ls.stderr.on('data', (data) => {
          errorOutput += data.toString();
          console.error('ls stderr:', data.toString());
        });

        ls.on('close', (code) => {
          console.log(`ls process exited with code ${code}`);
          if (code === 0) {
            const files = parseLsOutput(output, dir);
            console.log(`Found ${files.length} files in ${dir}`);
            resolve(files);
          } else {
            console.error('Failed to list local files:', errorOutput);
            reject(new Error(`Failed to list local files: ${errorOutput}`));
          }
        });
      });
    } catch (error) {
      console.error('Error in list-local handler:', error);
      throw error;
    }
  });

  // Store the current connection config globally
  let currentConfig = null;
  
  ipcMain.handle('connect', async (event, config) => {
    console.log('connect handler called with:', config);
    const { spawn } = require('child_process');
    
    try {
      // Test SSH connection
      await new Promise((resolve, reject) => {
        const ssh = spawn('ssh', [
          '-i', config.keyPath,
          '-p', config.port.toString(),
          '-o', 'ConnectTimeout=10',
          '-o', 'StrictHostKeyChecking=no',
          `${config.user}@${config.host}`,
          'echo "SSH connection test successful"'
        ]);

        let output = '';
        ssh.stdout.on('data', (data) => {
          output += data.toString();
        });

        ssh.stderr.on('data', (data) => {
          output += data.toString();
        });

        ssh.on('close', (code) => {
          if (code === 0) {
            resolve();
          } else {
            reject(new Error(`SSH test failed: ${output}`));
          }
        });
      });
      
      // Store the config for later use
      currentConfig = config;
      console.log('Connected to:', config.host);
      return { success: true };
    } catch (error) {
      console.error('Connection error:', error);
      throw new Error(`SSH connection failed: ${error.message}`);
    }
  });

  ipcMain.handle('disconnect', async () => {
    console.log('disconnect handler called');
    currentConfig = null;
    return { success: true };
  });
  
  ipcMain.handle('list-remote', async (event, dir) => {
    console.log('list-remote handler called with:', dir);
    const { spawn } = require('child_process');
    
    try {
      if (!currentConfig) {
        throw new Error('Not connected to any remote server');
      }
      
      return new Promise((resolve, reject) => {
        const ssh = spawn('ssh', [
          '-i', currentConfig.keyPath,
          '-p', currentConfig.port.toString(),
          '-o', 'StrictHostKeyChecking=no',
          `${currentConfig.user}@${currentConfig.host}`,
          `ls -la "${dir}"`
        ]);

        let output = '';
        let errorOutput = '';
        
        ssh.stdout.on('data', (data) => {
          output += data.toString();
        });
        
        ssh.stderr.on('data', (data) => {
          errorOutput += data.toString();
          console.error('ssh stderr:', data.toString());
        });

        ssh.on('close', (code) => {
          if (code === 0) {
            const files = parseLsOutput(output, dir);
            console.log(`Found ${files.length} files in remote dir ${dir}`);
            resolve(files);
          } else {
            console.error('Failed to list remote files:', errorOutput);
            reject(new Error(`Failed to list remote files: ${errorOutput}`));
          }
        });
      });
    } catch (error) {
      console.error('Error in list-remote handler:', error);
      throw error;
    }
  });

  // File transfer handlers
  ipcMain.handle('upload', async (event, sourcePaths, destDir) => {
    console.log('upload handler called with:', sourcePaths, destDir);
    const { spawn } = require('child_process');
    
    try {
      if (!currentConfig) {
        throw new Error('Not connected to any remote server');
      }
      
      return new Promise((resolve, reject) => {
        const rsync = spawn('rsync', [
          '-avz',
          '--progress',
          ...sourcePaths,
          `${currentConfig.user}@${currentConfig.host}:${destDir}`
        ]);

        let errorOutput = '';
        
        rsync.stdout.on('data', (data) => {
          console.log('Upload progress:', data.toString());
        });

        rsync.stderr.on('data', (data) => {
          errorOutput += data.toString();
          console.log('Upload info:', data.toString());
        });

        rsync.on('close', (code) => {
          if (code === 0) {
            resolve({ success: true });
          } else {
            console.error('Upload failed:', errorOutput);
            reject(new Error(`Upload failed: ${errorOutput}`));
          }
        });
      });
    } catch (error) {
      console.error('Error in upload handler:', error);
      throw error;
    }
  });

  ipcMain.handle('download', async (event, sourcePaths, destDir) => {
    console.log('download handler called with:', sourcePaths, destDir);
    const { spawn } = require('child_process');
    
    try {
      if (!currentConfig) {
        throw new Error('Not connected to any remote server');
      }
      
      return new Promise((resolve, reject) => {
        const rsync = spawn('rsync', [
          '-avz',
          '--progress',
          ...sourcePaths.map(path => `${currentConfig.user}@${currentConfig.host}:${path}`),
          destDir
        ]);

        let errorOutput = '';
        
        rsync.stdout.on('data', (data) => {
          console.log('Download progress:', data.toString());
        });

        rsync.stderr.on('data', (data) => {
          errorOutput += data.toString();
          console.log('Download info:', data.toString());
        });

        rsync.on('close', (code) => {
          if (code === 0) {
            resolve({ success: true });
          } else {
            console.error('Download failed:', errorOutput);
            reject(new Error(`Download failed: ${errorOutput}`));
          }
        });
      });
    } catch (error) {
      console.error('Error in download handler:', error);
      throw error;
    }
  });

  ipcMain.handle('local-transfer', async (event, sourcePaths, destDir) => {
    console.log('local-transfer handler called with:', sourcePaths, destDir);
    const { spawn } = require('child_process');
    
    try {
      return new Promise((resolve, reject) => {
        const rsync = spawn('rsync', [
          '-avz',
          '--progress',
          ...sourcePaths,
          destDir
        ]);

        rsync.stdout.on('data', (data) => {
          console.log('Local transfer progress:', data.toString());
        });

        rsync.stderr.on('data', (data) => {
          console.log('Local transfer info:', data.toString());
        });

        rsync.on('close', (code) => {
          if (code === 0) {
            resolve({ success: true });
          } else {
            reject(new Error('Local transfer failed'));
          }
        });
      });
    } catch (error) {
      console.error('Error in local-transfer handler:', error);
      throw error;
    }
  });

  // Configuration handlers
  ipcMain.handle('save-config', async (event, config) => {
    console.log('save-config handler called with:', config);
    const fs = require('fs');
    const path = require('path');
    
    try {
      if (!config || !config.name) {
        console.error('Invalid config object or missing name property');
        throw new Error('Invalid configuration: missing name');
      }

      const configDir = path.join(app.getPath('userData'), 'configs');
      console.log('Config directory:', configDir);
      
      // Create configs directory if it doesn't exist
      if (!fs.existsSync(configDir)) {
        console.log('Creating config directory');
        fs.mkdirSync(configDir, { recursive: true });
      }
      
      const configPath = path.join(configDir, `${config.name}.json`);
      console.log('Saving config to:', configPath);
      
      fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
      console.log(`Config saved successfully: ${config.name}`);
      return { success: true };
    } catch (error) {
      console.error('Error in save-config handler:', error);
      throw error;
    }
  });

  ipcMain.handle('load-configs', async () => {
    const fs = require('fs');
    const path = require('path');
    
    try {
      console.log('load-configs handler called');
      const userDataPath = app.getPath('userData');
      console.log('User data path:', userDataPath);
      
      const configDir = path.join(userDataPath, 'configs');
      console.log('Config directory:', configDir);
      
      if (!fs.existsSync(configDir)) {
        console.log('Config directory does not exist, creating it');
        fs.mkdirSync(configDir, { recursive: true });
        return [];
      }
      
      const configFiles = fs.readdirSync(configDir).filter(file => file.endsWith('.json'));
      console.log('Found config files:', configFiles);
      
      const configs = configFiles.map(file => {
        const configPath = path.join(configDir, file);
        console.log('Reading config file:', configPath);
        const configData = fs.readFileSync(configPath, 'utf8');
        return JSON.parse(configData);
      });
      
      console.log(`Loaded ${configs.length} configs:`, configs);
      return configs;
    } catch (error) {
      console.error('Error in load-configs handler:', error);
      throw error;
    }
  });
  
  ipcMain.handle('delete-config', async (event, configName) => {
    console.log('delete-config handler called with:', configName);
    const fs = require('fs');
    const path = require('path');
    
    try {
      const configDir = path.join(app.getPath('userData'), 'configs');
      const configPath = path.join(configDir, `${configName}.json`);
      
      if (fs.existsSync(configPath)) {
        fs.unlinkSync(configPath);
        console.log(`Config deleted: ${configName}`);
        return { success: true };
      } else {
        console.log(`Config not found: ${configName}`);
        return { success: false, error: 'Config not found' };
      }
    } catch (error) {
      console.error('Error in delete-config handler:', error);
      throw error;
    }
  });

  createWindow();
});

// Helper function to parse ls output
function parseLsOutput(output, basePath) {
  const lines = output.trim().split('\n');
  const files = [];

  for (const line of lines) {
    if (line.startsWith('total') || line.trim() === '') continue;
    
    const parts = line.trim().split(/\s+/);
    if (parts.length < 9) continue;

    const permissions = parts[0];
    const size = parts[4];
    const date = parts[5] + ' ' + parts[6] + ' ' + parts[7];
    const name = parts.slice(8).join(' ');
    
    if (name === '.' || name === '..') continue;

    const isDirectory = permissions.startsWith('d');
    const path = `${basePath}/${name}`.replace(/\/\/+/g, '/');
    
    files.push({
      name,
      path,
      isDirectory,
      size: parseInt(size) || 0,
      date: new Date(date),
      type: isDirectory ? 'directory' : 'file'
    });
  }

  return files;
}

// Quit when all windows are closed
app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    createWindow();
  }
});
