# App Store Assets Usage Guide

This guide explains how to use the generated app store assets for the AAC Communication Helper app.

## Generated Assets Overview

All required assets have been generated and organized in the following directory structure:

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

## Android Asset Integration

### App Icons
The Android icons are located in `assets_store/icons/android/` and include all required sizes:
- LDPI (36x36)
- MDPI (48x48)
- HDPI (72x72)
- XHDPI (96x96)
- XXHDPI (144x144)
- XXXHDPI (192x192)

To integrate these icons into your Flutter app:

1. Copy the Android icons to `android/app/src/main/res/` in their respective directories:
   ```
   android/app/src/main/res/
   ├── mipmap-hdpi/ic_launcher.png (72x72)
   ├── mipmap-mdpi/ic_launcher.png (48x48)
   ├── mipmap-xhdpi/ic_launcher.png (96x96)
   ├── mipmap-xxhdpi/ic_launcher.png (144x144)
   ├── mipmap-xxxhdpi/ic_launcher.png (192x192)
   └── mipmap-anydpi-v26/ic_launcher.xml (adaptive icon configuration)
   ```

2. For adaptive icons (Android 8.0+), create an XML configuration in `mipmap-anydpi-v26/`:
   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
     <background android:drawable="@color/ic_launcher_background"/>
     <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
   </adaptive-icon>
   ```

### Splash Screens
Android splash screens are located in `assets_store/splashscreens/mobile/` and `assets_store/splashscreens/tablet/`.

To implement splash screens in Flutter:
1. Add the `flutter_native_splash` package to your `pubspec.yaml`
2. Configure the splash screen in `pubspec.yaml`:
   ```yaml
   flutter_native_splash:
     image: assets_store/splashscreens/mobile/splash_mobile_1080x1920.png
     color: "#4ECDC4"
   ```

## iOS Asset Integration

### App Icons
The iOS icons are located in `assets_store/icons/ios/` and include all required sizes for iPhone and iPad.

To integrate these icons into your Flutter app:

1. Open your Flutter project in Xcode:
   ```
   open ios/Runner.xcworkspace
   ```

2. Select the Runner project in the left panel

3. Go to the "Signing & Capabilities" tab

4. In the "App Icons and Launch Images" section, click on "App Icons Source"

5. Select "Use Asset Catalog" and create a new catalog if needed

6. Open the asset catalog and replace the placeholder icons with the generated ones

### Splash Screens
iOS splash screens are located in `assets_store/splashscreens/mobile/` and `assets_store/splashscreens/tablet/`.

To implement splash screens in Flutter:
1. Add the `flutter_native_splash` package to your `pubspec.yaml`
2. Configure the splash screen in `pubspec.yaml`:
   ```yaml
   flutter_native_splash:
     image: assets_store/splashscreens/mobile/splash_mobile_1125x2436.png
     color: "#4ECDC4"
   ```

## Web Asset Integration

### App Icons
Web icons are located in `assets_store/icons/web/` and include:
- favicon (16x16, 32x32)
- manifest icons (192x192, 512x512)

To integrate these icons into your Flutter web app:

1. Copy the web icons to `web/icons/`:
   ```
   web/
   ├── icons/
   │   ├── Icon-192.png (192x192)
   │   └── Icon-512.png (512x512)
   ├── favicon.png (32x32)
   └── manifest.json
   ```

2. Update `web/manifest.json`:
   ```json
   {
     "name": "AAC Communication Helper",
     "short_name": "AAC Helper",
     "start_url": ".",
     "display": "standalone",
     "background_color": "#4ECDC4",
     "theme_color": "#4ECDC4",
     "description": "An Augmentative and Alternative Communication app for individuals with communication challenges.",
     "orientation": "portrait-primary",
     "prefer_related_applications": false,
     "icons": [
       {
         "src": "icons/Icon-192.png",
         "sizes": "192x192",
         "type": "image/png"
       },
       {
         "src": "icons/Icon-512.png",
         "sizes": "512x512",
         "type": "image/png"
       }
     ]
   }
   ```

## Promotional Materials Usage

### Screenshots
Placeholder screenshots are located in `assets_store/promotional/screenshots/`. Before submitting to app stores:

1. Replace placeholder screenshots with actual app screenshots
2. Ensure screenshots show the app's best features
3. Include diverse representation of users
4. Follow app store guidelines for screenshot content

### Feature Graphics
Feature graphics are located in `assets_store/promotional/feature_graphics/`:
- Google Play Store: 1024x500 pixels
- Apple App Store: 1200x630 pixels

### Marketing Assets
Marketing assets are located in `assets_store/promotional/marketing/`:
- Logo variations for different uses
- Website banner
- Social media profile image

## Regenerating Assets

If you need to regenerate assets:

1. Modify the source SVG files:
   - `assets_store/source_logo.svg` for app icons
   - `assets_store/splash_source.svg` for splash screens

2. Run the appropriate script:
   - Windows: `assets_store/generate_assets.bat`
   - macOS/Linux: `assets_store/generate_assets.sh`

3. Verify all generated assets meet requirements

## Optimization Tips

1. **File Size**: Optimize PNG files using tools like TinyPNG or ImageOptim
2. **Consistency**: Maintain consistent branding across all assets
3. **Accessibility**: Ensure high contrast and readability
4. **Testing**: Test assets on different devices and screen sizes

## App Store Submission Requirements

### Google Play Store
- High-resolution icon (512x512 pixels) - use `assets_store/icons/web/web_icon_512x512.png`
- Feature graphic (1024x500 pixels) - use `assets_store/promotional/feature_graphics/feature_graphic_1024x500.png`
- Screenshots (minimum 2, maximum 8) - replace placeholders with actual screenshots
- Promo video (optional)

### Apple App Store
- App icon (1024x1024 pixels) - use `assets_store/icons/ios/ios_icon_1024x1024.png`
- Screenshots for various devices - replace placeholders with actual screenshots
- App preview (optional)

## Troubleshooting

### Common Issues
1. **Image quality**: If generated images appear pixelated, ensure source SVG has sufficient detail
2. **File permissions**: On Linux/macOS, ensure scripts have execute permissions (`chmod +x generate_assets.sh`)
3. **ImageMagick errors**: Verify ImageMagick is properly installed and in PATH

### Support
For issues with asset generation or integration:
1. Check that ImageMagick is installed and accessible
2. Verify source SVG files are valid
3. Ensure sufficient disk space for generated assets
4. Confirm output directories have write permissions

## Next Steps

1. Replace placeholder screenshots with actual app screenshots
2. Optimize all images for file size
3. Test assets on target devices
4. Verify compliance with app store guidelines
5. Prepare app store descriptions and metadata