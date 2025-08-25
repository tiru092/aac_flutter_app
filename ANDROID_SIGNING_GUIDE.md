# Android Signing Configuration Guide

This guide explains how to properly configure release signing for the AAC Communication Helper Android app.

## Prerequisites

1. Java JDK 11 or higher installed
2. Android SDK installed
3. Flutter development environment set up

## Generate Release Keystore

### Step 1: Create Keystore Directory
```bash
cd android/app
mkdir keystore
```

### Step 2: Generate Keystore
Run the following command in your terminal:
```bash
keytool -genkey -v -keystore keystore/release.keystore -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias aaccommunicationhelper
```

You will be prompted to enter:
- Keystore password (at least 6 characters)
- Key password (at least 6 characters)
- Your personal information (name, organizational unit, organization, city, state, country)

### Step 3: Secure Your Keystore
**Important**: Never commit your keystore file to version control!
The keystore file is already included in `.gitignore`, but double-check that it's not committed.

## Environment Variables Setup

Set the following environment variables for secure signing:

### Windows (Command Prompt)
```cmd
set KEYSTORE_PASSWORD=your_keystore_password
set KEY_ALIAS=aaccommunicationhelper
set KEY_PASSWORD=your_key_password
```

### Windows (PowerShell)
```powershell
$env:KEYSTORE_PASSWORD="your_keystore_password"
$env:KEY_ALIAS="aaccommunicationhelper"
$env:KEY_PASSWORD="your_key_password"
```

### macOS/Linux
```bash
export KEYSTORE_PASSWORD=your_keystore_password
export KEY_ALIAS=aaccommunicationhelper
export KEY_PASSWORD=your_key_password
```

## Alternative: Store Properties in Local File (Development Only)

For development purposes only, you can create a `key.properties` file in the `android/key.properties` directory:

```properties
storePassword=your_keystore_password
keyPassword=your_key_password
keyAlias=aaccommunicationhelper
storeFile=keystore/release.keystore
```

**Important**: Add this file to `.gitignore` to prevent it from being committed:
```gitignore
android/key.properties
```

Then modify `android/app/build.gradle.kts` to use these properties:

```kotlin
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
}
```

## Building Release APK

### Build APK
```bash
flutter build apk --release
```

### Build App Bundle (for Google Play Store)
```bash
flutter build appbundle --release
```

## Verify Signing

To verify that your APK is properly signed:

```bash
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk
```

## Troubleshooting

### Common Issues

1. **Keystore not found**: Ensure the keystore file is in the correct location (`android/app/keystore/release.keystore`)

2. **Password mismatch**: Double-check that your environment variables match the passwords used when creating the keystore

3. **Alias not found**: Verify that the alias matches what you used when creating the keystore

4. **Permission denied**: Ensure the keystore file has appropriate read permissions

### Reset Signing Configuration

If you need to recreate your keystore:
1. Delete the existing keystore file
2. Follow the "Generate Release Keystore" steps again
3. Update your environment variables or properties file

## Security Best Practices

1. **Never share your keystore**: Keep it secure and never commit it to version control
2. **Backup your keystore**: Store it in a secure location separate from your code
3. **Use strong passwords**: Choose complex passwords for both keystore and key
4. **Limit access**: Only provide signing credentials to trusted team members
5. **Regular rotation**: Consider rotating signing keys periodically for enhanced security

## CI/CD Integration

For automated builds, securely store your keystore and credentials in your CI/CD environment:

### GitHub Actions
```yaml
env:
  KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
  KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
  KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
```

### GitLab CI
```yaml
variables:
  KEYSTORE_PASSWORD: $CI_KEYSTORE_PASSWORD
  KEY_ALIAS: $CI_KEY_ALIAS
  KEY_PASSWORD: $CI_KEY_PASSWORD
```

## Additional Resources

- [Android App Signing Documentation](https://developer.android.com/studio/publish/app-signing)
- [Flutter Build Release Documentation](https://flutter.dev/docs/deployment/android)
- [Keytool Documentation](https://docs.oracle.com/javase/8/docs/technotes/tools/windows/keytool.html)