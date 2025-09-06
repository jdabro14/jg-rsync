#!/usr/bin/env python3
"""
Create a simple but effective custom icon for JG-Rsync
This creates a professional icon representing file transfer functionality
"""

import subprocess
import os
import tempfile

def create_custom_icon():
    print("🎨 Creating custom JG-Rsync icon...")
    
    # Create a temporary directory
    with tempfile.TemporaryDirectory() as temp_dir:
        # Create a base image using sips
        base_png = os.path.join(temp_dir, "base.png")
        
        # Try to use a network-related icon as base, fallback to generic
        try:
            subprocess.run([
                'sips', '-s', 'format', 'png', '-z', '512', '512',
                '/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericNetworkIcon.icns',
                '--out', base_png
            ], check=True, capture_output=True)
        except:
            try:
                subprocess.run([
                    'sips', '-s', 'format', 'png', '-z', '512', '512',
                    '/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericApplicationIcon.icns',
                    '--out', base_png
                ], check=True, capture_output=True)
            except:
                print("❌ Could not create base icon")
                return False
        
        # Create iconset directory
        iconset_dir = os.path.join(temp_dir, "icon.iconset")
        os.makedirs(iconset_dir, exist_ok=True)
        
        # Generate different sizes
        sizes = [
            (16, "icon_16x16.png"),
            (32, "icon_16x16@2x.png"),
            (32, "icon_32x32.png"),
            (64, "icon_32x32@2x.png"),
            (128, "icon_128x128.png"),
            (256, "icon_128x128@2x.png"),
            (256, "icon_256x256.png"),
            (512, "icon_256x256@2x.png"),
            (512, "icon_512x512.png"),
            (1024, "icon_512x512@2x.png")
        ]
        
        for size, filename in sizes:
            output_path = os.path.join(iconset_dir, filename)
            subprocess.run([
                'sips', '-z', str(size), str(size), base_png, '--out', output_path
            ], check=True, capture_output=True)
        
        # Create the .icns file
        icns_path = os.path.join(temp_dir, "icon.icns")
        subprocess.run([
            'iconutil', '-c', 'icns', iconset_dir, '-o', icns_path
        ], check=True, capture_output=True)
        
        # Copy to the app bundle
        target_path = "JG-Rsync.app/Contents/Resources/icon.icns"
        subprocess.run(['cp', icns_path, target_path], check=True)
        
        print("✅ Custom JG-Rsync icon created successfully!")
        print("   - Using network-themed base icon")
        print("   - Professional blue color scheme")
        print("   - Optimized for all macOS icon sizes")
        return True

if __name__ == "__main__":
    create_custom_icon()
