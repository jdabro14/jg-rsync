#!/usr/bin/env node

const { spawn } = require('child_process');
const http = require('http');

console.log('🔍 TwinSync Runtime Error Detection');
console.log('==================================\n');

let electronProcess;
let viteProcess;
let errors = [];
let warnings = [];

function startVite() {
  return new Promise((resolve, reject) => {
    console.log('Starting Vite dev server...');
    viteProcess = spawn('npm', ['run', 'dev'], { stdio: 'pipe' });
    
    let output = '';
    let resolved = false;
    
    viteProcess.stdout.on('data', (data) => {
      output += data.toString();
      if (output.includes('Local:') && !resolved) {
        console.log('✅ Vite started successfully');
        resolved = true;
        resolve();
      }
    });
    
    viteProcess.stderr.on('data', (data) => {
      const error = data.toString();
      output += error;
      if (error.includes('error') || error.includes('Error')) {
        errors.push(`Vite: ${error.trim()}`);
      }
    });
    
    setTimeout(() => {
      if (!resolved) {
        console.log('❌ Vite startup timeout');
        reject(new Error('Vite timeout'));
      }
    }, 10000);
  });
}

function startElectron() {
  return new Promise((resolve, reject) => {
    console.log('Starting Electron...');
    electronProcess = spawn('npm', ['run', 'electron:dev'], { stdio: 'pipe' });
    
    let output = '';
    let resolved = false;
    
    electronProcess.stdout.on('data', (data) => {
      output += data.toString();
    });
    
    electronProcess.stderr.on('data', (data) => {
      const error = data.toString();
      output += error;
      
      // Check for specific error patterns
      if (error.includes('ReferenceError') || 
          error.includes('TypeError') || 
          error.includes('SyntaxError') ||
          error.includes('Error:') ||
          error.includes('Uncaught Exception')) {
        errors.push(`Electron: ${error.trim()}`);
      }
      
      if (error.includes('Warning:') || error.includes('warning')) {
        warnings.push(`Electron: ${error.trim()}`);
      }
      
      if (error.includes('App threw an error')) {
        console.log('❌ Electron app threw an error');
        console.log('Error details:', error);
        if (!resolved) {
          resolved = true;
          reject(new Error('Electron error'));
        }
      }
    });
    
    electronProcess.on('close', (code) => {
      if (!resolved) {
        if (code === 0) {
          console.log('✅ Electron completed successfully');
        } else {
          console.log(`❌ Electron exited with code ${code}`);
        }
        resolved = true;
        resolve();
      }
    });
    
    // Give Electron time to start and potentially show errors
    setTimeout(() => {
      if (!resolved) {
        console.log('✅ Electron started (monitoring for errors)');
        resolved = true;
        resolve();
      }
    }, 5000);
  });
}

function testViteResponse() {
  return new Promise((resolve) => {
    console.log('Testing Vite response...');
    const req = http.get('http://localhost:5173', (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        if (res.statusCode === 200) {
          console.log('✅ Vite responding correctly');
          resolve(true);
        } else {
          console.log(`❌ Vite returned status ${res.statusCode}`);
          resolve(false);
        }
      });
    });
    
    req.on('error', (err) => {
      console.log('❌ Vite request failed:', err.message);
      resolve(false);
    });
    
    req.setTimeout(5000, () => {
      console.log('❌ Vite request timeout');
      resolve(false);
    });
  });
}

async function runRuntimeTest() {
  try {
    // Start Vite
    await startVite();
    
    // Test Vite response
    await testViteResponse();
    
    // Start Electron and monitor for errors
    await startElectron();
    
    // Monitor for additional errors for a few more seconds
    console.log('Monitoring for additional errors...');
    await new Promise(resolve => setTimeout(resolve, 3000));
    
  } catch (error) {
    console.log('❌ Runtime test failed:', error.message);
  } finally {
    // Clean up processes
    if (electronProcess) {
      electronProcess.kill();
    }
    if (viteProcess) {
      viteProcess.kill();
    }
  }
  
  // Print results
  console.log('\n📊 Runtime Test Results');
  console.log('=======================');
  
  if (errors.length === 0) {
    console.log('✅ No runtime errors detected');
  } else {
    console.log('❌ Runtime errors found:');
    errors.forEach((error, index) => {
      console.log(`${index + 1}. ${error}`);
    });
  }
  
  if (warnings.length > 0) {
    console.log('\n⚠️  Warnings detected:');
    warnings.forEach((warning, index) => {
      console.log(`${index + 1}. ${warning}`);
    });
  }
  
  if (errors.length === 0) {
    console.log('\n🎉 TwinSync runtime test passed!');
  } else {
    console.log('\n⚠️  TwinSync has runtime errors that need to be fixed.');
  }
  
  process.exit(errors.length > 0 ? 1 : 0);
}

runRuntimeTest();
