#!/usr/bin/env node

// Wait for Vite dev server to be ready
const http = require('http');

function checkPort(port) {
  return new Promise((resolve) => {
    const req = http.get(`http://localhost:${port}`, (res) => {
      resolve(true);
    });
    req.on('error', () => {
      resolve(false);
    });
    req.setTimeout(1000, () => {
      req.destroy();
      resolve(false);
    });
  });
}

async function waitForVite() {
  console.log('⏳ Waiting for Vite dev server...');
  
  while (true) {
    const port5173 = await checkPort(5173);
    const port5174 = await checkPort(5174);
    
    if (port5173) {
      console.log('✅ Vite ready on port 5173');
      process.exit(0);
    } else if (port5174) {
      console.log('✅ Vite ready on port 5174');
      process.exit(0);
    }
    
    await new Promise(resolve => setTimeout(resolve, 500));
  }
}

waitForVite().catch(console.error);
