#!/usr/bin/env python3
"""
Save the user's original icon image and create all required sizes.
"""

import os
import base64
from PIL import Image
import io

def save_original_and_generate():
    """Save the original user image and generate all sizes."""
    
    # I'll create a placeholder that you need to replace with your actual image
    print("IMPORTANT: You need to manually save your original image as 'user_original_icon.png'")
    print("Please copy your original PNG image file to this folder with that exact name.")
    print("")
    
    # Check if user has provided the original image
    original_path = "user_original_icon.png"
    
    if not os.path.exists(original_path):
        print("Please save your original image as 'user_original_icon.png' in this folder first.")
        print("Then run this script again.")
        return False
    
    try:
        # Load the original image
        original_img = Image.open(original_path)
        print(f"Successfully loaded original image: {original_img.size}")
        
        # Convert to RGBA if not already
        if original_img.mode != 'RGBA':
            original_img = original_img.convert('RGBA')
        
        # Android icon sizes (mipmap densities)
        android_sizes = {
            'mdpi': 48,
            'hdpi': 72, 
            'xhdpi': 96,
            'xxhdpi': 144,
            'xxxhdpi': 192
        }
        
        # iOS icon sizes
        ios_sizes = [40, 58, 60, 80, 87, 120, 152, 167, 180, 1024]
        
        # Web icon sizes  
        web_sizes = [16, 32, 48, 72, 96, 128, 144, 152, 192, 384, 512]
        
        # Create output directory
        output_dir = "generated_from_original"
        os.makedirs(output_dir, exist_ok=True)
        
        # Android icons
        android_dir = os.path.join(output_dir, "android")
        os.makedirs(android_dir, exist_ok=True)
        
        for density, size in android_sizes.items():
            resized = original_img.resize((size, size), Image.Resampling.LANCZOS)
            # Save as RGB for Android (no transparency issues)
            rgb_img = Image.new('RGB', (size, size), (255, 255, 255))
            rgb_img.paste(resized, mask=resized.split()[-1] if resized.mode == 'RGBA' else None)
            rgb_img.save(os.path.join(android_dir, f"ic_launcher_{density}.png"))
            rgb_img.save(os.path.join(android_dir, f"ic_launcher_round_{density}.png"))
            print(f"✓ Android {density}: {size}x{size}")
        
        # iOS icons
        ios_dir = os.path.join(output_dir, "ios")
        os.makedirs(ios_dir, exist_ok=True)
        
        for size in ios_sizes:
            resized = original_img.resize((size, size), Image.Resampling.LANCZOS)
            # iOS also prefers RGB
            rgb_img = Image.new('RGB', (size, size), (255, 255, 255))
            rgb_img.paste(resized, mask=resized.split()[-1] if resized.mode == 'RGBA' else None)
            rgb_img.save(os.path.join(ios_dir, f"icon_{size}x{size}.png"))
            print(f"✓ iOS: {size}x{size}")
        
        # Web icons (keep RGBA for web)
        web_dir = os.path.join(output_dir, "web")
        os.makedirs(web_dir, exist_ok=True)
        
        for size in web_sizes:
            resized = original_img.resize((size, size), Image.Resampling.LANCZOS)
            resized.save(os.path.join(web_dir, f"icon_{size}x{size}.png"))
            print(f"✓ Web: {size}x{size}")
        
        print(f"\n🎉 All icons generated successfully in '{output_dir}' folder!")
        print("Next step: Run the deployment script to copy them to the app.")
        return True
        
    except Exception as e:
        print(f"Error processing image: {e}")
        return False

if __name__ == "__main__":
    save_original_and_generate()
