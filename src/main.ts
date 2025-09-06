import { app, BrowserWindow, ipcMain } from 'electron';
import { join } from 'path';
import * as path from 'path';
import { spawn } from 'child_process';
import * as fs from 'fs';

class JGRsync {
  private mainWindow: BrowserWindow | null = null;
  private isConnected = false;
  private currentConfig: any = null;

  constructor() {
    this.setupIpcHandlers();
  }

  private setupIpcHandlers() {
    ipcMain.handle('connect', this.handleConnect.bind(this));
    ipcMain.handle('disconnect', this.handleDisconnect.bind(this));
    ipcMain.handle('list-local', this.handleListLocal.bind(this));
    ipcMain.handle('list-remote', this.handleListRemote.bind(this));
    ipcMain.handle('upload', this.handleUpload.bind(this));
    ipcMain.handle('download', this.handleDownload.bind(this));
    ipcMain.handle('save-config', this.handleSaveConfig.bind(this));
    ipcMain.handle('load-configs', this.handleLoadConfigs.bind(this));
    ipcMain.handle('delete-config', this.handleDeleteConfig.bind(this));
    ipcMain.handle('local-transfer', this.handleLocalTransfer.bind(this));
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
    // Fix SSH key path - use private key, not public key
    const privateKeyPath = config.keyPath.replace('.pub', '');
    
    return new Promise((resolve, reject) => {
      const ssh = spawn('ssh', [
        '-i', privateKeyPath,
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
  }

  private async handleListLocal(_event: any, dir: string): Promise<any[]> {
    try {
      console.log('Listing local files in:', dir);
      
      // Check if directory exists and is accessible
      const stats = await fs.promises.stat(dir);
      if (!stats.isDirectory()) {
        throw new Error(`Path is not a directory: ${dir}`);
      }

      // Read directory contents
      const entries = await fs.promises.readdir(dir, { withFileTypes: true });
      
      const files = await Promise.all(entries.map(async (entry) => {
        const fullPath = path.join(dir, entry.name);
        let size = undefined;
        
        if (entry.isFile()) {
          try {
            const fileStats = await fs.promises.stat(fullPath);
            size = fileStats.size;
          } catch (error) {
            console.warn(`Could not get size for ${fullPath}:`, error.message);
          }
        }
        
        return {
          name: entry.name,
          path: fullPath,
          isDirectory: entry.isDirectory(),
          size: size
        };
      }));

      // Sort: directories first, then files, both alphabetically
      files.sort((a, b) => {
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
        return a.name.localeCompare(b.name);
      });

      console.log('Local files found:', files.length, 'in', dir);
      return files;
    } catch (error) {
      console.error('Error listing local files:', error);
      throw new Error(`Failed to list local files: ${error.message}`);
    }
  }

  private async handleListRemote(_event: any, dir: string): Promise<any[]> {
    if (!this.isConnected || !this.currentConfig) {
      throw new Error('Not connected');
    }

    console.log('Listing remote directory:', dir);
    console.log('SSH config:', {
      host: this.currentConfig.host,
      user: this.currentConfig.user,
      port: this.currentConfig.port,
      keyPath: this.currentConfig.keyPath
    });

    // Fix SSH key path - use private key, not public key
    const privateKeyPath = this.currentConfig.keyPath.replace('.pub', '');
    
    return new Promise((resolve, reject) => {
      const ssh = spawn('ssh', [
        '-i', privateKeyPath,
        '-p', this.currentConfig.port.toString(),
        '-o', 'StrictHostKeyChecking=no',
        '-o', 'ConnectTimeout=10',
        `${this.currentConfig.user}@${this.currentConfig.host}`,
        `ls -la "${dir}" 2>/dev/null || echo "ERROR: Directory not found"`
      ]);

      let output = '';
      let errorOutput = '';
      
      ssh.stdout.on('data', (data) => {
        const dataStr = data.toString();
        output += dataStr;
        console.log('SSH stdout:', dataStr);
      });

      ssh.stderr.on('data', (data) => {
        const dataStr = data.toString();
        errorOutput += dataStr;
        console.log('SSH stderr:', dataStr);
      });

      ssh.on('close', (code) => {
        console.log('SSH process closed with code:', code);
        console.log('Full output:', output);
        console.log('Full error:', errorOutput);
        
        if (code === 0) {
          if (output.includes('ERROR: Directory not found')) {
            reject(new Error('Remote directory not found'));
          } else {
            const files = this.parseRemoteLsOutput(output, dir);
            console.log('Remote files found:', files.length, files);
            resolve(files);
          }
        } else {
          console.error('SSH error:', errorOutput);
          reject(new Error(`Failed to list remote files: ${errorOutput}`));
        }
      });
    });
  }

  private async handleUpload(_event: any, sourcePaths: string[], destDir: string): Promise<void> {
    if (!this.isConnected || !this.currentConfig) {
      throw new Error('Not connected');
    }

    // Fix SSH key path - use private key, not public key
    const privateKeyPath = this.currentConfig.keyPath.replace('.pub', '');
    
    return new Promise((resolve, reject) => {
      const rsync = spawn('rsync', [
        '-avz',
        '--progress',
        '-e', `ssh -i ${privateKeyPath} -p ${this.currentConfig.port} -o StrictHostKeyChecking=no`,
        ...sourcePaths,
        `${this.currentConfig.user}@${this.currentConfig.host}:"${destDir}"`
      ]);

      rsync.stdout.on('data', (data) => {
        console.log('Upload progress:', data.toString());
      });

      rsync.stderr.on('data', (data) => {
        console.log('Upload info:', data.toString());
      });

      rsync.on('close', (code) => {
        if (code === 0) {
          resolve();
        } else {
          reject(new Error('Upload failed'));
        }
      });
    });
  }

  private async handleDownload(_event: any, remotePath: string, localPath: string): Promise<void> {
    if (!this.isConnected || !this.currentConfig) {
      throw new Error('Not connected');
    }

    // Fix SSH key path - use private key, not public key
    const privateKeyPath = this.currentConfig.keyPath.replace('.pub', '');
    
    return new Promise((resolve, reject) => {
      const rsync = spawn('rsync', [
        '-avz',
        '--progress',
        '-e', `ssh -i ${privateKeyPath} -p ${this.currentConfig.port} -o StrictHostKeyChecking=no`,
        `${this.currentConfig.user}@${this.currentConfig.host}:"${remotePath}"`,
        localPath
      ]);

      let output = '';
      let errorOutput = '';

      rsync.stdout.on('data', (data) => {
        output += data.toString();
        console.log('Download progress:', data.toString());
      });

      rsync.stderr.on('data', (data) => {
        errorOutput += data.toString();
        console.log('Download info:', data.toString());
      });

      rsync.on('close', (code) => {
        if (code === 0) {
          console.log('Download completed successfully');
          resolve();
        } else {
          console.error('Download error:', errorOutput);
          reject(new Error(`Download failed: ${errorOutput}`));
        }
      });
    });
  }

  private async handleSaveConfig(_event: any, config: any): Promise<void> {
    const fs = require('fs');
    const path = require('path');
    const os = require('os');
    
    const configDir = path.join(os.homedir(), '.jg-rsync');
    const configFile = path.join(configDir, 'configs.json');
    
    // Ensure config directory exists
    if (!fs.existsSync(configDir)) {
      fs.mkdirSync(configDir, { recursive: true });
    }
    
    let configs = [];
    if (fs.existsSync(configFile)) {
      configs = JSON.parse(fs.readFileSync(configFile, 'utf8'));
    }
    
    // Add or update config
    const existingIndex = configs.findIndex((c: any) => c.name === config.name);
    if (existingIndex >= 0) {
      configs[existingIndex] = config;
    } else {
      configs.push(config);
    }
    
    fs.writeFileSync(configFile, JSON.stringify(configs, null, 2));
  }

  private async handleLoadConfigs(_event: any): Promise<any[]> {
    const fs = require('fs');
    const path = require('path');
    const os = require('os');
    
    const configDir = path.join(os.homedir(), '.jg-rsync');
    const configFile = path.join(configDir, 'configs.json');
    
    if (!fs.existsSync(configFile)) {
      return [];
    }
    
    return JSON.parse(fs.readFileSync(configFile, 'utf8'));
  }

  private async handleDeleteConfig(_event: any, configName: string): Promise<void> {
    const fs = require('fs');
    const path = require('path');
    const os = require('os');
    
    const configDir = path.join(os.homedir(), '.jg-rsync');
    const configFile = path.join(configDir, 'configs.json');
    
    if (!fs.existsSync(configFile)) {
      return;
    }
    
    let configs = JSON.parse(fs.readFileSync(configFile, 'utf8'));
    configs = configs.filter((c: any) => c.name !== configName);
    
    fs.writeFileSync(configFile, JSON.stringify(configs, null, 2));
  }

  private async handleLocalTransfer(_event: any, sourcePaths: string[], destDir: string): Promise<void> {
    return new Promise((resolve, reject) => {
      const rsync = spawn('rsync', [
        '-avz',
        '--progress',
        ...sourcePaths,
        destDir
      ]);

      let output = '';
      let errorOutput = '';

      rsync.stdout.on('data', (data) => {
        output += data.toString();
        console.log('Local transfer progress:', data.toString());
      });

      rsync.stderr.on('data', (data) => {
        errorOutput += data.toString();
        console.log('Local transfer info:', data.toString());
      });

      rsync.on('close', (code) => {
        if (code === 0) {
          console.log('Local transfer completed successfully');
          resolve();
        } else {
          console.error('Local transfer error:', errorOutput);
          reject(new Error(`Local transfer failed: ${errorOutput}`));
        }
      });
    });
  }

  private parseRemoteLsOutput(output: string, basePath: string): any[] {
    const lines = output.trim().split('\n');
    const files: any[] = [];

    for (const line of lines) {
      if (line.startsWith('total') || line.trim() === '') continue;
      
      const parts = line.trim().split(/\s+/);
      if (parts.length < 9) continue;

      const permissions = parts[0];
      const size = parts[4];
      const date = parts[5] + ' ' + parts[6] + ' ' + parts[7];
      
      // Handle symlinks and complex names better
      let name = parts.slice(8).join(' ');
      
      // Extract actual name from symlink (before ->)
      if (name.includes(' -> ')) {
        name = name.split(' -> ')[0];
      }
      
      if (name === '.' || name === '..') continue;

      const isDirectory = permissions.startsWith('d');
      const isSymlink = permissions.startsWith('l');
      const fullPath = join(basePath, name);

      files.push({
        name,
        path: fullPath,
        isDirectory: isDirectory || isSymlink, // Treat symlinks as directories for navigation
        size: parseInt(size) || 0,
        date: new Date(date),
        type: isDirectory ? 'directory' : (isSymlink ? 'symlink' : 'file'),
        isSymlink
      });
    }

    return files;
  }

  createWindow() {
    this.mainWindow = new BrowserWindow({
      width: 1200,
      height: 800,
      title: 'JG-Rsync',
      webPreferences: {
        nodeIntegration: false,
        contextIsolation: true,
        preload: join(__dirname, 'preload/index.js')
      }
    });

    if (process.env.NODE_ENV === 'development') {
      // Try port 5173 first, then 5174 if that fails
      this.loadDevURL().then(() => {
        // Only open dev tools if DEBUG is set
        if (process.env.DEBUG) {
          this.mainWindow.webContents.openDevTools();
        }
      });
    } else {
      this.mainWindow.loadFile(join(__dirname, 'index.html'));
    }
  }

  private async loadDevURL() {
    console.log('loadDevURL called, NODE_ENV:', process.env.NODE_ENV);
    const http = require('http');
    
    const checkPort = (port: number): Promise<boolean> => {
      return new Promise((resolve) => {
        const req = http.get(`http://localhost:${port}`, (res: any) => {
          console.log(`Port ${port} is available, status:`, res.statusCode);
          resolve(true);
        });
        req.on('error', (err: any) => {
          console.log(`Port ${port} not available:`, err.message);
          resolve(false);
        });
        req.setTimeout(2000, () => {
          console.log(`Port ${port} timeout`);
          req.destroy();
          resolve(false);
        });
      });
    };

    // Wait a bit for Vite to fully start
    await new Promise(resolve => setTimeout(resolve, 1000));

    // Try port 5173 first
    if (await checkPort(5173)) {
      console.log('Loading from port 5173');
      await this.mainWindow.loadURL('http://localhost:5173');
    } else if (await checkPort(5174)) {
      console.log('Loading from port 5174');
      await this.mainWindow.loadURL('http://localhost:5174');
    } else {
      console.error('No Vite dev server found on ports 5173 or 5174');
      // Try to load from port 5173 anyway as a last resort
      console.log('Attempting to load from port 5173 as fallback...');
      try {
        await this.mainWindow.loadURL('http://localhost:5173');
      } catch (error) {
        console.error('Failed to load from any port:', error);
        throw new Error('Cannot load Vite dev server');
      }
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