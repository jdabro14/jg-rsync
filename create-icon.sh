#!/bin/bash

# Create a simple icon for JG-Rsync
# This creates a basic icon using macOS built-in tools

# Create a temporary directory for icon creation
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Create a simple icon using sips (macOS built-in tool)
# First, let's create a simple text-based icon
cat > icon.svg << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<svg width="512" height="512" viewBox="0 0 512 512" xmlns="http://www.w3.org/2000/svg">
  <rect width="512" height="512" fill="#2E3440" rx="80"/>
  <rect x="80" y="80" width="352" height="352" fill="#3B4252" rx="40"/>
  <text x="256" y="200" font-family="Arial, sans-serif" font-size="120" font-weight="bold" text-anchor="middle" fill="#88C0D0">JG</text>
  <text x="256" y="320" font-family="Arial, sans-serif" font-size="80" font-weight="bold" text-anchor="middle" fill="#88C0D0">rsync</text>
  <circle cx="256" cy="400" r="20" fill="#A3BE8C"/>
  <circle cx="200" cy="400" r="15" fill="#EBCB8B"/>
  <circle cx="312" cy="400" r="15" fill="#BF616A"/>
</svg>
EOF

# Convert SVG to PNG using rsvg-convert if available, otherwise use a simple approach
if command -v rsvg-convert &> /dev/null; then
    rsvg-convert -w 512 -h 512 icon.svg -o icon.png
elif command -v convert &> /dev/null; then
    convert icon.svg icon.png
else
    # Fallback: create a simple colored square
    sips -s format png -s dpiWidth 72 -s dpiHeight 72 -z 512 512 /System/Library/PrivateFrameworks/LoginUIKit.framework/Versions/A/Frameworks/LoginUICore.framework/Resources/apple_logo_black.png --out icon.png 2>/dev/null || {
        # If that fails, create a simple colored rectangle
        python3 -c "
import os
from PIL import Image, ImageDraw, ImageFont
img = Image.new('RGB', (512, 512), color='#2E3440')
draw = ImageDraw.Draw(img)
draw.rectangle([80, 80, 432, 432], fill='#3B4252')
try:
    font_large = ImageFont.truetype('/System/Library/Fonts/Arial.ttf', 120)
    font_small = ImageFont.truetype('/System/Library/Fonts/Arial.ttf', 80)
except:
    font_large = ImageFont.load_default()
    font_small = ImageFont.load_default()
draw.text((256, 150), 'JG', font=font_large, fill='#88C0D0', anchor='mm')
draw.text((256, 280), 'rsync', font=font_small, fill='#88C0D0', anchor='mm')
img.save('icon.png')
" 2>/dev/null || {
            # Final fallback: create a simple colored square
            sips -s format png -z 512 512 /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericApplicationIcon.icns --out icon.png
        }
    }
fi

# Create the .icns file
if [ -f icon.png ]; then
    # Create iconset directory
    mkdir -p icon.iconset
    
    # Generate different sizes
    sips -z 16 16 icon.png --out icon.iconset/icon_16x16.png
    sips -z 32 32 icon.png --out icon.iconset/icon_16x16@2x.png
    sips -z 32 32 icon.png --out icon.iconset/icon_32x32.png
    sips -z 64 64 icon.png --out icon.iconset/icon_32x32@2x.png
    sips -z 128 128 icon.png --out icon.iconset/icon_128x128.png
    sips -z 256 256 icon.png --out icon.iconset/icon_128x128@2x.png
    sips -z 256 256 icon.png --out icon.iconset/icon_256x256.png
    sips -z 512 512 icon.png --out icon.iconset/icon_256x256@2x.png
    sips -z 512 512 icon.png --out icon.iconset/icon_512x512.png
    sips -z 1024 1024 icon.png --out icon.iconset/icon_512x512@2x.png
    
    # Create the .icns file
    iconutil -c icns icon.iconset -o icon.icns
    
    # Copy to the app bundle
    cp icon.icns "$OLDPWD/JG-Rsync.app/Contents/Resources/"
    
    echo "Icon created successfully!"
else
    echo "Failed to create icon, using default"
fi

# Clean up
cd "$OLDPWD"
rm -rf "$TEMP_DIR"
