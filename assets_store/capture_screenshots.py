#!/usr/bin/env python3
"""
Automated screenshot capture script for AAC Communication Helper.
This script helps capture screenshots for app store submission.
"""

import os
import time
import subprocess
from datetime import datetime

def create_screenshot_directories():
    """Create directory structure for screenshots."""
    directories = [
        "assets_store/promotional/screenshots/android/phone",
        "assets_store/promotional/screenshots/android/tablet", 
        "assets_store/promotional/screenshots/ios/iphone",
        "assets_store/promotional/screenshots/ios/ipad",
        "assets_store/promotional/feature_graphics"
    ]
    
    for directory in directories:
        os.makedirs(directory, exist_ok=True)
        print(f"📁 Created directory: {directory}")

def capture_android_screenshot(filename, device_id=None):
    """Capture screenshot from Android device/emulator."""
    try:
        # Get device ID if not provided
        if not device_id:
            result = subprocess.run(['adb', 'devices'], capture_output=True, text=True)
            lines = result.stdout.strip().split('\n')[1:]  # Skip header
            devices = [line.split()[0] for line in lines if 'device' in line]
            if not devices:
                print("❌ No Android devices found")
                return False
            device_id = devices[0]
        
        # Capture screenshot
        temp_path = "/sdcard/screenshot.png"
        local_path = f"assets_store/promotional/screenshots/android/phone/{filename}"
        
        # Take screenshot on device
        subprocess.run(['adb', '-s', device_id, 'shell', 'screencap', '-p', temp_path])
        
        # Pull screenshot to local machine
        subprocess.run(['adb', '-s', device_id, 'pull', temp_path, local_path])
        
        # Clean up device
        subprocess.run(['adb', '-s', device_id, 'shell', 'rm', temp_path])
        
        print(f"📸 Captured Android screenshot: {local_path}")
        return True
        
    except subprocess.CalledProcessError as e:
        print(f"❌ Error capturing Android screenshot: {e}")
        return False

def capture_ios_screenshot(filename, simulator_name="iPhone 14"):
    """Capture screenshot from iOS Simulator."""
    try:
        # Get simulator UUID
        result = subprocess.run(['xcrun', 'simctl', 'list', 'devices'], 
                              capture_output=True, text=True)
        
        # Parse simulator list to find the specified simulator
        lines = result.stdout.split('\n')
        simulator_uuid = None
        
        for line in lines:
            if simulator_name in line and '(Booted)' in line:
                # Extract UUID from line like: "iPhone 14 (UUID) (Booted)"
                start = line.find('(') + 1
                end = line.find(')', start)
                simulator_uuid = line[start:end]
                break
        
        if not simulator_uuid:
            print(f"❌ iOS Simulator '{simulator_name}' not found or not booted")
            return False
        
        # Capture screenshot
        local_path = f"assets_store/promotional/screenshots/ios/iphone/{filename}"
        subprocess.run(['xcrun', 'simctl', 'io', simulator_uuid, 'screenshot', local_path])
        
        print(f"📸 Captured iOS screenshot: {local_path}")
        return True
        
    except subprocess.CalledProcessError as e:
        print(f"❌ Error capturing iOS screenshot: {e}")
        return False

def interactive_screenshot_session():
    """Run an interactive session to capture screenshots."""
    print("🚀 AAC Communication Helper - Screenshot Capture Session")
    print("=" * 60)
    
    # Create directories
    create_screenshot_directories()
    
    print("\n📱 Choose platform:")
    print("1. Android")
    print("2. iOS Simulator")
    print("3. Both")
    
    choice = input("\nEnter choice (1-3): ").strip()
    
    # Define screenshot scenarios
    scenarios = [
        ("01_home_screen.png", "Home Screen with Communication Grid"),
        ("02_symbol_selection.png", "Symbol Selection in Action"),
        ("03_voice_features.png", "Voice/Audio Features"),
        ("04_personalization.png", "User Personalization"),
        ("05_practice_mode.png", "Learning/Practice Mode"),
        ("06_accessibility.png", "Accessibility Features"),
        ("07_favorites.png", "Favorites and Quick Access"),
        ("08_settings.png", "Settings and Configuration")
    ]
    
    if choice in ['1', '3']:  # Android
        print("\n📱 Starting Android screenshot capture...")
        print("Make sure your Android device/emulator is connected and the app is running.")
        input("Press Enter when ready...")
        
        for filename, description in scenarios:
            print(f"\n📸 Next screenshot: {description}")
            print("Navigate to the appropriate screen in your app.")
            input("Press Enter to capture screenshot...")
            
            if capture_android_screenshot(filename):
                print(f"✅ Captured: {filename}")
            else:
                print(f"❌ Failed to capture: {filename}")
            
            time.sleep(1)  # Brief pause between captures
    
    if choice in ['2', '3']:  # iOS
        print("\n📱 Starting iOS screenshot capture...")
        print("Make sure your iOS Simulator is running with the app open.")
        
        simulator_name = input("Enter simulator name (default: iPhone 14): ").strip()
        if not simulator_name:
            simulator_name = "iPhone 14"
        
        input("Press Enter when ready...")
        
        for filename, description in scenarios:
            print(f"\n📸 Next screenshot: {description}")
            print("Navigate to the appropriate screen in your app.")
            input("Press Enter to capture screenshot...")
            
            if capture_ios_screenshot(filename, simulator_name):
                print(f"✅ Captured: {filename}")
            else:
                print(f"❌ Failed to capture: {filename}")
            
            time.sleep(1)  # Brief pause between captures

