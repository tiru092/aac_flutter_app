#!/usr/bin/env python3
"""
Python script to generate app store assets for the AAC Communication Helper app.
This script generates all required assets without requiring ImageMagick.
"""

import os
from PIL import Image, ImageDraw, ImageFont

def create_directory_structure():
    """Create the directory structure for assets."""
    directories = [
        "assets_store/icons/android",
        "assets_store/icons/ios", 
        "assets_store/icons/web",
        "assets_store/splashscreens/mobile",
        "assets_store/splashscreens/tablet",
        "assets_store/promotional/screenshots",
        "assets_store/promotional/feature_graphics",
        "assets_store/promotional/marketing"
    ]
    
    for directory in directories:
        os.makedirs(directory, exist_ok=True)
        print(f"Created directory: {directory}")

def create_app_icon(size, filename, color_scheme=None):
    """Create a simple app icon with the specified size."""
    if color_scheme is None:
        color_scheme = {
            'background': (78, 205, 196),  # #4ECDC4 teal
            'accent': (255, 107, 107),     # #FF6B6B coral
            'highlight': (69, 183, 209),   # #45B7D1 blue
            'text': (255, 255, 255)        # white
        }
    
    # Create image
    img = Image.new('RGBA', (size, size), color_scheme['background'])
    draw = ImageDraw.Draw(img)
    
    # Draw a circle for the background
    circle_margin = size // 8
    draw.ellipse([circle_margin, circle_margin, size - circle_margin, size - circle_margin], 
                 fill=color_scheme['background'])
    
    # Draw a speech bubble
    bubble_size = size // 2
    bubble_margin = (size - bubble_size) // 2
    draw.rectangle([bubble_margin, bubble_margin + bubble_size//4, 
                    bubble_margin + bubble_size, bubble_margin + bubble_size*3//4], 
                   fill=color_scheme['text'], outline=None)
    
    # Draw a heart
    heart_size = size // 4
    heart_margin_x = (size - heart_size) // 2
    heart_margin_y = bubble_margin + bubble_size//8
    
    # Simple heart shape
    points = [
        (heart_margin_x, heart_margin_y + heart_size//3),
        (heart_margin_x + heart_size//4, heart_margin_y),
        (heart_margin_x + heart_size//2, heart_margin_y + heart_size//4),
        (heart_margin_x + heart_size*3//4, heart_margin_y),
        (heart_margin_x + heart_size, heart_margin_y + heart_size//3),
        (heart_margin_x + heart_size//2, heart_margin_y + heart_size)
    ]
    draw.polygon(points, fill=color_scheme['accent'])
    
    # Draw accessibility symbol
    circle_radius = size // 12
    circle_center = (size // 2, size // 2 + size // 6)
    draw.ellipse([circle_center[0] - circle_radius, circle_center[1] - circle_radius,
                  circle_center[0] + circle_radius, circle_center[1] + circle_radius],
                 fill=color_scheme['accent'], outline=color_scheme['text'], width=size//50)
    
    # Save image
    img.save(filename)
    print(f"Created icon: {filename}")

def create_splash_screen(width, height, filename, is_landscape=False):
    """Create a splash screen with the specified dimensions."""
    color_scheme = {
        'background': (78, 205, 196),  # #4ECDC4 teal
        'accent': (255, 107, 107),     # #FF6B6B coral
        'text': (255, 255, 255)        # white
    }
    
    # Create image
    img = Image.new('RGBA', (width, height), color_scheme['background'])
    draw = ImageDraw.Draw(img)
    
    # Add app name
    try:
        # Try to use a system font
        font = ImageFont.truetype("arial.ttf", min(width, height) // 15)
    except:
        # Fallback to default font
        font = ImageFont.load_default()
    
    app_name = "AAC Communication Helper"
    text_width = draw.textlength(app_name, font=font)
    text_x = (width - text_width) // 2
    text_y = height // 6
    
    draw.text((text_x, text_y), app_name, fill=color_scheme['text'], font=font)
    
    # Draw app icon in the center
    icon_size = min(width, height) // 4
    icon_margin_x = (width - icon_size) // 2
    icon_margin_y = height // 3
    
    # Draw icon background circle
    draw.ellipse([icon_margin_x, icon_margin_y, 
                  icon_margin_x + icon_size, icon_margin_y + icon_size], 
                 fill=color_scheme['text'])
    
    # Draw speech bubble
    bubble_size = icon_size // 2
    bubble_margin_x = icon_margin_x + (icon_size - bubble_size) // 2
    bubble_margin_y = icon_margin_y + (icon_size - bubble_size) // 2 + icon_size // 8
    draw.rectangle([bubble_margin_x, bubble_margin_y, 
                    bubble_margin_x + bubble_size, bubble_margin_y + bubble_size // 2], 
                   fill=color_scheme['background'])
    
    # Draw heart
    heart_size = icon_size // 4
    heart_margin_x = icon_margin_x + (icon_size - heart_size) // 2
    heart_margin_y = icon_margin_y + icon_size // 6
    
    points = [
        (heart_margin_x, heart_margin_y + heart_size//3),
        (heart_margin_x + heart_size//4, heart_margin_y),
        (heart_margin_x + heart_size//2, heart_margin_y + heart_size//4),
        (heart_margin_x + heart_size*3//4, heart_margin_y),
        (heart_margin_x + heart_size, heart_margin_y + heart_size//3),
        (heart_margin_x + heart_size//2, heart_margin_y + heart_size)
    ]
    draw.polygon(points, fill=color_scheme['accent'])
    
    # Add tagline
    tagline = "Empowering Communication for All"
    try:
        tagline_font = ImageFont.truetype("arial.ttf", min(width, height) // 25)
    except:
        tagline_font = ImageFont.load_default()
    
    tagline_width = draw.textlength(tagline, font=tagline_font)
    tagline_x = (width - tagline_width) // 2
    tagline_y = height * 2 // 3
    
    draw.text((tagline_x, tagline_y), tagline, fill=color_scheme['text'], font=tagline_font)
    
    # Save image
    img.save(filename)
    print(f"Created splash screen: {filename}")

def create_screenshot(width, height, filename, content):
    """Create a placeholder screenshot."""
    color_scheme = {
        'background': (78, 205, 196),  # #4ECDC4 teal
        'accent1': (255, 107, 107),    # #FF6B6B coral
        'accent2': (69, 183, 209),     # #45B7D1 blue
        'accent3': (150, 206, 180),    # #96CEB4 green
        'accent4': (254, 202, 87),     # #FECA57 yellow
        'text': (255, 255, 255)        # white
    }
    
    # Create image
    img = Image.new('RGBA', (width, height), color_scheme['background'])
    draw = ImageDraw.Draw(img)
    
    # Add content text
    try:
        font = ImageFont.truetype("arial.ttf", min(width, height) // 20)
    except:
        font = ImageFont.load_default()
    
    # Split content by newlines
    lines = content.split('\n')
    line_height = min(width, height) // 15
    
    for i, line in enumerate(lines):
        text_width = draw.textlength(line, font=font)
        text_x = (width - text_width) // 2
        text_y = height // 2 - (len(lines) * line_height // 2) + i * line_height
        draw.text((text_x, text_y), line, fill=color_scheme['text'], font=font)
    
    # Save image
    img.save(filename)
    print(f"Created screenshot: {filename}")

def create_feature_graphic(width, height, filename, platform):
    """Create a feature graphic for app stores."""
    color_scheme = {
        'background': (78, 205, 196),  # #4ECDC4 teal
        'text': (255, 255, 255)        # white
    }
    
    # Create image
    img = Image.new('RGBA', (width, height), color_scheme['background'])
    draw = ImageDraw.Draw(img)
    
    # Add platform-specific text
    try:
        font = ImageFont.truetype("arial.ttf", min(width, height) // 15)
    except:
        font = ImageFont.load_default()
    
    if "Google" in platform:
        text = "Google Play Feature Graphic"
    else:
        text = "App Store Feature Graphic"
    
    text_width = draw.textlength(text, font=font)
    text_x = (width - text_width) // 2
    text_y = (height - min(width, height) // 15) // 2
    
    draw.text((text_x, text_y), text, fill=color_scheme['text'], font=font)
    
    # Save image
    img.save(filename)
    print(f"Created feature graphic: {filename}")

def create_marketing_asset(width, height, filename, asset_type):
    """Create a marketing asset."""
    color_scheme = {
        'background': (78, 205, 196),  # #4ECDC4 teal
        'text': (255, 255, 255)        # white
    }
    
    # Create image
    img = Image.new('RGBA', (width, height), color_scheme['background'])
    draw = ImageDraw.Draw(img)
    
    # Add asset type text
    try:
        font = ImageFont.truetype("arial.ttf", min(width, height) // 15)
    except:
        font = ImageFont.load_default()
    
    text = asset_type.replace('_', ' ').title()
    text_width = draw.textlength(text, font=font)
    text_x = (width - text_width) // 2
    text_y = (height - min(width, height) // 15) // 2
    
    draw.text((text_x, text_y), text, fill=color_scheme['text'], font=font)
    
    # Save image
    img.save(filename)
    print(f"Created marketing asset: {filename}")

def generate_android_icons():
    """Generate all Android icons."""
    android_sizes = {
        36: "assets_store/icons/android/android_icon_36dp.png",
        48: "assets_store/icons/android/android_icon_48dp.png",
        72: "assets_store/icons/android/android_icon_72dp.png",
        96: "assets_store/icons/android/android_icon_96dp.png",
        144: "assets_store/icons/android/android_icon_144dp.png",
        192: "assets_store/icons/android/android_icon_192dp.png"
    }
    
    for size, filename in android_sizes.items():
        create_app_icon(size, filename)

def generate_ios_icons():
    """Generate all iOS icons."""
    ios_sizes = {
        40: "assets_store/icons/ios/ios_icon_20x20@2x.png",
        60: "assets_store/icons/ios/ios_icon_20x20@3x.png",
        58: "assets_store/icons/ios/ios_icon_29x29@2x.png",
        87: "assets_store/icons/ios/ios_icon_29x29@3x.png",
        80: "assets_store/icons/ios/ios_icon_40x40@2x.png",
        120: "assets_store/icons/ios/ios_icon_40x40@3x.png",
        120: "assets_store/icons/ios/ios_icon_60x60@2x.png",
        180: "assets_store/icons/ios/ios_icon_60x60@3x.png",
        152: "assets_store/icons/ios/ios_icon_76x76@2x.png",
        167: "assets_store/icons/ios/ios_icon_83.5x83.5@2x.png",
        1024: "assets_store/icons/ios/ios_icon_1024x1024.png"
    }
    
    for size, filename in ios_sizes.items():
        create_app_icon(size, filename)

def generate_web_icons():
    """Generate all web icons."""
    web_sizes = {
        16: "assets_store/icons/web/web_icon_16x16.png",
        32: "assets_store/icons/web/web_icon_32x32.png",
        192: "assets_store/icons/web/web_icon_192x192.png",
        512: "assets_store/icons/web/web_icon_512x512.png"
    }
    
    for size, filename in web_sizes.items():
        create_app_icon(size, filename)

def generate_mobile_splash_screens():
    """Generate all mobile splash screens."""
    mobile_sizes = {
        (640, 1136): "assets_store/splashscreens/mobile/splash_mobile_640x1136.png",
        (750, 1334): "assets_store/splashscreens/mobile/splash_mobile_750x1334.png",
        (1125, 2436): "assets_store/splashscreens/mobile/splash_mobile_1125x2436.png",
        (1242, 2688): "assets_store/splashscreens/mobile/splash_mobile_1242x2688.png",
        (828, 1792): "assets_store/splashscreens/mobile/splash_mobile_828x1792.png",
        (1080, 1920): "assets_store/splashscreens/mobile/splash_mobile_1080x1920.png"
    }
    
    for (width, height), filename in mobile_sizes.items():
        create_splash_screen(width, height, filename)

def generate_tablet_splash_screens():
    """Generate all tablet splash screens."""
    tablet_sizes = {
        (1536, 2048): "assets_store/splashscreens/tablet/splash_tablet_1536x2048.png",
        (1668, 2224): "assets_store/splashscreens/tablet/splash_tablet_1668x2224.png",
        (1668, 2388): "assets_store/splashscreens/tablet/splash_tablet_1668x2388.png",
        (2048, 2732): "assets_store/splashscreens/tablet/splash_tablet_2048x2732.png"
    }
    
    for (width, height), filename in tablet_sizes.items():
        create_splash_screen(width, height, filename)

def generate_screenshots():
    """Generate all screenshots."""
    screenshot_sizes = {
        (1080, 1920): [
            ("assets_store/promotional/screenshots/screenshot_1.png", "Screenshot 1\nMain Communication Grid"),
            ("assets_store/promotional/screenshots/screenshot_2.png", "Screenshot 2\nSymbol Customization"),
            ("assets_store/promotional/screenshots/screenshot_3.png", "Screenshot 3\nCategory Management"),
            ("assets_store/promotional/screenshots/screenshot_4.png", "Screenshot 4\nSettings and Preferences"),
            ("assets_store/promotional/screenshots/screenshot_5.png", "Screenshot 5\nProfile Selection")
        ]
    }
    
    for (width, height), screenshots in screenshot_sizes.items():
        for filename, content in screenshots:
            create_screenshot(width, height, filename, content)

def generate_feature_graphics():
    """Generate all feature graphics."""
    feature_graphics = {
        (1024, 500): ("assets_store/promotional/feature_graphics/feature_graphic_1024x500.png", "Google Play"),
        (1200, 630): ("assets_store/promotional/feature_graphics/feature_graphic_1200x630.png", "App Store")
    }
    
    for (width, height), (filename, platform) in feature_graphics.items():
        create_feature_graphic(width, height, filename, platform)

def generate_marketing_assets():
    """Generate all marketing assets."""
    marketing_assets = {
        (400, 150): "assets_store/promotional/marketing/logo_horizontal.png",
        (150, 400): "assets_store/promotional/marketing/logo_vertical.png",
        (150, 150): "assets_store/promotional/marketing/logo_icon.png",
        (1200, 600): "assets_store/promotional/marketing/banner_1200x600.png",
        (1080, 1080): "assets_store/promotional/marketing/social_media_1080x1080.png"
    }
    
    for (width, height), filename in marketing_assets.items():
        asset_type = filename.split('/')[-1].replace('.png', '')
        create_marketing_asset(width, height, filename, asset_type)

def main():
    """Main function to generate all assets."""
    print("Generating App Store Assets for AAC Communication Helper")
    print("=" * 54)
    
    # Check if Pillow is installed
    try:
        from PIL import Image, ImageDraw, ImageFont
    except ImportError:
        print("Error: Pillow is not installed")
        print("Please install Pillow using: pip install Pillow")
        return
    
    # Create directory structure
    create_directory_structure()
    
    # Generate all assets
    print("\nGenerating Android Icons...")
    generate_android_icons()
    
    print("\nGenerating iOS Icons...")
    generate_ios_icons()
    
    print("\nGenerating Web Icons...")
    generate_web_icons()
    
    print("\nGenerating Mobile Splash Screens...")
    generate_mobile_splash_screens()
    
    print("\nGenerating Tablet Splash Screens...")
    generate_tablet_splash_screens()
    
    print("\nGenerating Screenshots...")
    generate_screenshots()
    
    print("\nGenerating Feature Graphics...")
    generate_feature_graphics()
    
    print("\nGenerating Marketing Assets...")
    generate_marketing_assets()
    
    print("\n" + "=" * 54)
    print("All assets generated successfully!")
    print("=" * 54)
    print("\nNext steps:")
    print("1. Review all generated assets in the assets_store directory")
    print("2. Replace placeholder screenshots with actual app screenshots")
    print("3. Optimize images for file size if needed")
    print("4. Verify all assets meet store requirements")

if __name__ == "__main__":
    main()