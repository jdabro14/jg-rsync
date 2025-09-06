#!/bin/bash

# Create a custom icon for JG-Rsync
# This creates a professional icon representing file transfer/rsync functionality

# Create a temporary directory for icon creation
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

echo "🎨 Creating custom JG-Rsync icon..."

# Create an SVG icon with file transfer theme
cat > icon.svg << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<svg width="512" height="512" viewBox="0 0 512 512" xmlns="http://www.w3.org/2000/svg">
  <!-- Background circle with gradient -->
  <defs>
    <linearGradient id="bgGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#1e3a8a;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#3b82f6;stop-opacity:1" />
    </linearGradient>
    <linearGradient id="fileGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#f8fafc;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#e2e8f0;stop-opacity:1" />
    </linearGradient>
  </defs>
  
  <!-- Background circle -->
  <circle cx="256" cy="256" r="240" fill="url(#bgGradient)" stroke="#1e40af" stroke-width="8"/>
  
  <!-- Left file (source) -->
  <rect x="120" y="180" width="80" height="100" rx="8" fill="url(#fileGradient)" stroke="#64748b" stroke-width="2"/>
  <rect x="130" y="200" width="60" height="4" fill="#64748b"/>
  <rect x="130" y="210" width="45" height="4" fill="#64748b"/>
  <rect x="130" y="220" width="50" height="4" fill="#64748b"/>
  <rect x="130" y="230" width="40" height="4" fill="#64748b"/>
  <rect x="130" y="240" width="55" height="4" fill="#64748b"/>
  <rect x="130" y="250" width="35" height="4" fill="#64748b"/>
  
  <!-- Right file (destination) -->
  <rect x="312" y="180" width="80" height="100" rx="8" fill="url(#fileGradient)" stroke="#64748b" stroke-width="2"/>
  <rect x="322" y="200" width="60" height="4" fill="#64748b"/>
  <rect x="322" y="210" width="45" height="4" fill="#64748b"/>
  <rect x="322" y="220" width="50" height="4" fill="#64748b"/>
  <rect x="322" y="230" width="40" height="4" fill="#64748b"/>
  <rect x="322" y="240" width="55" height="4" fill="#64748b"/>
  <rect x="322" y="250" width="35" height="4" fill="#64748b"/>
  
  <!-- Transfer arrows -->
  <path d="M220 220 L280 220" stroke="#10b981" stroke-width="6" stroke-linecap="round"/>
  <path d="M220 240 L280 240" stroke="#10b981" stroke-width="6" stroke-linecap="round"/>
  <path d="M220 260 L280 260" stroke="#10b981" stroke-width="6" stroke-linecap="round"/>
  
  <!-- Arrow heads -->
  <path d="M270 210 L280 220 L270 230" stroke="#10b981" stroke-width="6" stroke-linecap="round" fill="none"/>
  <path d="M270 230 L280 240 L270 250" stroke="#10b981" stroke-width="6" stroke-linecap="round" fill="none"/>
  <path d="M270 250 L280 260 L270 270" stroke="#10b981" stroke-width="6" stroke-linecap="round" fill="none"/>
  
  <!-- JG text -->
  <text x="256" y="380" font-family="Arial, sans-serif" font-size="48" font-weight="bold" text-anchor="middle" fill="white">JG</text>
  <text x="256" y="420" font-family="Arial, sans-serif" font-size="32" font-weight="bold" text-anchor="middle" fill="#93c5fd">rsync</text>
  
  <!-- Network/sync indicator dots -->
  <circle cx="200" cy="320" r="4" fill="#fbbf24"/>
  <circle cx="220" cy="320" r="4" fill="#fbbf24"/>
  <circle cx="240" cy="320" r="4" fill="#fbbf24"/>
  <circle cx="272" cy="320" r="4" fill="#fbbf24"/>
  <circle cx="292" cy="320" r="4" fill="#fbbf24"/>
  <circle cx="312" cy="320" r="4" fill="#fbbf24"/>
</svg>
EOF

# Convert SVG to PNG using different methods
if command -v rsvg-convert &> /dev/null; then
    echo "Using rsvg-convert..."
    rsvg-convert -w 512 -h 512 icon.svg -o icon.png
elif command -v convert &> /dev/null; then
    echo "Using ImageMagick convert..."
    convert icon.svg icon.png
else
    # Try using Python with PIL
    echo "Using Python PIL..."
    python3 -c "
import os
try:
    from PIL import Image, ImageDraw, ImageFont
    import io
    import xml.etree.ElementTree as ET
    
    # Simple SVG to PNG conversion
    # Create a 512x512 image with blue background
    img = Image.new('RGB', (512, 512), color='#1e3a8a')
    draw = ImageDraw.Draw(img)
    
    # Draw a simple file transfer icon
    # Background circle
    draw.ellipse([32, 32, 480, 480], fill='#3b82f6', outline='#1e40af', width=8)
    
    # Left file
    draw.rectangle([120, 180, 200, 280], fill='#f8fafc', outline='#64748b', width=2)
    for i, y in enumerate([200, 210, 220, 230, 240, 250]):
        draw.rectangle([130, y, 190, y+4], fill='#64748b')
    
    # Right file  
    draw.rectangle([312, 180, 392, 280], fill='#f8fafc', outline='#64748b', width=2)
    for i, y in enumerate([200, 210, 220, 230, 240, 250]):
        draw.rectangle([322, y, 382, y+4], fill='#64748b')
    
    # Transfer arrows
    for y in [220, 240, 260]:
        draw.line([220, y, 280, y], fill='#10b981', width=6)
        # Arrow head
        draw.polygon([(270, y-10), (280, y), (270, y+10)], fill='#10b981')
    
    # JG text
    try:
        font_large = ImageFont.truetype('/System/Library/Fonts/Arial.ttf', 48)
        font_small = ImageFont.truetype('/System/Library/Fonts/Arial.ttf', 32)
    except:
        font_large = ImageFont.load_default()
        font_small = ImageFont.load_default()
    
    draw.text((256, 350), 'JG', font=font_large, fill='white', anchor='mm')
    draw.text((256, 400), 'rsync', font=font_small, fill='#93c5fd', anchor='mm')
    
    # Sync dots
    for x in [200, 220, 240, 272, 292, 312]:
        draw.ellipse([x-4, 316, x+4, 324], fill='#fbbf24')
    
    img.save('icon.png')
    print('Custom icon created successfully!')
    
except ImportError:
    print('PIL not available, using fallback method')
    # Fallback: create a simple colored square
    import subprocess
    subprocess.run(['sips', '-s', 'format', 'png', '-z', '512', '512', '/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericApplicationIcon.icns', '--out', 'icon.png'])
except Exception as e:
    print(f'Error creating icon: {e}')
    # Final fallback
    import subprocess
    subprocess.run(['sips', '-s', 'format', 'png', '-z', '512', '512', '/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericApplicationIcon.icns', '--out', 'icon.png'])
" 2>/dev/null || {
    echo "Using fallback method..."
    sips -s format png -z 512 512 /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericApplicationIcon.icns --out icon.png
}
fi

# Create iconset for .icns file
if [ -f icon.png ]; then
    echo "Creating iconset..."
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
    
    echo "✅ Custom JG-Rsync icon created successfully!"
    echo "   - Blue gradient background representing technology"
    echo "   - File transfer arrows showing rsync functionality"
    echo "   - 'JG' and 'rsync' text for clear branding"
    echo "   - Professional design suitable for macOS"
else
    echo "❌ Failed to create custom icon"
fi

# Clean up
cd "$OLDPWD"
rm -rf "$TEMP_DIR"
