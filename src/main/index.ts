import { app, BrowserWindow, ipcMain } from 'electron';
import { join } from 'path';
import { spawn } from 'child_process';

class SimpleTwinSync {
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
    return new Promise((resolve, reject) => {
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
  }

  private async handleListLocal(_event: any, dir: string): Promise<any[]> {
    return new Promise((resolve, reject) => {
      const ls = spawn('ls', ['-la', dir]);
      let output = '';
      
      ls.stdout.on('data', (data) => {
        output += data.toString();
      });

      ls.on('close', (code) => {
        if (code === 0) {
          const files = this.parseLsOutput(output, dir);
          resolve(files);
        } else {
          reject(new Error('Failed to list local files'));
        }
      });
    });
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

  private async handleUpload(_event: any, sourcePaths: string[], destDir: string): Promise<void> {
    if (!this.isConnected || !this.currentConfig) {
      throw new Error('Not connected');
    }

    return new Promise((resolve, reject) => {
      const rsync = spawn('rsync', [
        '-avz',
        '--progress',
        ...sourcePaths,
        `${this.currentConfig.user}@${this.currentConfig.host}:${destDir}`
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

  private async handleDownload(_event: any, sourcePaths: string[], destDir: string): Promise<void> {
    if (!this.isConnected || !this.currentConfig) {
      throw new Error('Not connected');
    }

    return new Promise((resolve, reject) => {
      const rsync = spawn('rsync', [
        '-avz',
        '--progress',
        ...sourcePaths.map(path => `${this.currentConfig.user}@${this.currentConfig.host}:${path}`),
        destDir
      ]);

      rsync.stdout.on('data', (data) => {
        console.log('Download progress:', data.toString());
      });

      rsync.stderr.on('data', (data) => {
        console.log('Download info:', data.toString());
      });

      rsync.on('close', (code) => {
        if (code === 0) {
          resolve();
        } else {
          reject(new Error('Download failed'));
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

  createWindow() {
    this.mainWindow = new BrowserWindow({
      width: 1200,
      height: 800,
      webPreferences: {
        nodeIntegration: false,
        contextIsolation: true,
        preload: join(__dirname, '../preload/simple.js')
      }
    });

    if (process.env.NODE_ENV === 'development') {
      this.mainWindow.loadURL('http://localhost:5173');
      this.mainWindow.webContents.openDevTools();
    } else {
      this.mainWindow.loadFile(join(__dirname, '../renderer/index.html'));
    }
  }
}

// Create and run the app
const twinSync = new SimpleTwinSync();

app.whenReady().then(() => {
  twinSync.createWindow();
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    twinSync.createWindow();
  }
});
