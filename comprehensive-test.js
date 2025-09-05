#!/usr/bin/env node

const { spawn } = require('child_process');
const http = require('http');
const fs = require('fs');
const path = require('path');

console.log('🧪 Comprehensive TwinSync Testing Suite');
console.log('=====================================\n');

let testResults = {
  build: false,
  vite: false,
  electron: false,
  rendererErrors: [],
  runtimeErrors: []
};

// Test 1: Build Process
async function testBuild() {
  console.log('1. Testing TypeScript build...');
  return new Promise((resolve) => {
    const build = spawn('npm', ['run', 'build:main'], { stdio: 'pipe' });
    let output = '';
    
    build.stdout.on('data', (data) => {
      output += data.toString();
    });
    
    build.stderr.on('data', (data) => {
      output += data.toString();
    });
    
    build.on('close', (code) => {
      if (code === 0) {
        console.log('✅ TypeScript build successful');
        testResults.build = true;
      } else {
        console.log('❌ TypeScript build failed');
        console.log('Build output:', output);
      }
      resolve();
    });
  });
}

// Test 2: Vite Dev Server
async function testVite() {
  console.log('\n2. Testing Vite dev server...');
  return new Promise((resolve) => {
    const vite = spawn('npm', ['run', 'dev'], { stdio: 'pipe' });
    let output = '';
    let resolved = false;
    
    vite.stdout.on('data', (data) => {
      output += data.toString();
      if (output.includes('Local:') && !resolved) {
        console.log('✅ Vite dev server started');
        testResults.vite = true;
        resolved = true;
        resolve();
      }
    });
    
    vite.stderr.on('data', (data) => {
      output += data.toString();
    });
    
    // Timeout after 10 seconds
    setTimeout(() => {
      if (!resolved) {
        console.log('❌ Vite dev server timeout');
        console.log('Vite output:', output);
        resolved = true;
        resolve();
      }
    }, 10000);
  });
}

// Test 3: Check for compiled files
async function testCompiledFiles() {
  console.log('\n3. Testing compiled files...');
  
  const distMain = path.join(__dirname, 'dist', 'main.js');
  const distMainIndex = path.join(__dirname, 'dist', 'main', 'index.js');
  
  if (fs.existsSync(distMain) && fs.existsSync(distMainIndex)) {
    console.log('✅ Compiled files exist');
    
    // Check if they use CommonJS syntax
    const mainContent = fs.readFileSync(distMain, 'utf8');
    if (mainContent.includes('require(') && !mainContent.includes('import ')) {
      console.log('✅ Main file uses CommonJS syntax');
    } else {
      console.log('❌ Main file does not use CommonJS syntax');
      console.log('First 200 chars:', mainContent.substring(0, 200));
    }
  } else {
    console.log('❌ Compiled files missing');
  }
}

// Test 4: Electron Process
async function testElectron() {
  console.log('\n4. Testing Electron process...');
  return new Promise((resolve) => {
    const electron = spawn('npm', ['run', 'electron:dev'], { stdio: 'pipe' });
    let output = '';
    let resolved = false;
    
    electron.stdout.on('data', (data) => {
      output += data.toString();
    });
    
    electron.stderr.on('data', (data) => {
      const error = data.toString();
      output += error;
      
      // Check for specific errors
      if (error.includes('ReferenceError') || error.includes('TypeError')) {
        testResults.runtimeErrors.push(error.trim());
      }
      
      if (error.includes('App threw an error')) {
        console.log('❌ Electron app threw an error');
        console.log('Error details:', error);
        if (!resolved) {
          resolved = true;
          resolve();
        }
      }
    });
    
    electron.on('close', (code) => {
      if (!resolved) {
        if (code === 0) {
          console.log('✅ Electron process completed successfully');
          testResults.electron = true;
        } else {
          console.log('❌ Electron process failed with code:', code);
        }
        resolved = true;
        resolve();
      }
    });
    
    // Timeout after 15 seconds
    setTimeout(() => {
      if (!resolved) {
        console.log('❌ Electron process timeout');
        console.log('Electron output:', output);
        resolved = true;
        resolve();
      }
    }, 15000);
  });
}