def create_feature_graphic():
    """Create a feature graphic for Google Play Store."""
    try:
        from PIL import Image, ImageDraw, ImageFont
        
        # Create feature graphic (1024 x 500)
        img = Image.new('RGB', (1024, 500), color=(78, 205, 196))  # Teal background
        draw = ImageDraw.Draw(img)
        
        # Add app title
        try:
            font_large = ImageFont.truetype("arial.ttf", 48)
            font_medium = ImageFont.truetype("arial.ttf", 24)
        except:
            font_large = ImageFont.load_default()
            font_medium = ImageFont.load_default()
        
        # Title
        title = "AAC Communication Helper"
        subtitle = "Empowering Communication Through Technology"
        
        # Center the text
        title_bbox = draw.textbbox((0, 0), title, font=font_large)
        title_width = title_bbox[2] - title_bbox[0]
        title_x = (1024 - title_width) // 2
        
        subtitle_bbox = draw.textbbox((0, 0), subtitle, font=font_medium)
        subtitle_width = subtitle_bbox[2] - subtitle_bbox[0]
        subtitle_x = (1024 - subtitle_width) // 2
        
        # Draw text with shadow effect
        draw.text((title_x + 2, 152), title, fill=(0, 0, 0, 128), font=font_large)  # Shadow
        draw.text((title_x, 150), title, fill=(255, 255, 255), font=font_large)  # Main text
        
        draw.text((subtitle_x + 2, 222), subtitle, fill=(0, 0, 0, 128), font=font_medium)  # Shadow
        draw.text((subtitle_x, 220), subtitle, fill=(255, 255, 255), font=font_medium)  # Main text
        
        # Add decorative elements (simple shapes representing communication)
        # Speech bubbles
        for i, color in enumerate([(255, 107, 107), (69, 183, 209), (255, 193, 7)]):
            x = 100 + i * 250
            y = 300
            draw.ellipse([x, y, x + 80, y + 50], fill=color)
        
        # Save feature graphic
        feature_path = "assets_store/promotional/feature_graphics/feature_graphic.png"
        img.save(feature_path)
        print(f"🎨 Created feature graphic: {feature_path}")
        
    except ImportError:
        print("❌ PIL (Pillow) not available. Install with: pip install Pillow")
    except Exception as e:
        print(f"❌ Error creating feature graphic: {e}")

def main():
    """Main function to run screenshot capture."""
    print("🎯 AAC Communication Helper - Screenshot Capture Tool")
    print("This tool helps you capture screenshots for app store submission.")
    print()
    
    print("Options:")
    print("1. Interactive screenshot session")
    print("2. Create feature graphic only")
    print("3. Setup directories only")
    
    choice = input("\nEnter choice (1-3): ").strip()
    
    if choice == '1':
        interactive_screenshot_session()
        create_feature_graphic()
    elif choice == '2':
        create_screenshot_directories()
        create_feature_graphic()
    elif choice == '3':
        create_screenshot_directories()
    else:
        print("Invalid choice. Exiting.")
        return
    
    print("\n🎉 Screenshot capture session complete!")
    print("\nNext steps:")
    print("1. Review captured screenshots for quality")
    print("2. Edit screenshots if needed (add text overlays, etc.)")
    print("3. Prepare store listings with the screenshots")
    print("4. Upload to Google Play Store and Apple App Store")

if __name__ == "__main__":
    main()
