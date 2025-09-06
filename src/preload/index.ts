import { contextBridge, ipcRenderer } from 'electron';

const electronAPI = {
  connect: (config: any) => ipcRenderer.invoke('connect', config),
  disconnect: () => ipcRenderer.invoke('disconnect'),
  listLocal: (dir: string) => ipcRenderer.invoke('list-local', dir),
  listRemote: (dir: string) => ipcRenderer.invoke('list-remote', dir),
  upload: (sourcePaths: string[], destDir: string) => ipcRenderer.invoke('upload', sourcePaths, destDir),
  download: (sourcePaths: string[], destDir: string) => ipcRenderer.invoke('download', sourcePaths, destDir),
  saveConfig: (config: any) => ipcRenderer.invoke('save-config', config),
  loadConfigs: () => ipcRenderer.invoke('load-configs'),
  deleteConfig: (configName: string) => ipcRenderer.invoke('delete-config', configName),
  localTransfer: (sourcePaths: string[], destDir: string) => ipcRenderer.invoke('local-transfer', sourcePaths, destDir),
};

contextBridge.exposeInMainWorld('electronAPI', electronAPI);

declare global {
  interface Window {
    electronAPI: typeof electronAPI;
  }
}
