@echo off
echo Creating release keystore for AAC Communication Helper...
echo.

cd /d "%~dp0android\app"

if not exist "keystore" (
    mkdir keystore
    echo Created keystore directory
)

echo.
echo You will be prompted to enter keystore information.
echo IMPORTANT: Remember these passwords - you'll need them for app updates!
echo.

REM Use the keytool from Android Studio JDK
set KEYTOOL_PATH="C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe"

if not exist %KEYTOOL_PATH% (
    echo ERROR: keytool not found at expected location!
    echo Please ensure Android Studio is installed or update the path in this script.
    echo Looking for keytool in Android Studio JDK...
    pause
    exit /b 1
)

%KEYTOOL_PATH% -genkey -v -keystore keystore/release.keystore -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias aaccommunicationhelper

echo.
echo Keystore created successfully!
echo.
echo Next steps:
echo 1. Set environment variables for secure signing:
echo    set KEYSTORE_PASSWORD=your_keystore_password
echo    set KEY_PASSWORD=your_key_password
echo    set KEY_ALIAS=aaccommunicationhelper
echo.
echo 2. Build release APK:
echo    flutter build apk --release
echo.
echo 3. Build App Bundle for Play Store:
echo    flutter build appbundle --release
echo.

pause
