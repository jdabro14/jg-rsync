import React, { useState, useEffect } from 'react';

interface FileItem {
  name: string;
  isDirectory: boolean;
  size?: number;
  path: string;
}

interface ConnectionConfig {
  user: string;
  host: string;
  port: number;
  keyPath: string;
  remotePath: string;
  name?: string;
}

const SimpleApp: React.FC = () => {
  // Connection state
  const [isConnected, setIsConnected] = useState(false);
  const [config, setConfig] = useState<ConnectionConfig>({
    user: 'username',
    host: 'hostname or IP',
    port: 22,
    keyPath: '/Users/jgingold/.ssh/id_rsa',
    remotePath: '/home'
  });
  
  // Left pane: Always local
  const [leftPath, setLeftPath] = useState('/Users/jgingold');
  const [leftFiles, setLeftFiles] = useState<FileItem[]>([]);
  const [selectedLeft, setSelectedLeft] = useState<string[]>([]);
  
  // Right pane: Can be local or remote
  const [rightType, setRightType] = useState<'local' | 'remote'>('local');
  const [rightPath, setRightPath] = useState('/Users/jgingold');
  const [rightFiles, setRightFiles] = useState<FileItem[]>([]);
  const [selectedRight, setSelectedRight] = useState<string[]>([]);
  
  // UI state
  const [status, setStatus] = useState('Ready');
  const [savedConfigs, setSavedConfigs] = useState<ConnectionConfig[]>([]);
  const [configName, setConfigName] = useState('');

  // Load files for left pane (always local)
  const loadLeftFiles = async () => {
    if (!window.electronAPI) return;
    try {
      console.log(`Loading left files from: ${leftPath}`);
      const files = await window.electronAPI.listLocal(leftPath);
      console.log(`Loaded ${files.length} left files`);
      setLeftFiles(files);
    } catch (error) {
      console.error('Failed to load left files:', error);
      setStatus(`Failed to load left files: ${error}`);
    }
  };

  // Load files for right pane (local or remote)
  const loadRightFiles = async () => {
    if (!window.electronAPI) return;
    try {
      console.log(`Loading right files from: ${rightPath} (type: ${rightType})`);
      if (rightType === 'local') {
        const files = await window.electronAPI.listLocal(rightPath);
        console.log(`Loaded ${files.length} right files (local)`);
        setRightFiles(files);
      } else if (rightType === 'remote' && isConnected) {
        const files = await window.electronAPI.listRemote(rightPath);
        console.log(`Loaded ${files.length} right files (remote)`);
        setRightFiles(files);
      }
    } catch (error) {
      console.error('Failed to load right files:', error);
      setStatus(`Failed to load right files: ${error}`);
    }
  };

  // Load saved configurations
  const loadSavedConfigs = async () => {
    if (!window.electronAPI) return;
    try {
      const configs = await window.electronAPI.loadConfigs();
      setSavedConfigs(configs);
    } catch (error) {
      console.error('Failed to load configs:', error);
    }
  };

  // Connect to remote server
  const handleConnect = async () => {
    if (!window.electronAPI) return;
    try {
      setStatus('Connecting...');
      await window.electronAPI.connect(config);
      setIsConnected(true);
      setStatus('Connected');
      if (rightType === 'remote') {
        loadRightFiles();
      }
    } catch (error) {
      console.error('Connection failed:', error);
      setStatus(`Connection failed: ${error}`);
    }
  };

  // Disconnect from remote server
  const handleDisconnect = async () => {
    if (!window.electronAPI) return;
    try {
      await window.electronAPI.disconnect();
      setIsConnected(false);
      setStatus('Disconnected');
      if (rightType === 'remote') {
        setRightFiles([]);
      }
    } catch (error) {
      console.error('Disconnect failed:', error);
      setStatus(`Disconnect failed: ${error}`);
    }
  };

  // Transfer files from left to right
  const handleTransferLeftToRight = async () => {
    if (!window.electronAPI) return;
    if (selectedLeft.length === 0) {
      setStatus('Please select files to transfer');
      return;
    }

    try {
      setStatus('Transferring files...');
      
      if (rightType === 'local') {
        // Local to local transfer
        await window.electronAPI.localTransfer(selectedLeft, rightPath);
        setStatus(`Transferred ${selectedLeft.length} file(s) to ${rightPath}`);
      } else if (rightType === 'remote' && isConnected) {
        // Local to remote transfer
        await window.electronAPI.upload(selectedLeft, rightPath);
        setStatus(`Uploaded ${selectedLeft.length} file(s) to ${rightPath}`);
      }
      
      setSelectedLeft([]);
      loadRightFiles(); // Refresh right pane
    } catch (error) {
      console.error('Transfer failed:', error);
      setStatus(`Transfer failed: ${error}`);
    }
  };

  // Transfer files from right to left
  const handleTransferRightToLeft = async () => {
    if (!window.electronAPI) return;
    if (selectedRight.length === 0) {
      setStatus('Please select files to transfer');
      return;
    }

    try {
      setStatus('Transferring files...');
      
      if (rightType === 'local') {
        // Local to local transfer
        await window.electronAPI.localTransfer(selectedRight, leftPath);
        setStatus(`Transferred ${selectedRight.length} file(s) to ${leftPath}`);
      } else if (rightType === 'remote' && isConnected) {
        // Remote to local transfer
        await window.electronAPI.download(selectedRight, leftPath);
        setStatus(`Downloaded ${selectedRight.length} file(s) to ${leftPath}`);
      }
      
      setSelectedRight([]);
      loadLeftFiles(); // Refresh left pane
    } catch (error) {
      console.error('Transfer failed:', error);
      setStatus(`Transfer failed: ${error}`);
    }
  };

  // Navigate to directory
  const navigateTo = (path: string, pane: 'left' | 'right') => {
    console.log(`Navigating to ${path} in ${pane} pane`);
    console.log(`Current leftPath: ${leftPath}, rightPath: ${rightPath}`);
    
    // Normalize the path to prevent recursive issues
    let normalizedPath = path.replace(/\/+/g, '/').replace(/\/$/, '') || '/';
    
    // Handle Google Drive symlinks to prevent recursion
    if (normalizedPath.includes('jdabro@gmail.com - Google Drive')) {
      normalizedPath = '/Users/jgingold/Library/CloudStorage/GoogleDrive-jdabro@gmail.com';
      console.log(`Resolved Google Drive symlink to: ${normalizedPath}`);
    } else if (normalizedPath.includes('jesse@crexpedio.com - Google Drive')) {
      normalizedPath = '/Users/jgingold/Library/CloudStorage/GoogleDrive-jesse@crexpedio.com';
      console.log(`Resolved Google Drive symlink to: ${normalizedPath}`);
    }
    
    // Handle special cases for parent directory navigation
    if (path === '..' || path.endsWith('/..')) {
      const currentPath = pane === 'left' ? leftPath : rightPath;
      normalizedPath = currentPath.split('/').slice(0, -1).join('/') || '/';
      console.log(`Parent directory navigation: ${normalizedPath}`);
    }
    
    console.log(`Final normalized path: ${normalizedPath}`);
    
    if (pane === 'left') {
      setLeftPath(normalizedPath);
      setSelectedLeft([]);
      console.log(`Set leftPath to: ${normalizedPath}`);
    } else {
      setRightPath(normalizedPath);
      setSelectedRight([]);
      console.log(`Set rightPath to: ${normalizedPath}`);
    }
  };

  // Toggle right pane type
  const toggleRightType = () => {
    const newType = rightType === 'local' ? 'remote' : 'local';
    setRightType(newType);
    setRightPath(newType === 'local' ? '/Users/jgingold' : '/home');
    setSelectedRight([]);
    setRightFiles([]);
  };

  // Save configuration
  const saveConfig = async () => {
    if (!window.electronAPI || !configName.trim()) return;
    try {
      const configToSave = { ...config, name: configName };
      await window.electronAPI.saveConfig(configToSave);
      setStatus(`Configuration '${configName}' saved`);
      setConfigName('');
      loadSavedConfigs();
    } catch (error) {
      console.error('Save config failed:', error);
      setStatus(`Save config failed: ${error}`);
    }
  };

  // Load configuration
  const loadConfig = (configToLoad: ConnectionConfig) => {
    setConfig(configToLoad);
    setStatus(`Loaded configuration '${configToLoad.name}'`);
  };

  // Delete configuration
  const deleteConfig = async (configName: string) => {
    if (!window.electronAPI) return;
    try {
      await window.electronAPI.deleteConfig(configName);
      setStatus(`Configuration '${configName}' deleted`);
      loadSavedConfigs();
    } catch (error) {
      console.error('Delete config failed:', error);
      setStatus(`Delete config failed: ${error}`);
    }
  };

  // Initialize
  useEffect(() => {
    console.log(`Initial state - leftPath: ${leftPath}, rightPath: ${rightPath}, rightType: ${rightType}`);
    if (window.electronAPI) {
      loadLeftFiles();
      loadRightFiles();
      loadSavedConfigs();
    } else {
      console.log('Waiting for electronAPI to load...');
      const checkAPI = setInterval(() => {
        if (window.electronAPI) {
          clearInterval(checkAPI);
          loadLeftFiles();
          loadRightFiles();
          loadSavedConfigs();
        }
      }, 100);
      
      return () => clearInterval(checkAPI);
    }
  }, []);

  // Load files when paths change
  useEffect(() => {
    if (window.electronAPI) {
      loadLeftFiles();
    }
  }, [leftPath]);

  useEffect(() => {
    if (window.electronAPI) {
      loadRightFiles();
    }
  }, [rightPath, rightType, isConnected]);

  // Render breadcrumbs
  const renderBreadcrumbs = (path: string, pane: 'left' | 'right') => {
    // Handle root path
    if (path === '/') {
      return (
        <div className="breadcrumbs">
          <button
            className="breadcrumb-link"
            onClick={() => navigateTo('/', pane)}
          >
            🏠
          </button>
          <span className="current-path-text">Current: /</span>
        </div>
      );
    }

    // Handle Google Drive paths with friendly names
    let displayPath = path;
    if (path.includes('GoogleDrive-jdabro@gmail.com')) {
      displayPath = path.replace('/Users/jgingold/Library/CloudStorage/GoogleDrive-jdabro@gmail.com', '📁 Google Drive (jdabro)');
    } else if (path.includes('GoogleDrive-jesse@crexpedio.com')) {
      displayPath = path.replace('/Users/jgingold/Library/CloudStorage/GoogleDrive-jesse@crexpedio.com', '📁 Google Drive (jesse)');
    }

    const parts = path.split('/').filter(part => part);
    const breadcrumbs = parts.map((part, index) => {
      const fullPath = '/' + parts.slice(0, index + 1).join('/');
      let displayPart = part;
      
      // Show friendly names for Google Drive
      if (part === 'GoogleDrive-jdabro@gmail.com') {
        displayPart = '📁 Google Drive (jdabro)';
      } else if (part === 'GoogleDrive-jesse@crexpedio.com') {
        displayPart = '📁 Google Drive (jesse)';
      }
      
      return (
        <span key={fullPath}>
          <button
            className="breadcrumb-link"
            onClick={() => navigateTo(fullPath, pane)}
          >
            {displayPart}
          </button>
          {index < parts.length - 1 && ' / '}
        </span>
      );
    });

    return (
      <div className="breadcrumbs">
        <button
          className="breadcrumb-link"
          onClick={() => navigateTo('/', pane)}
        >
          🏠
        </button>
        {breadcrumbs.length > 0 && ' / '}
        {breadcrumbs}
        <span className="current-path-text">Current: {displayPath}</span>
      </div>
    );
  };

  return (
    <div className="app">
      {/* Header */}
      <div className="header">
        <h1>JG-Rsync</h1>
        <div className="status">{status}</div>
      </div>

      {/* Three-Pane Layout */}
      <div className="three-pane-layout">
        {/* Left Pane - Connection & Configuration */}
        <div className="pane connection-pane">
          <div className="pane-header">
            <h3>Connection & Config</h3>
          </div>
          <div className="connection-form">
            <div className="form-group">
              <label>User:</label>
              <input
                type="text"
                value={config.user}
                onChange={(e) => setConfig({ ...config, user: e.target.value })}
              />
            </div>
            <div className="form-group">
              <label>Host:</label>
              <input
                type="text"
                value={config.host}
                onChange={(e) => setConfig({ ...config, host: e.target.value })}
              />
            </div>
            <div className="form-group">
              <label>Port:</label>
              <input
                type="number"
                value={config.port}
                onChange={(e) => setConfig({ ...config, port: parseInt(e.target.value) })}
              />
            </div>
            <div className="form-group">
              <label>Key Path:</label>
              <input
                type="text"
                value={config.keyPath}
                onChange={(e) => setConfig({ ...config, keyPath: e.target.value })}
              />
            </div>
            <div className="form-group">
              <label>Remote Path:</label>
              <input
                type="text"
                value={config.remotePath}
                onChange={(e) => setConfig({ ...config, remotePath: e.target.value })}
              />
            </div>
            <div className="form-actions">
              {!isConnected ? (
                <button className="btn btn-primary" onClick={handleConnect}>
                  Connect
                </button>
              ) : (
                <button className="btn btn-secondary" onClick={handleDisconnect}>
                  Disconnect
                </button>
              )}
            </div>
          </div>

          {/* Configuration Management */}
          <div className="config-management">
            <div className="form-group">
              <label>Save Config:</label>
              <input
                type="text"
                placeholder="Config name"
                value={configName}
                onChange={(e) => setConfigName(e.target.value)}
              />
              <button className="btn btn-secondary" onClick={saveConfig}>
                Save
              </button>
            </div>
            <div className="saved-configs">
              <h4>Saved Configurations:</h4>
              {savedConfigs.map((savedConfig) => (
                <div key={savedConfig.name} className="config-item">
                  <button
                    className="btn btn-small"
                    onClick={() => loadConfig(savedConfig)}
                  >
                    Load
                  </button>
                  <span className="config-name">{savedConfig.name}</span>
                  <button
                    className="btn btn-small btn-danger"
                    onClick={() => deleteConfig(savedConfig.name!)}
                  >
                    Delete
                  </button>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Middle Pane - Local Files */}
        {/* Debug info */}
        {(() => { console.log('Rendering left pane with', leftFiles.length, 'files'); return null; })()}
        <div className="pane left-pane">
          <div className="pane-header">
            <h3>Local Files</h3>
            <div className="pane-actions">
              <button
                className="btn btn-secondary"
                onClick={() => navigateTo('/Users/jgingold', 'left')}
              >
                🏠 Home
              </button>
              <button
                className="btn btn-secondary"
                onClick={() => navigateTo('/Volumes', 'left')}
              >
                💾 Volumes
              </button>
              <button
                className="btn btn-secondary"
                onClick={() => navigateTo('/Users/jgingold/Library/CloudStorage/GoogleDrive-jdabro@gmail.com', 'left')}
              >
                📁 Google Drive (jdabro)
              </button>
              <button
                className="btn btn-secondary"
                onClick={() => navigateTo('/Users/jgingold/Library/CloudStorage/GoogleDrive-jesse@crexpedio.com', 'left')}
              >
                📁 Google Drive (jesse)
              </button>
            </div>
          </div>
          <div className="current-path">
            {renderBreadcrumbs(leftPath, 'left')}
          </div>
          <div className="file-list">
            {leftFiles.length === 0 ? (
              <div style={{ padding: '20px', textAlign: 'center', color: '#666' }}>
                No files found in {leftPath}
              </div>
            ) : (
              leftFiles.map((file) => (
                <div
                  key={file.path}
                  className={`file-item ${selectedLeft.includes(file.path) ? 'selected' : ''}`}
                  onClick={() => {
                    if (file.isDirectory) {
                      navigateTo(file.path, 'left');
                    } else {
                      setSelectedLeft(prev => 
                        prev.includes(file.path) 
                          ? prev.filter(p => p !== file.path)
                          : [...prev, file.path]
                      );
                    }
                  }}
                >
                  <span className="file-icon">
                    {file.isDirectory ? '📁' : '📄'}
                  </span>
                  <span className="file-name">{file.name}</span>
                  {!file.isDirectory && (
                    <span className="file-size">
                      {file.size ? `${(file.size / 1024).toFixed(1)} KB` : ''}
                    </span>
                  )}
                </div>
              ))
            )}
          </div>
          {selectedLeft.length > 0 && (
            <div className="transfer-actions">
              <button className="btn btn-primary" onClick={handleTransferLeftToRight}>
                → Transfer {selectedLeft.length} file(s) to Right
              </button>
            </div>
          )}
        </div>

        {/* Right Pane - Remote/Local Files */}
        {/* Debug info */}
        {(() => { console.log('Rendering right pane with', rightFiles.length, 'files'); return null; })()}
        <div className="pane right-pane">
          <div className="pane-header">
            <h3>{rightType === 'local' ? 'Local Files' : 'Remote Files'}</h3>
            <div className="pane-actions">
              <button
                className="btn btn-small"
                onClick={toggleRightType}
              >
                Switch to {rightType === 'local' ? 'Remote' : 'Local'}
              </button>
              {rightType === 'local' ? (
                <>
                  <button
                    className="btn btn-secondary"
                    onClick={() => navigateTo('/Users/jgingold', 'right')}
                  >
                    🏠 Home
                  </button>
                  <button
                    className="btn btn-secondary"
                    onClick={() => navigateTo('/Volumes', 'right')}
                  >
                    💾 Volumes
                  </button>
                </>
              ) : (
                <>
                  <button
                    className="btn btn-secondary"
                    onClick={() => navigateTo('/home', 'right')}
                  >
                    🏠 Home
                  </button>
                  <button
                    className="btn btn-secondary"
                    onClick={() => navigateTo('/', 'right')}
                  >
                    📁 Root
                  </button>
                </>
              )}
            </div>
          </div>
          <div className="current-path">
            {renderBreadcrumbs(rightPath, 'right')}
          </div>
          <div className="file-list">
            {rightFiles.length === 0 ? (
              <div style={{ padding: '20px', textAlign: 'center', color: '#666' }}>
                No files found in {rightPath}
              </div>
            ) : (
              rightFiles.map((file) => (
                <div
                  key={file.path}
                  className={`file-item ${selectedRight.includes(file.path) ? 'selected' : ''}`}
                  onClick={() => {
                    if (file.isDirectory) {
                      navigateTo(file.path, 'right');
                    } else {
                      setSelectedRight(prev => 
                        prev.includes(file.path) 
                          ? prev.filter(p => p !== file.path)
                          : [...prev, file.path]
                      );
                    }
                  }}
                >
                  <span className="file-icon">
                    {file.isDirectory ? '📁' : '📄'}
                  </span>
                  <span className="file-name">{file.name}</span>
                  {!file.isDirectory && (
                    <span className="file-size">
                      {file.size ? `${(file.size / 1024).toFixed(1)} KB` : ''}
                    </span>
                  )}
                </div>
              ))
            )}
          </div>
          {selectedRight.length > 0 && (
            <div className="transfer-actions">
              <button className="btn btn-primary" onClick={handleTransferRightToLeft}>
                ← Transfer {selectedRight.length} file(s) to Left
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default SimpleApp;