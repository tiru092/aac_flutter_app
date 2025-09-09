#!/usr/bin/env python3
"""
Deploy generated app icons to their proper locations in the Flutter project.
"""

import os
import shutil

def copy_android_icons():
    """Copy Android icons to proper mipmap directories."""
    android_mappings = [
        # (source_file, target_directory, target_filename)
        ("assets_store/icons/android/ic_launcher_48.png", "android/app/src/main/res/mipmap-mdpi", "ic_launcher.png"),
        ("assets_store/icons/android/ic_launcher_72.png", "android/app/src/main/res/mipmap-hdpi", "ic_launcher.png"),
        ("assets_store/icons/android/ic_launcher_96.png", "android/app/src/main/res/mipmap-xhdpi", "ic_launcher.png"),
        ("assets_store/icons/android/ic_launcher_144.png", "android/app/src/main/res/mipmap-xxhdpi", "ic_launcher.png"),
        ("assets_store/icons/android/ic_launcher_192.png", "android/app/src/main/res/mipmap-xxxhdpi", "ic_launcher.png"),
        
        # Round icons (same source, different name)
        ("assets_store/icons/android/ic_launcher_48.png", "android/app/src/main/res/mipmap-mdpi", "ic_launcher_round.png"),
        ("assets_store/icons/android/ic_launcher_72.png", "android/app/src/main/res/mipmap-hdpi", "ic_launcher_round.png"),
        ("assets_store/icons/android/ic_launcher_96.png", "android/app/src/main/res/mipmap-xhdpi", "ic_launcher_round.png"),
        ("assets_store/icons/android/ic_launcher_144.png", "android/app/src/main/res/mipmap-xxhdpi", "ic_launcher_round.png"),
        ("assets_store/icons/android/ic_launcher_192.png", "android/app/src/main/res/mipmap-xxxhdpi", "ic_launcher_round.png"),
    ]
    
    print("Copying Android icons...")
    for source, target_dir, target_file in android_mappings:
        if os.path.exists(source):
            os.makedirs(target_dir, exist_ok=True)
            target_path = os.path.join(target_dir, target_file)
            shutil.copy2(source, target_path)
            print(f"✅ Copied {source} -> {target_path}")
        else:
            print(f"❌ Source not found: {source}")

def copy_ios_icons():
    """Copy iOS icons to proper iOS directory."""
    ios_source_dir = "assets_store/icons/ios"
    ios_target_dir = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    
    # Create Contents.json for iOS AppIcon set
    contents_json = """{
  "images" : [
    {
      "filename" : "Icon-40.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-80.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-76.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "76x76"
    },
    {
      "filename" : "Icon-152.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "76x76"
    },
    {
      "filename" : "Icon-167.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "83.5x83.5"
    },
    {
      "filename" : "Icon-60.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "30x30"
    },
    {
      "filename" : "Icon-87.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-80.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-120.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-120.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "filename" : "Icon-180.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "filename" : "Icon-1024.png",
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}"""
    
    print("Copying iOS icons...")
    os.makedirs(ios_target_dir, exist_ok=True)
    
    # Copy all iOS icon files
    for filename in os.listdir(ios_source_dir):
        if filename.endswith('.png'):
            source_path = os.path.join(ios_source_dir, filename)
            target_path = os.path.join(ios_target_dir, filename)
            shutil.copy2(source_path, target_path)
            print(f"✅ Copied {source_path} -> {target_path}")
    
    # Create Contents.json
    contents_path = os.path.join(ios_target_dir, "Contents.json")
    with open(contents_path, 'w') as f:
        f.write(contents_json)
    print(f"✅ Created {contents_path}")

def copy_web_icons():
    """Copy web icons to assets/icons directory."""
    web_source_dir = "assets_store/icons/web"
    web_target_dir = "assets/icons"
    
    web_mappings = [
        ("icon-16.png", "web_icon_16x16.png"),
        ("icon-32.png", "web_icon_32x32.png"),
        ("icon-192.png", "web_icon_192x192.png"),
        ("icon-512.png", "web_icon_512x512.png"),
    ]
    
    print("Copying web icons...")
    os.makedirs(web_target_dir, exist_ok=True)
    
    for source_name, target_name in web_mappings:
        source_path = os.path.join(web_source_dir, source_name)
        target_path = os.path.join(web_target_dir, target_name)
        if os.path.exists(source_path):
            shutil.copy2(source_path, target_path)
            print(f"✅ Copied {source_path} -> {target_path}")
        else:
            print(f"❌ Source not found: {source_path}")

def main():
    """Deploy all generated icons to their proper locations."""
    print("🚀 Deploying new app icons...")
    print("=" * 50)
    
    copy_android_icons()
    print()
    copy_ios_icons()
    print()
    copy_web_icons()
    
    print("=" * 50)
    print("✅ All app icons deployed successfully!")
    print("\nNext steps:")
    print("1. Clean and rebuild your Flutter app")
    print("2. Test the new icons on device/emulator")
    print("3. Generate app screenshots for store submission")

if __name__ == "__main__":
    main()
