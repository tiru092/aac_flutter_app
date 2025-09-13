#!/usr/bin/env python3
"""
Simple screenshot capture for AAC app Play Store submission.
"""

import os
import subprocess
import time
from datetime import datetime

def capture_screenshot(filename, description):
    """Capture a screenshot using ADB."""
    print(f"\n📸 {description}")
    print(f"🎯 Capturing: {filename}")
    
    # Create the full path
    screenshot_dir = "promotional/screenshots/android/phone"
    os.makedirs(screenshot_dir, exist_ok=True)
    filepath = os.path.join(screenshot_dir, filename)
    
    try:
        # Capture screenshot using ADB
        result = subprocess.run([
            "adb", "exec-out", "screencap", "-p"
        ], capture_output=True, check=True)
        
        # Save the screenshot
        with open(filepath, "wb") as f:
            f.write(result.stdout)
        
        print(f"✅ Screenshot saved: {filepath}")
        return True
        
    except subprocess.CalledProcessError as e:
        print(f"❌ Error capturing screenshot: {e}")
        return False
    except FileNotFoundError:
        print("❌ ADB not found. Please ensure Android SDK is installed and ADB is in PATH.")
        print("🔧 Alternative: Take screenshots manually on your device and save them to:")
        print(f"   {screenshot_dir}/")
        return False

def capture_all_screenshots():
    """Capture all required screenshots for Play Store submission."""
    
    print("🎬 AAC App Screenshot Capture for Play Store")
    print("=" * 50)
    print("📱 Make sure your app is running on the connected Android device!")
    print("⏰ You'll have 10 seconds between each screenshot to navigate the app.")
    print()
    
    screenshots = [
        ("01_home_screen.png", "Home Screen with Communication Grid - Show main AAC interface"),
        ("02_symbol_selection.png", "Symbol Selection in Action - Show symbols being selected"),
        ("03_voice_features.png", "Voice Features - Show TTS or voice settings"),
        ("04_favorites.png", "Favorites/Quick Access - Show personalization features"),
        ("05_practice_mode.png", "Practice/Learning Mode - Show educational features"),
        ("06_settings.png", "Settings/Accessibility - Show customization options"),
    ]
    
    input("🚀 Press Enter when the app is ready on your device...")
    
    for i, (filename, description) in enumerate(screenshots, 1):
        print(f"\n📋 Step {i}/{len(screenshots)}")
        input(f"👉 Navigate to: {description}\\n   Press Enter when ready to capture...")
        
        success = capture_screenshot(filename, description)
        if not success:
            print("⚠️  Screenshot failed - please capture manually")
        
        if i < len(screenshots):
            print("⏰ 5 seconds to navigate to next screen...")
            time.sleep(5)
    
    print("\n🎉 Screenshot capture complete!")
    print(f"📁 Screenshots saved in: promotional/screenshots/android/phone/")
    print("📋 Next steps:")
    print("   1. Review screenshots for quality")
    print("   2. Add them to your Play Store listing")
    print("   3. Create feature graphic if needed")

if __name__ == "__main__":
    capture_all_screenshots()
