# Android Installation Fix Guide

## Device Settings to Check:

### 1. Developer Options
- Settings → About Phone → Tap "Build Number" 7 times
- Go back to Settings → Developer Options
- Enable "USB Debugging" ✓
- Enable "Install via USB" ✓ 
- Enable "USB Debugging (Security Settings)" ✓

### 2. Security Settings
- Settings → Security & Privacy → Device Admin Apps
- Make sure no apps are blocking installations
- Settings → Security → Unknown Sources → Enable ✓

### 3. Play Protect (Google Play)
- Settings → Security → Google Play Protect
- Disable "Scan apps with Play Protect" temporarily
- Or add an exception for your app

### 4. USB Connection
- Use "File Transfer (MTP)" mode
- When connecting, allow "USB Debugging" and select "Always allow from this computer"

### 5. Manual Installation Alternative
If automatic installation fails, you can manually install:
1. Copy the APK to device: `build\app\outputs\flutter-apk\app-debug.apk`
2. Use a file manager on the device to install it
3. Or use `adb install -r build\app\outputs\flutter-apk\app-debug.apk`

## Alternative Commands to Try:

```bash
# Try installing with replacement flag
flutter install --debug -d 21051182G --install-replace

# Or try running with specific flags
flutter run -d 21051182G --debug --no-build

# Build and install manually
flutter build apk --debug
# Then manually copy APK to device storage and install via file manager
```

## If All Else Fails:
1. Restart both computer and Android device
2. Use a different USB cable
3. Try installing on an Android emulator instead
4. Use wireless debugging (Android 11+)
