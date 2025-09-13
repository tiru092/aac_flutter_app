#!/usr/bin/env python3
"""
Direct replacement script - saves user's original icon and deploys it immediately.
"""

import os
import shutil
from PIL import Image

def create_user_original_icon():
    """Create the user's original icon from the attachment."""
    
    # Create a placeholder - user needs to replace this with their actual image
    print("="*60)
    print("STEP 1: SAVE YOUR ORIGINAL IMAGE")
    print("="*60)
    print("1. Right-click on your original image attachment")
    print("2. Save it as 'user_original_icon.png' in this assets_store folder")
    print("3. Make sure the filename is exactly: user_original_icon.png")
    print("4. Then run this script again")
    print("")
    
    # Check if the image exists
    if not os.path.exists("user_original_icon.png"):
        print("❌ user_original_icon.png not found!")
        print("Please save your image first, then run this script again.")
        return False
    
    print("✅ Found user_original_icon.png")
    return True

def replace_all_icons_with_original():
    """Replace all app icons with the user's original image."""
    
    if not create_user_original_icon():
        return
    
    try:
        # Load the original image
        original_img = Image.open("user_original_icon.png")
        print(f"✅ Loaded original image: {original_img.size}")
        
        # Convert to RGBA
        if original_img.mode != 'RGBA':
            original_img = original_img.convert('RGBA')
        
        print("\n" + "="*60)
        print("STEP 2: GENERATING ALL ICON SIZES")
        print("="*60)
        
        # Android mipmap folders and sizes
        android_folders = {
            "../android/app/src/main/res/mipmap-mdpi": 48,
            "../android/app/src/main/res/mipmap-hdpi": 72,
            "../android/app/src/main/res/mipmap-xhdpi": 96,
            "../android/app/src/main/res/mipmap-xxhdpi": 144,
            "../android/app/src/main/res/mipmap-xxxhdpi": 192
        }
        
        # Replace Android icons
        for folder_path, size in android_folders.items():
            if not os.path.exists(folder_path):
                os.makedirs(folder_path, exist_ok=True)
            
            # Create resized icon
            resized = original_img.resize((size, size), Image.Resampling.LANCZOS)
            
            # Convert to RGB with white background for Android
            rgb_img = Image.new('RGB', (size, size), (255, 255, 255))
            if resized.mode == 'RGBA':
                rgb_img.paste(resized, mask=resized.split()[-1])
            else:
                rgb_img.paste(resized)
            
            # Save both launcher and round versions
            rgb_img.save(os.path.join(folder_path, "ic_launcher.png"))
            rgb_img.save(os.path.join(folder_path, "ic_launcher_round.png"))
            
            print(f"✅ Android {os.path.basename(folder_path)}: {size}x{size}")
        
        # iOS AppIcon.appiconset
        ios_folder = "../ios/Runner/Assets.xcassets/AppIcon.appiconset"
        ios_sizes = [
            (40, "40x40"),
            (58, "58x58"), 
            (60, "60x60"),
            (80, "80x80"),
            (87, "87x87"),
            (120, "120x120"),
            (152, "152x152"),
            (167, "167x167"),
            (180, "180x180"),
            (1024, "1024x1024")
        ]
        
        if not os.path.exists(ios_folder):
            os.makedirs(ios_folder, exist_ok=True)
        
        for size, name in ios_sizes:
            resized = original_img.resize((size, size), Image.Resampling.LANCZOS)
            
            # Convert to RGB for iOS
            rgb_img = Image.new('RGB', (size, size), (255, 255, 255))
            if resized.mode == 'RGBA':
                rgb_img.paste(resized, mask=resized.split()[-1])
            else:
                rgb_img.paste(resized)
            
            rgb_img.save(os.path.join(ios_folder, f"Icon-App-{name}@1x.png"))
            print(f"✅ iOS: {name}")
        
        # Web icons
        web_folder = "../assets/icons"
        if not os.path.exists(web_folder):
            os.makedirs(web_folder, exist_ok=True)
        
        web_sizes = [16, 32, 48, 72, 96, 128, 144, 152, 192, 384, 512]
        
        for size in web_sizes:
            resized = original_img.resize((size, size), Image.Resampling.LANCZOS)
            resized.save(os.path.join(web_folder, f"icon-{size}x{size}.png"))
            print(f"✅ Web: {size}x{size}")
        
        # Also save as main icon files
        resized_192 = original_img.resize((192, 192), Image.Resampling.LANCZOS)
        resized_192.save(os.path.join(web_folder, "Icon-192.png"))
        
        resized_512 = original_img.resize((512, 512), Image.Resampling.LANCZOS)
        resized_512.save(os.path.join(web_folder, "Icon-512.png"))
        
        print("\n" + "="*60)
        print("🎉 SUCCESS! ALL ICONS REPLACED")
        print("="*60)
        print("✅ Android icons: Updated in all mipmap folders")
        print("✅ iOS icons: Updated in AppIcon.appiconset")
        print("✅ Web icons: Updated in assets/icons")
        print("")
        print("Your original image is now used for all app icons!")
        print("You can test the app to see the new icons.")
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    replace_all_icons_with_original()
