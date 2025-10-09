#!/usr/bin/env python3
"""
Script to create missing emoji icons and category icons for AAC Flutter App
Creates PNG files from emoji characters and category icons
"""

import os
import requests
from PIL import Image, ImageDraw, ImageFont
import io

# Create directories if they don't exist
def ensure_dir(directory):
    if not os.path.exists(directory):
        os.makedirs(directory)

# Create emoji PNG from unicode character
def create_emoji_png(emoji, filename, size=128):
    """Create a PNG file from emoji character using Noto Color Emoji font or fallback"""
    try:
        # Try to create image with PIL
        img = Image.new('RGBA', (size, size), (255, 255, 255, 0))
        draw = ImageDraw.Draw(img)
        
        # Try to load a system font that supports emoji
        try:
            # Common emoji font paths on Windows
            font_paths = [
                "C:/Windows/Fonts/seguiemj.ttf",  # Segoe UI Emoji
                "C:/Windows/Fonts/NotoColorEmoji.ttf",  # Noto Color Emoji
            ]
            
            font = None
            for font_path in font_paths:
                if os.path.exists(font_path):
                    font = ImageFont.truetype(font_path, size=int(size * 0.8))
                    break
            
            if font is None:
                font = ImageFont.load_default()
            
        except Exception:
            font = ImageFont.load_default()
        
        # Get text size and center it
        bbox = draw.textbbox((0, 0), emoji, font=font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]
        
        x = (size - text_width) // 2
        y = (size - text_height) // 2 - bbox[1]
        
        # Draw emoji
        draw.text((x, y), emoji, font=font, fill=(0, 0, 0, 255))
        
        # Save the image
        img.save(filename, 'PNG')
        print(f"Created: {filename}")
        return True
        
    except Exception as e:
        print(f"Error creating {filename}: {e}")
        return False

