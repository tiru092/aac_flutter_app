@echo off
echo Building AAC Communication Helper for Production Release...
echo.

REM Check if keystore exists
if not exist "android\app\keystore\release.keystore" (
    echo ERROR: Release keystore not found!
    echo Please run generate_keystore.bat first to create the release keystore.
    echo.
    pause
    exit /b 1
)

REM Check environment variables
if "%KEYSTORE_PASSWORD%"=="" (
    echo ERROR: KEYSTORE_PASSWORD environment variable not set!
    echo Please set the following environment variables:
    echo   set KEYSTORE_PASSWORD=your_keystore_password
    echo   set KEY_PASSWORD=your_key_password
    echo   set KEY_ALIAS=aaccommunicationhelper
    echo.
    pause
    exit /b 1
)

if "%KEY_PASSWORD%"=="" (
    echo ERROR: KEY_PASSWORD environment variable not set!
    pause
    exit /b 1
)

echo Environment variables configured correctly.
echo.

REM Clean previous builds
echo Cleaning previous builds...
flutter clean
flutter pub get

echo.
echo Building release APK...
flutter build apk --release --split-per-abi

echo.
echo Building App Bundle for Play Store...
flutter build appbundle --release

echo.
echo ================================
echo BUILD COMPLETED SUCCESSFULLY!
echo ================================
echo.
echo Generated files:
echo - APK: build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
echo - App Bundle: build\app\outputs\bundle\release\app-release.aab
echo.
echo Next steps:
echo 1. Test the APK on physical devices
echo 2. Upload the App Bundle (.aab) to Google Play Console
echo 3. Complete the store listing with metadata and screenshots
echo.

pause
