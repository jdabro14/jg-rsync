import { app, BrowserWindow, ipcMain } from 'electron';
import { join } from 'path';
import { spawn } from 'child_process';
import { autoUpdater } from 'electron-updater';

class JGRsync {
  private mainWindow: BrowserWindow | null = null;
  private isConnected = false;
  private currentConfig: any = null;

  constructor() {
    this.setupIpcHandlers();
    this.setupAutoUpdater();
  }

  private setupAutoUpdater() {
    // Auto-updater disabled for local development
    console.log('Auto-updater disabled for local development');
  }

  private setupIpcHandlers() {
    console.log('Setting up IPC handlers');
    ipcMain.handle('connect', this.handleConnect.bind(this));
    ipcMain.handle('disconnect', this.handleDisconnect.bind(this));
    ipcMain.handle('list-local', (event: any, dir: string) => {
      console.log('list-local handler called with:', dir);
      return this.handleListLocal(event, dir);
    });
    ipcMain.handle('list-remote', this.handleListRemote.bind(this));
    ipcMain.handle('upload', this.handleUpload.bind(this));
    ipcMain.handle('download', this.handleDownload.bind(this));
    ipcMain.handle('save-config', (event: any, config: any) => {
      console.log('save-config handler called with:', config);
      return this.handleSaveConfig(event, config);
    });
    ipcMain.handle('load-configs', this.handleLoadConfigs.bind(this));
    ipcMain.handle('delete-config', this.handleDeleteConfig.bind(this));
    ipcMain.handle('local-transfer', this.handleLocalTransfer.bind(this));
    console.log('All IPC handlers registered');
  }

  private async handleConnect(_event: any, config: any): Promise<void> {
    try {
      // Test SSH connection
      await this.testSSHConnection(config);
      this.isConnected = true;
      this.currentConfig = config;
      console.log('Connected to:', config.host);
    } catch (error) {
      throw new Error(`SSH connection failed: ${error}`);
    }
  }

  private async handleDisconnect(): Promise<void> {
    this.isConnected = false;
    this.currentConfig = null;
    console.log('Disconnected');
  }

  private async testSSHConnection(config: any): Promise<void> {
    console.log('Testing SSH connection with config:', {
      user: config.user,
      host: config.host,
      port: config.port,
      keyPath: config.keyPath
    });

    return new Promise((resolve, reject) => {
      const sshArgs = [
        '-i', config.keyPath,
        '-p', config.port.toString(),
        '-o', 'ConnectTimeout=10',
        '-o', 'StrictHostKeyChecking=no',
        `${config.user}@${config.host}`,
        'echo "SSH connection test successful"'
      ];
      
      console.log('Running SSH test with args:', sshArgs);
      
      const ssh = spawn('ssh', sshArgs);

      let stdout = '';
      let stderr = '';

      ssh.stdout.on('data', (data) => {
        const output = data.toString();
        stdout += output;
        console.log('SSH stdout:', output);
      });

      ssh.stderr.on('data', (data) => {
        const output = data.toString();
        stderr += output;
        console.log('SSH stderr:', output);
      });

      ssh.on('error', (error) => {
        console.error('SSH process error:', error);
        reject(new Error(`SSH process error: ${error.message}`));
      });

      ssh.on('close', (code) => {
        console.log(`SSH process exited with code: ${code}`);
        console.log('SSH stdout:', stdout);
        console.log('SSH stderr:', stderr);
        
        if (code === 0) {
          resolve();
        } else {
          reject(new Error(`SSH test failed with exit code ${code}. Stderr: ${stderr}`));
        }
      });
    });
  }

