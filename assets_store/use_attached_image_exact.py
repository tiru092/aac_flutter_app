#!/usr/bin/env python3
"""
Use the user's EXACT attached image without any modifications.
This script will take the original PNG image and only resize it to required sizes.
"""

import os
from PIL import Image
import base64
import io

def save_user_attached_image():
    """Save the user's exact attached image as PNG."""
    
    # The user has attached a specific PNG image that I need to use exactly as-is
    # I need to extract this from the conversation context
    
    print("🖼️  EXTRACTING YOUR EXACT ATTACHED IMAGE...")
    
    # For now, create a placeholder that tells user to manually save their image
    # This is the most reliable way to ensure we get their EXACT image
    
    original_path = "user_attached_original.png"
    
    if os.path.exists(original_path):
        print(f"✅ Found your original image: {original_path}")
        return original_path
    
    print("❌ Please save your attached image as 'user_attached_original.png' in this folder")
    print("📌 IMPORTANT: Save the EXACT image you attached - don't modify it!")
    print("📌 Right-click on your attached image → Save as → user_attached_original.png")
    print("📌 Put it in the assets_store folder")
    return None

def resize_exact_image_only():
    """Take the user's exact image and only resize it - NO modifications."""
    
    original_path = save_user_attached_image()
    
    if not original_path:
        print("\n🔴 Cannot proceed without your original image file.")
        print("Please save your attached image first, then run this script again.")
        return
    
    try:
        # Load the EXACT original image
        original_img = Image.open(original_path)
        print(f"✅ Loaded original image: {original_img.size} pixels")
        print(f"✅ Mode: {original_img.mode}")
        
        # Show what we're working with
        print(f"✅ This is your EXACT attached image - no modifications will be made!")
        
        # Android sizes (mipmap densities)
        android_sizes = {
            'mdpi': 48,
            'hdpi': 72,
            'xhdpi': 96, 
            'xxhdpi': 144,
            'xxxhdpi': 192
        }
        
        print(f"\n📱 ANDROID ICONS - Resizing only...")
        android_folders = {
            "../android/app/src/main/res/mipmap-mdpi": 48,
            "../android/app/src/main/res/mipmap-hdpi": 72,
            "../android/app/src/main/res/mipmap-xhdpi": 96,
            "../android/app/src/main/res/mipmap-xxhdpi": 144,
            "../android/app/src/main/res/mipmap-xxxhdpi": 192
        }
        
        for folder_path, size in android_folders.items():
            os.makedirs(folder_path, exist_ok=True)
            
            # ONLY resize - no other changes
            resized = original_img.resize((size, size), Image.Resampling.LANCZOS)
            
            # Save exactly as PNG (preserving transparency if present)
            resized.save(os.path.join(folder_path, "ic_launcher.png"))
            resized.save(os.path.join(folder_path, "ic_launcher_round.png"))
            
            print(f"✅ {os.path.basename(folder_path)}: {size}x{size} (EXACT resize)")
        
        print(f"\n🍎 iOS ICONS - Resizing only...")
        ios_folder = "../ios/Runner/Assets.xcassets/AppIcon.appiconset"
        ios_sizes = [40, 58, 60, 80, 87, 120, 152, 167, 180, 1024]
        
        os.makedirs(ios_folder, exist_ok=True)
        
        for size in ios_sizes:
            # ONLY resize - no other changes
            resized = original_img.resize((size, size), Image.Resampling.LANCZOS)
            resized.save(os.path.join(ios_folder, f"Icon-App-{size}x{size}@1x.png"))
            print(f"✅ iOS: {size}x{size} (EXACT resize)")
        
        print(f"\n🌐 WEB ICONS - Resizing only...")
        web_folder = "../assets/icons"
        web_sizes = [16, 32, 48, 72, 96, 128, 144, 152, 192, 384, 512]
        
        os.makedirs(web_folder, exist_ok=True)
        
        for size in web_sizes:
            # ONLY resize - no other changes
            resized = original_img.resize((size, size), Image.Resampling.LANCZOS)
            resized.save(os.path.join(web_folder, f"icon-{size}x{size}.png"))
            print(f"✅ Web: {size}x{size} (EXACT resize)")
        
        # Main web icons
        original_img.resize((192, 192), Image.Resampling.LANCZOS).save(os.path.join(web_folder, "Icon-192.png"))
        original_img.resize((512, 512), Image.Resampling.LANCZOS).save(os.path.join(web_folder, "Icon-512.png"))
        
        print(f"\n🎉 SUCCESS! Your EXACT attached image has been used!")
        print(f"✅ Only resized to required dimensions")
        print(f"✅ No color changes, no modifications, no regeneration")
        print(f"✅ Your original design preserved 100%")
        
    except Exception as e:
        print(f"❌ Error processing your image: {e}")
        print("Make sure the file is a valid PNG image.")

if __name__ == "__main__":
    resize_exact_image_only()
