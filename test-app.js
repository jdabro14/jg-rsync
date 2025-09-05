#!/usr/bin/env node

// Simple test script to verify TwinSync is running
const http = require('http');

console.log('🧪 Testing TwinSync Application...\n');

// Test Vite dev server
const testVite = () => {
  return new Promise((resolve) => {
    const req = http.get('http://localhost:5173', (res) => {
      if (res.statusCode === 200) {
        console.log('✅ Vite dev server is running on http://localhost:5173');
        resolve(true);
      } else {
        console.log('❌ Vite dev server returned status:', res.statusCode);
        resolve(false);
      }
    });
    
    req.on('error', (err) => {
      console.log('❌ Vite dev server is not accessible:', err.message);
      resolve(false);
    });
    
    req.setTimeout(5000, () => {
      console.log('❌ Vite dev server timeout');
      resolve(false);
    });
  });
};

// Test Electron process
const testElectron = () => {
  const { exec } = require('child_process');
  
  return new Promise((resolve) => {
    exec('ps aux | grep -i electron | grep -v grep', (error, stdout) => {
      if (error) {
        console.log('❌ Error checking Electron process:', error.message);
        resolve(false);
        return;
      }
      
      if (stdout.trim()) {
        console.log('✅ Electron process is running');
        console.log('   Process info:', stdout.trim().split('\n')[0]);
        resolve(true);
      } else {
        console.log('❌ Electron process not found');
        resolve(false);
      }
    });
  });
};

// Run tests
async function runTests() {
  console.log('1. Testing Vite dev server...');
  const viteOk = await testVite();
  
  console.log('\n2. Testing Electron process...');
  const electronOk = await testElectron();
  
  console.log('\n📊 Test Results:');
  console.log('================');
  console.log(`Vite Dev Server: ${viteOk ? '✅ PASS' : '❌ FAIL'}`);
  console.log(`Electron Process: ${electronOk ? '✅ PASS' : '❌ FAIL'}`);
  
  if (viteOk && electronOk) {
    console.log('\n🎉 TwinSync is running successfully!');
    console.log('   You should see the TwinSync window open on your screen.');
    console.log('   If not, check the terminal for any error messages.');
  } else {
    console.log('\n⚠️  Some components are not running properly.');
    console.log('   Check the terminal output for error details.');
  }
  
  console.log('\n💡 To stop the application, press Ctrl+C in the terminal where you ran ./start.sh');
}

runTests().catch(console.error);