// Test 5: Check for common React/TypeScript errors
async function testCodeQuality() {
  console.log('\n5. Testing code quality...');
  
  const filesToCheck = [
    'src/renderer/App.tsx',
    'src/renderer/components/FilePane.tsx',
    'src/renderer/components/FilePanes.tsx',
    'src/renderer/components/ConnectionBar.tsx',
    'src/renderer/components/TransferPanel.tsx',
    'src/renderer/components/LogsDrawer.tsx',
    'src/renderer/components/SettingsModal.tsx',
    'src/renderer/components/ProfileModal.tsx'
  ];
  
  let errors = [];
  
  for (const file of filesToCheck) {
    const filePath = path.join(__dirname, file);
    if (fs.existsSync(filePath)) {
      const content = fs.readFileSync(filePath, 'utf8');
      
      // Check for common issues
      if (content.includes('dragEvent') && !content.includes('React.DragEvent')) {
        errors.push(`${file}: dragEvent used without proper typing`);
      }
      
      if (content.includes('selectedLocalFiles.includes') && !content.includes('selectedLocalFiles?.includes')) {
        errors.push(`${file}: selectedLocalFiles used without optional chaining`);
      }
      
      if (content.includes('selectedRemoteFiles.includes') && !content.includes('selectedRemoteFiles?.includes')) {
        errors.push(`${file}: selectedRemoteFiles used without optional chaining`);
      }
      
      if (content.includes('any') && content.includes('event: any')) {
        errors.push(`${file}: event parameter has 'any' type`);
      }
    }
  }
  
  if (errors.length === 0) {
    console.log('✅ Code quality checks passed');
  } else {
    console.log('❌ Code quality issues found:');
    errors.forEach(error => console.log('  -', error));
  }
  
  return errors;
}

// Test 6: Check package.json configuration
async function testPackageConfig() {
  console.log('\n6. Testing package.json configuration...');
  
  const packagePath = path.join(__dirname, 'package.json');
  if (fs.existsSync(packagePath)) {
    const packageJson = JSON.parse(fs.readFileSync(packagePath, 'utf8'));
    
    if (packageJson.main === 'dist/main.js') {
      console.log('✅ Main entry point correctly set');
    } else {
      console.log('❌ Main entry point incorrect:', packageJson.main);
    }
    
    if (packageJson.scripts && packageJson.scripts['build:main']) {
      console.log('✅ Build script exists');
    } else {
      console.log('❌ Build script missing');
    }
  }
}

// Run all tests
async function runAllTests() {
  try {
    await testBuild();
    await testCompiledFiles();
    await testPackageConfig();
    await testCodeQuality();
    
    // Start Vite in background
    const vite = spawn('npm', ['run', 'dev'], { stdio: 'pipe' });
    
    // Wait for Vite to start
    await new Promise(resolve => setTimeout(resolve, 3000));
    
    // Test Vite
    const viteResponse = await new Promise((resolve) => {
      const req = http.get('http://localhost:5173', (res) => {
        resolve(res.statusCode === 200);
      });
      req.on('error', () => resolve(false));
      req.setTimeout(5000, () => resolve(false));
    });
    
    if (viteResponse) {
      console.log('✅ Vite dev server responding');
      testResults.vite = true;
    } else {
      console.log('❌ Vite dev server not responding');
    }
    
    // Test Electron
    await testElectron();
    
  } catch (error) {
    console.log('❌ Test suite error:', error.message);
  }
  
  // Print final results
  console.log('\n📊 Test Results Summary');
  console.log('======================');
  console.log('Build Process:', testResults.build ? '✅ PASS' : '❌ FAIL');
  console.log('Vite Server:', testResults.vite ? '✅ PASS' : '❌ FAIL');
  console.log('Electron Process:', testResults.electron ? '✅ PASS' : '❌ FAIL');
  
  if (testResults.runtimeErrors.length > 0) {
    console.log('\n❌ Runtime Errors Found:');
    testResults.runtimeErrors.forEach((error, index) => {
      console.log(`${index + 1}. ${error}`);
    });
  }
  
  if (testResults.build && testResults.vite && testResults.electron && testResults.runtimeErrors.length === 0) {
    console.log('\n🎉 All tests passed! TwinSync is ready to use.');
  } else {
    console.log('\n⚠️  Some tests failed. Please fix the issues before using TwinSync.');
  }
  
  // Clean up
  process.exit(0);
}

runAllTests();