# Create category icons with colored backgrounds and text
def create_category_icon(category_name, emoji, color_hex, filename, size=128):
    """Create a category icon with colored background and emoji"""
    try:
        # Convert hex to RGB
        color_rgb = tuple(int(color_hex[i:i+2], 16) for i in (1, 3, 5))
        
        # Create image with colored background
        img = Image.new('RGBA', (size, size), color_rgb + (255,))
        draw = ImageDraw.Draw(img)
        
        # Add rounded corners
        mask = Image.new('L', (size, size), 0)
        mask_draw = ImageDraw.Draw(mask)
        mask_draw.rounded_rectangle([(0, 0), (size-1, size-1)], radius=size//8, fill=255)
        
        # Apply mask for rounded corners
        img.putalpha(mask)
        
        # Try to load emoji font
        try:
            font_paths = [
                "C:/Windows/Fonts/seguiemj.ttf",
                "C:/Windows/Fonts/NotoColorEmoji.ttf",
            ]
            
            font = None
            for font_path in font_paths:
                if os.path.exists(font_path):
                    font = ImageFont.truetype(font_path, size=int(size * 0.5))
                    break
            
            if font is None:
                font = ImageFont.load_default()
                
        except Exception:
            font = ImageFont.load_default()
        
        # Draw emoji in center
        bbox = draw.textbbox((0, 0), emoji, font=font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]
        
        x = (size - text_width) // 2
        y = (size - text_height) // 2 - bbox[1]
        
        draw.text((x, y), emoji, font=font, fill=(255, 255, 255, 255))
        
        img.save(filename, 'PNG')
        print(f"Created category icon: {filename}")
        return True
        
    except Exception as e:
        print(f"Error creating category icon {filename}: {e}")
        return False

def main():
    # Base paths
    base_path = "C:/Users/PC/Documents/AAC_Arjun_app/aac_flutter_app"
    assets_path = os.path.join(base_path, "assets")
    symbols_path = os.path.join(assets_path, "symbols")
    icons_path = os.path.join(assets_path, "icons")
    
    # Ensure directories exist
    ensure_dir(symbols_path)
    ensure_dir(icons_path)
    
    # Category icons with their emojis and colors
    categories = {
        'food': {'emoji': '🍎', 'color': 'FF6B6B', 'names': ['food.png', 'foods.png']},
        'vehicles': {'emoji': '🚗', 'color': '4ECDC4', 'names': ['vehicle.png', 'vehicles.png']},
        'emotions': {'emoji': '😊', 'color': 'FFE66D', 'names': ['emotion.png', 'emotions.png']}, 
        'actions': {'emoji': '🏃', 'color': '6C63FF', 'names': ['action.png', 'actions.png']},
        'family': {'emoji': '👨‍👩‍👧‍👦', 'color': 'FF9F43', 'names': ['family.png']},
        'needs': {'emoji': '🙏', 'color': '51CF66', 'names': ['needs.png']},
        'custom': {'emoji': '⭐', 'color': 'A855F7', 'names': ['custom.png']}
    }
    
    # Create category icons
    print("Creating category icons...")
    for category, info in categories.items():
        for name in info['names']:
            filename = os.path.join(icons_path, name)
            create_category_icon(category.title(), info['emoji'], info['color'], filename)
    
    # Common emoji symbols from the sample data that need PNG versions
    emoji_symbols = {
        # Food & Drinks
        'milk.png': '🥛',
        'bread.png': '🍞', 
        'banana.png': '🍌',
        'orange.png': '🍊',
        'grape.png': '🍇',
        'strawberry.png': '🍓',
        'pizza.png': '🍕',
        'burger.png': '🍔',
        'sandwich.png': '🥪',
        'hotdog.png': '🌭',
        'taco.png': '🌮',
        'salad.png': '🥗',
        'soup.png': '🍲',
        'rice.png': '🍚',
        'pasta.png': '🍝',
        'cookie.png': '🍪',
        'cake.png': '🎂',
        'icecream.png': '🍦',
        'juice.png': '🧃',
        'coffee.png': '☕',
        'tea.png': '🍵',
        
        # Vehicles
        'bus.png': '🚌',
        'train.png': '🚂',
        'airplane.png': '✈️',
        'bicycle.png': '🚴',
        'motorcycle.png': '🏍️',
        'truck.png': '🚚',
        'taxi.png': '🚕',
        'boat.png': '⛵',
        'helicopter.png': '🚁',
        
        # Emotions  
        'happy.png': '😊',
        'sad.png': '😢',
        'angry.png': '😠',
        'excited.png': '🤩',
        'scared.png': '😨',
        'tired.png': '😴',
        'love.png': '😍',
        'surprised.png': '😲',
        
        # Actions
        'run.png': '🏃',
        'walk.png': '🚶',
        'jump.png': '🦘',
        'sit.png': '🪑',
        'sleep.png': '😴',
        'eat.png': '🍽️',
        'drink.png': '🥤',
        'play.png': '🎮',
        'read.png': '📚',
        'write.png': '✍️',
        'draw.png': '🎨',
        'sing.png': '🎤',
        'dance.png': '💃',
        'hug.png': '🤗',
        'wave.png': '👋',
        'clap.png': '👏',
        'point.png': '👉',
        'help.png': '🤝',
        
        # Family
        'mom.png': '👩',
        'dad.png': '👨', 
        'baby.png': '👶',
        'child.png': '🧒',
        'grandma.png': '👵',
        'grandpa.png': '👴',
        'family.png': '👨‍👩‍👧‍👦',
        'friend.png': '👫',
        'teacher.png': '👨‍🏫',
        'doctor.png': '👨‍⚕️',
        'police.png': '👮',
        
        # Basic Needs
        'home.png': '🏠',
        'bed.png': '🛏️',
        'toilet.png': '🚽',
        'shower.png': '🚿',
        'clothes.png': '👕',
        'shoes.png': '👟',
        'medicine.png': '💊',
        'phone.png': '📱',
        'computer.png': '💻',
        'tv.png': '📺',
        'book.png': '📖',
        'pen.png': '🖊️',
        'bag.png': '👜',
        'watch.png': '⌚',
        'umbrella.png': '☂️',
        'sunglasses.png': '🕶️'
    }
    
    # Create emoji symbol PNGs
    print("\nCreating emoji symbol icons...")
    for filename, emoji in emoji_symbols.items():
        filepath = os.path.join(symbols_path, filename)
        create_emoji_png(emoji, filepath)
    
    print("\nIcon creation completed!")
    print(f"Created category icons in: {icons_path}")
    print(f"Created symbol icons in: {symbols_path}")
    
    # List created files
    print("\nCreated files:")
    if os.path.exists(icons_path):
        icons = [f for f in os.listdir(icons_path) if f.endswith('.png')]
        print(f"Category icons: {len(icons)} files")
        for icon in sorted(icons):
            print(f"  - {icon}")
    
    if os.path.exists(symbols_path):
        symbols = [f for f in os.listdir(symbols_path) if f.endswith('.png')]
        print(f"Symbol icons: {len(symbols)} files") 
        for symbol in sorted(symbols):
            print(f"  - {symbol}")

if __name__ == "__main__":
    main()