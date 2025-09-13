#!/usr/bin/env python3
"""
Use the exact original image provided by user as app icon.
This script takes the user's original image and resizes it for all required icon sizes.
"""

import os
from PIL import Image

def resize_original_icon():
    """Resize the original user image to all required icon sizes."""
    
    # First, I need to manually save the user's image
    # The user provided a PNG image with colorful human figures and play button
    print("Please save your original image as 'user_original_icon.png' in the assets_store folder")
    print("Then run this script to generate all required sizes")
    
    original_path = "user_original_icon.png"
    
    if not os.path.exists(original_path):
        print(f"Error: {original_path} not found!")
        print("Please save your original image with this exact filename first.")
        return
    
    # Load the original image
    original_img = Image.open(original_path)
    print(f"Loaded original image: {original_img.size}")
    
    # Android icon sizes (mipmap densities)
    android_sizes = {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192
    }
    
    # iOS icon sizes
    ios_sizes = [
        40, 58, 60, 80, 87, 120, 152, 167, 180, 1024
    ]
    
    # Web icon sizes
    web_sizes = [16, 32, 48, 72, 96, 128, 144, 152, 192, 384, 512]
    
    # Create output directory
    output_dir = "resized_icons"
    os.makedirs(output_dir, exist_ok=True)
    
    # Generate Android icons
    android_dir = os.path.join(output_dir, "android")
    os.makedirs(android_dir, exist_ok=True)
    
    for density, size in android_sizes.items():
        resized = original_img.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(os.path.join(android_dir, f"ic_launcher_{density}.png"))
        resized.save(os.path.join(android_dir, f"ic_launcher_round_{density}.png"))
        print(f"Generated Android {density}: {size}x{size}")
    
    # Generate iOS icons
    ios_dir = os.path.join(output_dir, "ios")
    os.makedirs(ios_dir, exist_ok=True)
    
    for size in ios_sizes:
        resized = original_img.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(os.path.join(ios_dir, f"icon_{size}x{size}.png"))
        print(f"Generated iOS: {size}x{size}")
    
    # Generate web icons
    web_dir = os.path.join(output_dir, "web")
    os.makedirs(web_dir, exist_ok=True)
    
    for size in web_sizes:
        resized = original_img.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(os.path.join(web_dir, f"icon_{size}x{size}.png"))
        print(f"Generated Web: {size}x{size}")
    
    print(f"\nAll icons generated in '{output_dir}' folder")
    print("Now you can deploy them using the deploy script")

if __name__ == "__main__":
    resize_original_icon()
