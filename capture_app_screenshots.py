#!/usr/bin/env python3
"""
Automated screenshot capture for Play Store submission
Captures required app screenshots using ADB commands
"""

import subprocess
import time
import os
from datetime import datetime

def run_adb_command(command):
    """Run an ADB command and return the result"""
    try:
        # Use full path to ADB with proper PowerShell execution
        adb_path = os.path.expanduser(r"~\AppData\Local\Android\Sdk\platform-tools\adb.exe")
        
        # For PowerShell, we need to properly handle the command
        full_command = f'& "{adb_path}" {command}'
        result = subprocess.run(["powershell", "-Command", full_command], 
                               capture_output=True, text=True, shell=False)
        
        if result.returncode != 0:
            print(f"ADB command failed: {command}")
            print(f"Error: {result.stderr}")
            return False
        return True  # Return True for success, since some commands output to stderr
    except Exception as e:
        print(f"Error running ADB command: {e}")
        return False

def capture_screenshot(filename, description=""):
    """Capture a screenshot and save it with the given filename"""
    print(f"Capturing screenshot: {description}")
    
    # Create full path
    screenshot_path = f"promotional/screenshots/android/phone/{filename}"
    
    # Ensure directory exists
    os.makedirs(os.path.dirname(screenshot_path), exist_ok=True)
    
    # Capture screenshot on device
    if not run_adb_command("shell screencap -p /sdcard/screenshot.png"):
        return False
    
    # Pull screenshot to computer
    if not run_adb_command(f"pull /sdcard/screenshot.png {screenshot_path}"):
        return False
    
    # Clean up device
    run_adb_command("shell rm /sdcard/screenshot.png")
    
    print(f"Screenshot saved: {screenshot_path}")
    return True

def wait_for_user_input(message):
    """Wait for user to press Enter"""
    input(f"{message} Press Enter when ready...")

def check_device_connection():
    """Check if device is connected and return device info"""
    try:
        adb_path = os.path.expanduser(r"~\AppData\Local\Android\Sdk\platform-tools\adb.exe")
        full_command = f'& "{adb_path}" devices'
        result = subprocess.run(["powershell", "-Command", full_command], 
                               capture_output=True, text=True, shell=False)
        
        if result.returncode != 0:
            return False
        return result.stdout.strip()
    except Exception as e:
        print(f"Error checking device connection: {e}")
        return False

def capture_all_screenshots():
    """Capture all required screenshots for Play Store"""
    print("=== Play Store Screenshot Capture ===")
    print("Make sure your app is running on the connected device")
    print("Device should be in portrait mode")
    print()
    
    # Check if device is connected
    devices = check_device_connection()
    if not devices or "device" not in devices:
        print("No Android device connected via ADB")
        return False
    
    print("Connected device found!")
    print()
    
    # Screenshots needed for Play Store
    screenshots = [
        {
            "filename": "01_home_screen.png",
            "description": "Home screen with your new app icon visible",
            "instructions": "Navigate to the main home screen showing your app features"
        },
        {
            "filename": "02_symbol_selection.png", 
            "description": "Symbol selection interface",
            "instructions": "Show the symbol/communication board interface"
        },
        {
            "filename": "03_voice_features.png",
            "description": "Voice/audio features in action",
            "instructions": "Display voice recording or playback features"
        },
        {
            "filename": "04_favorites.png",
            "description": "Favorites or frequently used items",
            "instructions": "Show favorites section or commonly used symbols"
        },
        {
            "filename": "05_practice_mode.png",
            "description": "Practice or learning mode",
            "instructions": "Display any practice exercises or learning features"
        },
        {
            "filename": "06_settings_profile.png",
            "description": "Settings or user profile",
            "instructions": "Show settings screen or user profile management"
        }
    ]
    
    for i, screenshot in enumerate(screenshots, 1):
        print(f"Screenshot {i}/6: {screenshot['description']}")
        print(f"Instructions: {screenshot['instructions']}")
        wait_for_user_input("Position the app for this screenshot.")
        
        if capture_screenshot(screenshot['filename'], screenshot['description']):
            print("✅ Screenshot captured successfully!")
        else:
            print("❌ Failed to capture screenshot")
            return False
        
        print("-" * 50)
        time.sleep(1)
    
    print("🎉 All screenshots captured successfully!")
    print(f"Screenshots saved in: promotional/screenshots/android/phone/")
    
    # List captured files
    screenshot_dir = "promotional/screenshots/android/phone"
    if os.path.exists(screenshot_dir):
        files = os.listdir(screenshot_dir)
        png_files = [f for f in files if f.endswith('.png')]
        if png_files:
            print("\nCaptured screenshots:")
            for file in sorted(png_files):
                print(f"  - {file}")
    
    return True

if __name__ == "__main__":
    print("Play Store Screenshot Capture Tool")
    print("==================================")
    print()
    
    # Ensure we're in the right directory
    if not os.path.exists("pubspec.yaml"):
        print("Error: This script should be run from the Flutter app root directory")
        exit(1)
    
    success = capture_all_screenshots()
    
    if success:
        print("\n✅ Screenshot capture completed successfully!")
        print("You can now use these screenshots for your Play Store submission.")
    else:
        print("\n❌ Screenshot capture failed. Please check your device connection and try again.")
