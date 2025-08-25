@echo off
echo Generating App Store Assets for AAC Communication Helper
echo ======================================================

REM Check if ImageMagick is installed
magick -version >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: ImageMagick is not installed or not in PATH
    echo Please install ImageMagick from https://imagemagick.org/script/download.php
    pause
    exit /b 1
)

echo Converting SVG source to PNG...
magick -background none assets_store\source_logo.svg assets_store\source.png
magick -background none assets_store\splash_source.svg assets_store\splash_source.png

echo.
echo Generating Android Icons...
echo --------------------------

cd assets_store\icons\android

REM Generate Android icons from source
magick ..\..\source.png -resize 36x36 android_icon_36dp.png
magick ..\..\source.png -resize 48x48 android_icon_48dp.png
magick ..\..\source.png -resize 72x72 android_icon_72dp.png
magick ..\..\source.png -resize 96x96 android_icon_96dp.png
magick ..\..\source.png -resize 144x144 android_icon_144dp.png
magick ..\..\source.png -resize 192x192 android_icon_192dp.png

echo Android icons generated successfully!

echo.
echo Generating iOS Icons...
echo -----------------------

cd ..\ios

REM Generate iOS icons from source
magick ..\..\source.png -resize 40x40 ios_icon_20x20@2x.png
magick ..\..\source.png -resize 60x60 ios_icon_20x20@3x.png
magick ..\..\source.png -resize 58x58 ios_icon_29x29@2x.png
magick ..\..\source.png -resize 87x87 ios_icon_29x29@3x.png
magick ..\..\source.png -resize 80x80 ios_icon_40x40@2x.png
magick ..\..\source.png -resize 120x120 ios_icon_40x40@3x.png
magick ..\..\source.png -resize 120x120 ios_icon_60x60@2x.png
magick ..\..\source.png -resize 180x180 ios_icon_60x60@3x.png
magick ..\..\source.png -resize 152x152 ios_icon_76x76@2x.png
magick ..\..\source.png -resize 167x167 ios_icon_83.5x83.5@2x.png
magick ..\..\source.png -resize 1024x1024 ios_icon_1024x1024.png

echo iOS icons generated successfully!

echo.
echo Generating Web Icons...
echo -----------------------

cd ..\web

REM Generate Web icons from source
magick ..\..\source.png -resize 16x16 web_icon_16x16.png
magick ..\..\source.png -resize 32x32 web_icon_32x32.png
magick ..\..\source.png -resize 192x192 web_icon_192x192.png
magick ..\..\source.png -resize 512x512 web_icon_512x512.png

echo Web icons generated successfully!

echo.
echo Generating Mobile Splash Screens...
echo ----------------------------------

cd ..\..\splashscreens\mobile

REM Generate mobile splash screens
magick ..\..\splash_source.png -resize 640x1136 splash_mobile_640x1136.png
magick ..\..\splash_source.png -resize 750x1334 splash_mobile_750x1334.png
magick ..\..\splash_source.png -resize 1125x2436 splash_mobile_1125x2436.png
magick ..\..\splash_source.png -resize 1242x2688 splash_mobile_1242x2688.png
magick ..\..\splash_source.png -resize 828x1792 splash_mobile_828x1792.png
magick ..\..\splash_source.png -resize 1080x1920 splash_mobile_1080x1920.png

echo Mobile splash screens generated successfully!

echo.
echo Generating Tablet Splash Screens...
echo ----------------------------------

cd ..\tablet

REM Generate tablet splash screens
magick ..\..\splash_source.png -resize 1536x2048 splash_tablet_1536x2048.png
magick ..\..\splash_source.png -resize 1668x2224 splash_tablet_1668x2224.png
magick ..\..\splash_source.png -resize 1668x2388 splash_tablet_1668x2388.png
magick ..\..\splash_source.png -resize 2048x2732 splash_tablet_2048x2732.png

echo Tablet splash screens generated successfully!

echo.
echo Generating Promotional Materials...
echo ----------------------------------

cd ..\..\promotional\screenshots

REM Create placeholder screenshots (in a real scenario, these would be actual app screenshots)
magick -size 1080x1920 xc:#4ECDC4 -pointsize 40 -fill white -annotate +540+960 "Screenshot 1\nMain Communication Grid" -gravity center screenshot_1.png
magick -size 1080x1920 xc:#FF6B6B -pointsize 40 -fill white -annotate +540+960 "Screenshot 2\nSymbol Customization" -gravity center screenshot_2.png
magick -size 1080x1920 xc:#45B7D1 -pointsize 40 -fill white -annotate +540+960 "Screenshot 3\nCategory Management" -gravity center screenshot_3.png
magick -size 1080x1920 xc:#96CEB4 -pointsize 40 -fill white -annotate +540+960 "Screenshot 4\nSettings and Preferences" -gravity center screenshot_4.png
magick -size 1080x1920 xc:#FECA57 -pointsize 40 -fill white -annotate +540+960 "Screenshot 5\nProfile Selection" -gravity center screenshot_5.png

cd ..\feature_graphics

REM Generate feature graphics
magick -size 1024x500 xc:#4ECDC4 -pointsize 40 -fill white -annotate +512+250 "Google Play Feature Graphic" -gravity center feature_graphic_1024x500.png
magick -size 1200x630 xc:#4ECDC4 -pointsize 40 -fill white -annotate +600+315 "App Store Feature Graphic" -gravity center feature_graphic_1200x630.png

cd ..\marketing

REM Generate marketing assets
magick ..\..\source.png -resize 400x150 logo_horizontal.png
magick ..\..\source.png -resize 150x400 logo_vertical.png
magick ..\..\source.png -resize 150x150 logo_icon.png
magick -size 1200x600 xc:#4ECDC4 -pointsize 60 -fill white -annotate +600+300 "Website Banner" -gravity center banner_1200x600.png
magick -size 1080x1080 xc:#4ECDC4 -pointsize 40 -fill white -annotate +540+540 "Social Media Profile" -gravity center social_media_1080x1080.png

echo Promotional materials generated successfully!

echo.
echo All assets generated successfully!
echo =================================
echo.
echo Next steps:
echo 1. Review all generated assets in the assets_store directory
echo 2. Replace placeholder screenshots with actual app screenshots
echo 3. Optimize images for file size if needed
echo 4. Verify all assets meet store requirements
echo.
pause