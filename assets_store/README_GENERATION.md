# App Store Assets Generation Guide

This guide provides instructions for generating all required app store assets for the AAC Communication Helper app.

## Prerequisites

1. Install ImageMagick for batch image processing:
   https://imagemagick.org/script/download.php

2. Prepare a high-quality source image (1024x1024 pixels minimum) in PNG format

## Icon Generation

### Android Icons

Run the following commands to generate Android icons:

```bash
# Navigate to the icons directory
cd assets_store/icons

# Generate Android icons from source (replace source.png with your source image)
convert source.png -resize 36x36 android_icon_36dp.png
convert source.png -resize 48x48 android_icon_48dp.png
convert source.png -resize 72x72 android_icon_72dp.png
convert source.png -resize 96x96 android_icon_96dp.png
convert source.png -resize 144x144 android_icon_144dp.png
convert source.png -resize 192x192 android_icon_192dp.png
```

### iOS Icons

Use an icon generator tool or run these commands:

```bash
# Generate iOS icons from source
convert source.png -resize 40x40 ios_icon_20x20@2x.png
convert source.png -resize 60x60 ios_icon_20x20@3x.png
convert source.png -resize 58x58 ios_icon_29x29@2x.png
convert source.png -resize 87x87 ios_icon_29x29@3x.png
convert source.png -resize 80x80 ios_icon_40x40@2x.png
convert source.png -resize 120x120 ios_icon_40x40@3x.png
convert source.png -resize 120x120 ios_icon_60x60@2x.png
convert source.png -resize 180x180 ios_icon_60x60@3x.png
convert source.png -resize 152x152 ios_icon_76x76@2x.png
convert source.png -resize 167x167 ios_icon_83.5x83.5@2x.png
convert source.png -resize 1024x1024 ios_icon_1024x1024.png
```

### Web Icons

```bash
# Generate Web icons from source
convert source.png -resize 16x16 web_icon_16x16.png
convert source.png -resize 32x32 web_icon_32x32.png
convert source.png -resize 192x192 web_icon_192x192.png
convert source.png -resize 512x512 web_icon_512x512.png
```

## Splash Screen Generation

Prepare your splash screen design and generate different sizes:

```bash
# Navigate to splashscreens directory
cd assets_store/splashscreens

# Generate mobile splash screens
convert splash_source.png -resize 640x1136 splash_mobile_640x1136.png
convert splash_source.png -resize 750x1334 splash_mobile_750x1334.png
convert splash_source.png -resize 1125x2436 splash_mobile_1125x2436.png
convert splash_source.png -resize 1242x2688 splash_mobile_1242x2688.png
convert splash_source.png -resize 828x1792 splash_mobile_828x1792.png
convert splash_source.png -resize 1080x1920 splash_mobile_1080x1920.png

# Generate tablet splash screens
convert splash_source.png -resize 1536x2048 splash_tablet_1536x2048.png
convert splash_source.png -resize 1668x2224 splash_tablet_1668x2224.png
convert splash_source.png -resize 1668x2388 splash_tablet_1668x2388.png
convert splash_source.png -resize 2048x2732 splash_tablet_2048x2732.png
```

## Promotional Materials

### Screenshots

Take screenshots of the app in various scenarios:
1. Main communication grid
2. Symbol customization screen
3. Category management
4. Settings and preferences
5. Profile selection

Ensure screenshots are:
- Clear and high-resolution
- Show the app's best features
- Include diverse representation of users

### Feature Graphics

Create feature graphics for app stores:
- Google Play Store: 1024x500 pixels
- Apple App Store: 1200x630 pixels

Include:
- App name
- Key features
- Visual representation of the app's purpose

### Marketing Assets

Create additional marketing materials:
- Horizontal logo (for website headers)
- Vertical logo (for social media)
- Icon-only version (for favicons)
- Website banner (1200x600 pixels)
- Social media profile image (1080x1080 pixels)

## Automation Script

Create a batch script to automate asset generation:

```bash
#!/bin/bash
# generate_assets.sh

SOURCE_IMAGE="source.png"
SPLASH_SOURCE="splash_source.png"

# Generate icons
echo "Generating icons..."
convert $SOURCE_IMAGE -resize 1024x1024 ios_icon_1024x1024.png
# Add more convert commands for all required sizes

# Generate splash screens
echo "Generating splash screens..."
convert $SPLASH_SOURCE -resize 1080x1920 splash_mobile_1080x1920.png
# Add more convert commands for all required sizes

echo "Asset generation complete!"
```

## Best Practices

1. **Consistency**: Maintain consistent branding across all assets
2. **Accessibility**: Ensure high contrast and readability
3. **Clarity**: Keep designs simple and uncluttered
4. **Testing**: Test assets on different devices and screen sizes
5. **Optimization**: Compress images without losing quality
6. **Backup**: Keep original high-resolution sources

## Tools Recommendation

1. **Image Editing**: 
   - Adobe Photoshop/Illustrator
   - GIMP (free alternative)
   - Figma (web-based)

2. **Icon Generation**:
   - Android Asset Studio
   - App Icon Generator
   - MakeAppIcon

3. **Screenshot Tools**:
   - Android Emulator/Device screenshots
   - iOS Simulator screenshots
   - Browser developer tools for web

## File Organization

Organize generated assets in the following structure:
```
assets_store/
├── icons/
│   ├── android/
│   ├── ios/
│   └── web/
├── splashscreens/
│   ├── mobile/
│   └── tablet/
└── promotional/
    ├── screenshots/
    ├── feature_graphics/
    └── marketing/
```

## Quality Checklist

Before submitting assets, verify:
- [ ] All required sizes are generated
- [ ] File names match requirements exactly
- [ ] Images are in PNG format
- [ ] No transparency issues
- [ ] Text is readable at small sizes
- [ ] Branding is consistent
- [ ] Assets comply with store guidelines
- [ ] Files are optimized for size