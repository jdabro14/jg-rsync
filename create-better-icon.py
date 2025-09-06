#!/usr/bin/env python3

import os
import subprocess
import sys

def create_icon():
    """Create a better JG-Rsync icon"""
    
    # Try to use PIL if available
    try:
        from PIL import Image, ImageDraw, ImageFont
        
        print("🎨 Creating custom JG-Rsync icon with PIL...")
        
        # Create a 512x512 image
        size = 512
        img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        # Create a modern gradient background
        for y in range(size):
            # Blue gradient from top to bottom
            color = (int(30 + (y / size) * 50), int(60 + (y / size) * 100), int(120 + (y / size) * 80), 255)
            draw.line([(0, y), (size, y)], fill=color)
        
        # Add a subtle border
        draw.rectangle([0, 0, size-1, size-1], outline=(255, 255, 255, 100), width=4)
        
        # Add "JG" text in the center
        try:
            # Try to use a system font
            font_large = ImageFont.truetype("/System/Library/Fonts/Arial Bold.ttf", 140)
            font_small = ImageFont.truetype("/System/Library/Fonts/Arial.ttf", 80)
        except:
            # Fallback to default font
            font_large = ImageFont.load_default()
            font_small = ImageFont.load_default()
        
        # Draw "JG" text
        text_jg = "JG"
        bbox = draw.textbbox((0, 0), text_jg, font=font_large)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]
        x = (size - text_width) // 2
        y = (size - text_height) // 2 - 40
        draw.text((x, y), text_jg, font=font_large, fill=(255, 255, 255, 255))
        
        # Draw "Rsync" text below
        text_rsync = "Rsync"
        bbox = draw.textbbox((0, 0), text_rsync, font=font_small)
        text_width = bbox[2] - bbox[0]
        x = (size - text_width) // 2
        y = (size - text_height) // 2 + 60
        draw.text((x, y), text_rsync, font=font_small, fill=(255, 255, 255, 200))
        
        # Add transfer arrows
        arrow_color = (255, 255, 255, 180)
        arrow_size = 30
        
        # Left to right arrow
        left_x = size // 2 - 80
        right_x = size // 2 + 80
        center_y = size // 2 + 120
        
        # Arrow body
        draw.line([(left_x, center_y), (right_x - arrow_size, center_y)], fill=arrow_color, width=6)
        # Arrow head
        draw.polygon([
            (right_x - arrow_size, center_y - 15),
            (right_x, center_y),
            (right_x - arrow_size, center_y + 15)
        ], fill=arrow_color)
        
        # Right to left arrow
        center_y = size // 2 - 120
        draw.line([(right_x, center_y), (left_x + arrow_size, center_y)], fill=arrow_color, width=6)
        draw.polygon([
            (left_x + arrow_size, center_y - 15),
            (left_x, center_y),
            (left_x + arrow_size, center_y + 15)
        ], fill=arrow_color)
        
        # Save the image
        output_path = "JG-Rsync.app/Contents/Resources/icon.png"
        img.save(output_path)
        print(f"✅ Custom icon saved to {output_path}")
        
    except ImportError:
        print("⚠️  PIL not available, using fallback method...")
        create_fallback_icon()
    except Exception as e:
        print(f"❌ Error creating icon with PIL: {e}")
        create_fallback_icon()

def create_fallback_icon():
    """Create a simple icon using system tools"""
    print("🎨 Creating fallback icon...")
    
    # Use a network icon as base
    base_icon = "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericNetworkIcon.icns"
    if not os.path.exists(base_icon):
        base_icon = "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericApplicationIcon.icns"
    
    # Convert to PNG
    temp_png = "/tmp/jg_rsync_icon.png"
    subprocess.run([
        "sips", "-s", "format", "png", "-z", "512", "512", 
        base_icon, "--out", temp_png
    ], check=True)
    
    # Copy to app bundle
    output_path = "JG-Rsync.app/Contents/Resources/icon.png"
    subprocess.run(["cp", temp_png, output_path], check=True)
    subprocess.run(["rm", temp_png], check=True)
    
    print(f"✅ Fallback icon saved to {output_path}")

def create_iconset():
    """Create the .icns file from the PNG"""
    print("🔧 Creating .icns file...")
    
    iconset_dir = "temp-icon.iconset"
    os.makedirs(iconset_dir, exist_ok=True)
    
    # Create different sizes
    sizes = [16, 32, 128, 256, 512]
    for size in sizes:
        # Standard size
        subprocess.run([
            "sips", "-z", str(size), str(size), 
            "JG-Rsync.app/Contents/Resources/icon.png",
            "--out", os.path.join(iconset_dir, f"icon_{size}x{size}.png")
        ], check=True)
        
        # Retina size
        subprocess.run([
            "sips", "-z", str(size*2), str(size*2),
            "JG-Rsync.app/Contents/Resources/icon.png", 
            "--out", os.path.join(iconset_dir, f"icon_{size}x{size}@2x.png")
        ], check=True)
    
    # Create .icns file
    subprocess.run([
        "iconutil", "-c", "icns", iconset_dir, 
        "-o", "JG-Rsync.app/Contents/Resources/icon.icns"
    ], check=True)
    
    # Clean up
    subprocess.run(["rm", "-rf", iconset_dir], check=True)
    subprocess.run(["rm", "JG-Rsync.app/Contents/Resources/icon.png"], check=True)
    
    print("✅ .icns file created successfully!")

if __name__ == "__main__":
    create_icon()
    create_iconset()
    print("🎉 Icon creation complete!")