  private async handleListLocal(_event: any, dir: string): Promise<any[]> {
    console.log('handleListLocal called with directory:', dir);
    try {
      return new Promise((resolve, reject) => {
        console.log('Spawning ls process for directory:', dir);
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
            const files = this.parseLsOutput(output, dir);
            console.log(`Found ${files.length} files in ${dir}`);
            resolve(files);
          } else {
            console.error('Failed to list local files:', errorOutput);
            reject(new Error(`Failed to list local files: ${errorOutput}`));
          }
        });
      });
    } catch (error) {
      console.error('Error in handleListLocal:', error);
      throw error;
    }
  }

  private async handleListRemote(_event: any, dir: string): Promise<any[]> {
    if (!this.isConnected || !this.currentConfig) {
      throw new Error('Not connected');
    }

    return new Promise((resolve, reject) => {
      const ssh = spawn('ssh', [
        '-i', this.currentConfig.keyPath,
        '-p', this.currentConfig.port.toString(),
        '-o', 'StrictHostKeyChecking=no',
        `${this.currentConfig.user}@${this.currentConfig.host}`,
        `ls -la "${dir}"`
      ]);

      let output = '';
      ssh.stdout.on('data', (data) => {
        output += data.toString();
      });

      ssh.on('close', (code) => {
        if (code === 0) {
          const files = this.parseLsOutput(output, dir);
          resolve(files);
        } else {
          reject(new Error('Failed to list remote files'));
        }
      });
    });
  }

  private async verifyRemoteFiles(sourcePaths: string[]): Promise<void> {
    console.log('Verifying remote files exist:', sourcePaths);
    
    for (const path of sourcePaths) {
      try {
        await this.checkRemoteFileExists(path);
      } catch (error) {
        throw new Error(`File does not exist on remote server: ${path}`);
      }
    }
    
    console.log('All files verified to exist on remote server');
  }

  private async checkRemoteFileExists(remotePath: string): Promise<void> {
    console.log(`Checking if file exists: ${remotePath}`);
    
    return new Promise((resolve, reject) => {
      const ssh = spawn('ssh', [
        '-i', this.currentConfig.keyPath,
        '-p', this.currentConfig.port.toString(),
        '-o', 'StrictHostKeyChecking=no',
        `${this.currentConfig.user}@${this.currentConfig.host}`,
        `test -e "${remotePath}"`
      ]);

      let stdout = '';
      let stderr = '';

      ssh.stdout.on('data', (data) => {
        stdout += data.toString();
        console.log(`File check stdout: ${data.toString()}`);
      });

      ssh.stderr.on('data', (data) => {
        stderr += data.toString();
        console.log(`File check stderr: ${data.toString()}`);
      });

      ssh.on('close', (code) => {
        console.log(`File check exited with code: ${code} for path: ${remotePath}`);
        console.log(`File check stdout: ${stdout}`);
        console.log(`File check stderr: ${stderr}`);
        
        if (code === 0) {
          resolve();
        } else {
          reject(new Error(`File does not exist: ${remotePath} (exit code: ${code})`));
        }
      });

      ssh.on('error', (error) => {
        console.error(`SSH error checking file: ${error.message}`);
        reject(new Error(`SSH error checking file: ${error.message}`));
      });
    });
  }

  private async handleUpload(_event: any, sourcePaths: string[], destDir: string): Promise<void> {
    if (!this.isConnected || !this.currentConfig) {
      throw new Error('Not connected');
    }

    console.log('Starting upload with config:', {
      user: this.currentConfig.user,
      host: this.currentConfig.host,
      sourcePaths,
      destDir
    });

    return new Promise((resolve, reject) => {
      const rsyncArgs = [
        '-avz',
        '--progress',
        ...sourcePaths,
        `${this.currentConfig.user}@${this.currentConfig.host}:"${destDir}"`
      ];
      
      console.log('Running rsync with args:', rsyncArgs);
      
      const rsync = spawn('rsync', rsyncArgs);

      let stdout = '';
      let stderr = '';

      rsync.stdout.on('data', (data) => {
        const output = data.toString();
        stdout += output;
        console.log('Upload progress:', output);
      });

      rsync.stderr.on('data', (data) => {
        const output = data.toString();
        stderr += output;
        console.log('Upload info:', output);
      });

      rsync.on('error', (error) => {
        console.error('Rsync process error:', error);
        reject(new Error(`Rsync process error: ${error.message}`));
      });

      rsync.on('close', (code) => {
        console.log(`Rsync process exited with code: ${code}`);
        console.log('Stdout:', stdout);
        console.log('Stderr:', stderr);
        
        if (code === 0) {
          resolve();
        } else {
          reject(new Error(`Upload failed with exit code ${code}. Stderr: ${stderr}`));
        }
      });
    });
  }

  private async handleDownload(_event: any, sourcePaths: string[], destDir: string): Promise<void> {
    if (!this.isConnected || !this.currentConfig) {
      throw new Error('Not connected');
    }

    console.log('Starting download with config:', {
      user: this.currentConfig.user,
      host: this.currentConfig.host,
      sourcePaths,
      destDir
    });

    return new Promise(async (resolve, reject) => {
      // First, verify that the files exist on the remote server
      try {
        await this.verifyRemoteFiles(sourcePaths);
      } catch (error) {
        reject(new Error(`File verification failed: ${error.message}`));
        return;
      }
      const rsyncArgs = [
        '-avz',
        '--progress',
        ...sourcePaths.map(path => `${this.currentConfig.user}@${this.currentConfig.host}:"${path}"`),
        destDir
      ];
      
      console.log('Running rsync with args:', rsyncArgs);
      
      const rsync = spawn('rsync', rsyncArgs);

      let stdout = '';
      let stderr = '';

      rsync.stdout.on('data', (data) => {
        const output = data.toString();
        stdout += output;
        console.log('Download progress:', output);
      });

      rsync.stderr.on('data', (data) => {
        const output = data.toString();
        stderr += output;
        console.log('Download info:', output);
      });

      rsync.on('error', (error) => {
        console.error('Rsync process error:', error);
        reject(new Error(`Rsync process error: ${error.message}`));
      });

      rsync.on('close', (code) => {
        console.log(`Rsync process exited with code: ${code}`);
        console.log('Stdout:', stdout);
        console.log('Stderr:', stderr);
        
        if (code === 0) {
          resolve();
        } else if (code === 23) {
          // Exit code 23 means some files were not found
          reject(new Error(`Some files not found on remote server. Please check the file paths. Stderr: ${stderr}`));
        } else if (stderr.includes('No such file or directory')) {
          reject(new Error(`Files not found on remote server: ${stderr}`));
        } else {
          reject(new Error(`Download failed with exit code ${code}. Stderr: ${stderr}`));
        }
      });
    });
  }

  private parseLsOutput(output: string, basePath: string): any[] {
    const lines = output.trim().split('\n');
    const files: any[] = [];

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
      const fullPath = join(basePath, name);

      files.push({
        name,
        path: fullPath,
        isDirectory,
        size: parseInt(size) || 0,
        date: new Date(date),
        type: isDirectory ? 'directory' : 'file'
      });
    }

    return files;
  }

  private async handleSaveConfig(_event: any, config: any): Promise<void> {
    console.log('handleSaveConfig called with config:', config);
    try {
      if (!config || !config.name) {
        console.error('Invalid config object or missing name property');
        throw new Error('Invalid configuration: missing name');
      }

      const fs = require('fs');
      const path = require('path');
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
      return Promise.resolve();
    } catch (error) {
      console.error('Error in handleSaveConfig:', error);
      throw error;
    }
  }

  private async handleLoadConfigs(): Promise<any[]> {
    const fs = require('fs');
    const path = require('path');
    const configDir = path.join(app.getPath('userData'), 'configs');
    
    if (!fs.existsSync(configDir)) {
      fs.mkdirSync(configDir, { recursive: true });
      return [];
    }
    
    const configFiles = fs.readdirSync(configDir).filter(file => file.endsWith('.json'));
    const configs = configFiles.map(file => {
      const configPath = path.join(configDir, file);
      const configData = fs.readFileSync(configPath, 'utf8');
      return JSON.parse(configData);
    });
    
    return configs;
  }

  private async handleDeleteConfig(_event: any, configName: string): Promise<void> {
    const fs = require('fs');
    const path = require('path');
    const configPath = path.join(app.getPath('userData'), 'configs', `${configName}.json`);
    
    if (fs.existsSync(configPath)) {
      fs.unlinkSync(configPath);
      console.log(`Config deleted: ${configName}`);
    }
  }

  private async handleLocalTransfer(_event: any, sourcePaths: string[], destDir: string): Promise<void> {
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
          resolve();
        } else {
          reject(new Error('Local transfer failed'));
        }
      });
    });
  }

  createWindow() {
    // Get window state from userData or use defaults
    const userDataPath = app.getPath('userData');
    const fs = require('fs');
    const path = require('path');
    const windowStatePath = path.join(userDataPath, 'window-state.json');
    
    console.log('Window state path:', windowStatePath);
    
    let windowState = {
      width: 1400,
      height: 900,
      x: undefined,
      y: undefined
    };
    
    // Try to load saved window state
    try {
      if (fs.existsSync(windowStatePath)) {
        const savedState = JSON.parse(fs.readFileSync(windowStatePath, 'utf8'));
        windowState = { ...windowState, ...savedState };
        console.log('Loaded window state:', windowState);
      } else {
        console.log('No saved window state, using defaults:', windowState);
      }
    } catch (error) {
      console.log('Could not load window state, using defaults:', error);
    }

    this.mainWindow = new BrowserWindow({
      width: windowState.width,
      height: windowState.height,
      x: windowState.x,
      y: windowState.y,
      minWidth: 1000,
      minHeight: 600,
      webPreferences: {
        nodeIntegration: false,
        contextIsolation: true,
        preload: join(__dirname, '../preload/index.js')
      }
    });

    console.log('Created window with size:', windowState.width, 'x', windowState.height);

    // Save window state on close and before-quit
    const saveWindowState = () => {
      try {
        if (this.mainWindow && !this.mainWindow.isDestroyed()) {
          const bounds = this.mainWindow.getBounds();
          console.log('Saving window state:', bounds);
          fs.writeFileSync(windowStatePath, JSON.stringify(bounds, null, 2));
        }
      } catch (error) {
        console.error('Error saving window state:', error);
      }
    };

    this.mainWindow.on('close', saveWindowState);
    app.on('before-quit', saveWindowState);

    if (process.env.NODE_ENV === 'development') {
      this.mainWindow.loadURL('http://localhost:5173');
      this.mainWindow.webContents.openDevTools();
    } else {
      this.mainWindow.loadFile(join(__dirname, '../index.html'));
    }
  }
}

// Create and run the app
const jgRsync = new JGRsync();

app.whenReady().then(() => {
  jgRsync.createWindow();
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    jgRsync.createWindow();
  }
});
