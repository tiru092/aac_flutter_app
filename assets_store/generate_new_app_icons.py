#!/usr/bin/env python3
"""
Generate new app icons with the colorful figures design for AAC Communication Helper.
"""

import os
from PIL import Image, ImageDraw

def create_colorful_app_icon(size, filename):
    """Create the new app icon with colorful figures and play button."""
    
    # Create image with white background
    img = Image.new('RGBA', (size, size), (255, 255, 255, 255))
    draw = ImageDraw.Draw(img)
    
    # Define colors matching the new design
    colors = {
        'blue': (0, 149, 221),      # Blue figure
        'green': (139, 195, 74),    # Green figure  
        'orange': (255, 152, 0),    # Orange figure
        'purple': (156, 39, 176),   # Purple figure
        'teal': (0, 150, 136),      # Teal figure
        'play_button': (13, 71, 161), # Dark blue play button
        'white': (255, 255, 255)
    }
    
    center = size // 2
    figure_size = size // 8
    
    # Position figures around a circle
    import math
    positions = []
    for i in range(5):  # 5 figures
        angle = (i * 72 - 90) * math.pi / 180  # Start from top, 72 degrees apart
        x = center + int((size // 3) * math.cos(angle))
        y = center + int((size // 3) * math.sin(angle))
        positions.append((x, y))
    
    figure_colors = [colors['blue'], colors['teal'], colors['purple'], colors['green'], colors['orange']]
    
    # Draw figures (simplified human shapes)
    for i, ((x, y), color) in enumerate(zip(positions, figure_colors)):
        # Head
        head_radius = figure_size // 3
        draw.ellipse([x - head_radius, y - head_radius - figure_size//2, 
                     x + head_radius, y + head_radius - figure_size//2], fill=color)
        
        # Body (elongated oval)
        body_width = figure_size // 2
        body_height = figure_size
        draw.ellipse([x - body_width//2, y - figure_size//3, 
                     x + body_width//2, y + body_height - figure_size//3], fill=color)
        
        # Arms (extending outward)
        arm_length = figure_size // 2
        arm_width = figure_size // 6
        
        # Left arm
        arm_angle = -45 if i % 2 == 0 else -30
        arm_x = x + int(arm_length * math.cos(math.radians(arm_angle)))
        arm_y = y + int(arm_length * math.sin(math.radians(arm_angle)))
        draw.line([x - body_width//3, y, arm_x, arm_y], fill=color, width=arm_width)
        
        # Right arm  
        arm_angle = 45 if i % 2 == 0 else 30
        arm_x = x + int(arm_length * math.cos(math.radians(arm_angle)))
        arm_y = y + int(arm_length * math.sin(math.radians(arm_angle)))
        draw.line([x + body_width//3, y, arm_x, arm_y], fill=color, width=arm_width)
        
        # Legs
        leg_length = figure_size // 2
        leg_width = figure_size // 6
        
        # Left leg
        draw.line([x - body_width//4, y + body_height//2, 
                  x - body_width//2, y + body_height//2 + leg_length], 
                  fill=color, width=leg_width)
        
        # Right leg
        draw.line([x + body_width//4, y + body_height//2, 
                  x + body_width//2, y + body_height//2 + leg_length], 
                  fill=color, width=leg_width)
    
    # Draw central play button
    play_size = size // 4
    play_margin = (size - play_size) // 2
    
    # Play button circle background
    draw.ellipse([play_margin, play_margin, play_margin + play_size, play_margin + play_size], 
                fill=colors['play_button'])
    
    # Play triangle
    triangle_size = play_size // 2
    triangle_center_x = center + play_size // 12  # Slightly offset to look centered
    triangle_center_y = center
    triangle_height = triangle_size
    triangle_width = int(triangle_size * 0.866)  # For equilateral triangle
    
    triangle_points = [
        (triangle_center_x - triangle_width//2, triangle_center_y - triangle_height//2),
        (triangle_center_x - triangle_width//2, triangle_center_y + triangle_height//2),
        (triangle_center_x + triangle_width//2, triangle_center_y)
    ]
    draw.polygon(triangle_points, fill=colors['white'])
    
    # Save the image
    img.save(filename, "PNG")
    print(f"Created new app icon: {filename}")

def generate_all_app_icons():
    """Generate all required app icon sizes for different platforms."""
    
    # Create directories
    os.makedirs("assets_store/icons/android", exist_ok=True)
    os.makedirs("assets_store/icons/ios", exist_ok=True)
    os.makedirs("assets_store/icons/web", exist_ok=True)
    
    # Android icon sizes (mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
    android_sizes = [
        (48, "assets_store/icons/android/ic_launcher_48.png"),      # mdpi
        (72, "assets_store/icons/android/ic_launcher_72.png"),      # hdpi  
        (96, "assets_store/icons/android/ic_launcher_96.png"),      # xhdpi
        (144, "assets_store/icons/android/ic_launcher_144.png"),    # xxhdpi
        (192, "assets_store/icons/android/ic_launcher_192.png"),    # xxxhdpi
    ]
    
    # iOS icon sizes
    ios_sizes = [
        (40, "assets_store/icons/ios/Icon-40.png"),
        (58, "assets_store/icons/ios/Icon-58.png"),
        (60, "assets_store/icons/ios/Icon-60.png"),
        (80, "assets_store/icons/ios/Icon-80.png"),
        (87, "assets_store/icons/ios/Icon-87.png"),
        (120, "assets_store/icons/ios/Icon-120.png"),
        (152, "assets_store/icons/ios/Icon-152.png"),
        (167, "assets_store/icons/ios/Icon-167.png"),
        (180, "assets_store/icons/ios/Icon-180.png"),
        (1024, "assets_store/icons/ios/Icon-1024.png"),
    ]
    
    # Web icon sizes
    web_sizes = [
        (16, "assets_store/icons/web/icon-16.png"),
        (32, "assets_store/icons/web/icon-32.png"),
        (192, "assets_store/icons/web/icon-192.png"),
        (512, "assets_store/icons/web/icon-512.png"),
    ]
    
    print("Generating Android icons...")
    for size, filename in android_sizes:
        create_colorful_app_icon(size, filename)
    
    print("Generating iOS icons...")
    for size, filename in ios_sizes:
        create_colorful_app_icon(size, filename)
    
    print("Generating Web icons...")
    for size, filename in web_sizes:
        create_colorful_app_icon(size, filename)
    
    # Create master icon
    create_colorful_app_icon(1024, "assets_store/icons/app_icon_master.png")
    
    print("✅ All app icons generated successfully!")

if __name__ == "__main__":
    generate_all_app_icons()
